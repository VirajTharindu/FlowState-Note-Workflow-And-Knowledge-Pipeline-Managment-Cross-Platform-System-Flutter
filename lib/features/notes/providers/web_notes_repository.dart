import 'dart:async';
import 'package:flow_state/features/notes/models/note.dart';
import 'package:flow_state/core/algorithms/dijkstra.dart';
import 'package:flow_state/core/algorithms/knapsack.dart';
import 'package:flow_state/core/algorithms/gale_shapley.dart';
import 'package:flow_state/core/algorithms/sorting.dart';
import 'package:flow_state/core/data_structures/flow_linked_list.dart';

/// In-memory notes repository for web platform.
/// Provides the same API as the Isar-backed repository but uses
/// Dart lists and StreamControllers for reactivity.
class WebNotesRepository {
  final List<Note> _notes = [];
  int _nextId = 1;
  final _controller = StreamController<List<Note>>.broadcast();

  void _notify() {
    _controller.add(List.unmodifiable(_notes));
  }

  Future<void> seedInitialData() async {
    if (_notes.isNotEmpty) return;

    final now = DateTime.now();

    // Seed Raw Notes (for Capture View)
    _addInternal(Note()
      ..title = 'Meeting with Flow Team'
      ..content = 'Discuss Phase 3 integration and graph logic improvements.'
      ..state = NoteState.raw
      ..createdAt = now.subtract(const Duration(minutes: 10))
      ..updatedAt = now.subtract(const Duration(minutes: 10))
      ..tags = ['Work', 'Meeting']);

    _addInternal(Note()
      ..title = 'Buy Groceries'
      ..content = 'Need eggs, milk, and high-protein snacks for the week.'
      ..state = NoteState.raw
      ..createdAt = now.subtract(const Duration(hours: 1))
      ..updatedAt = now.subtract(const Duration(hours: 1))
      ..tags = ['Personal', 'Shopping']);

    _addInternal(Note()
      ..title = 'Algorithmic Research'
      ..content = 'Deep dive into Dijkstra performance for sparse graphs.'
      ..state = NoteState.raw
      ..createdAt = now.subtract(const Duration(days: 1))
      ..updatedAt = now.subtract(const Duration(days: 1))
      ..tags = ['Work', 'Research']
      ..isFavorite = true);

    // Seed Processing Notes (for Studio View)
    _addInternal(Note()
      ..title = 'Feature Roadmap 2026'
      ..content = 'Plan for AI-agent orchestration and cross-platform synchronization.'
      ..state = NoteState.processing
      ..createdAt = now.subtract(const Duration(days: 2))
      ..updatedAt = now.subtract(const Duration(minutes: 5))
      ..tags = ['Strategy']);

    // Seed Library Notes (for Portal View)
    _addInternal(Note()
      ..title = 'FlowState Architecture'
      ..content = 'Reference guide for the platform-adaptive knowledge pipeline.'
      ..state = NoteState.library
      ..createdAt = now.subtract(const Duration(days: 7))
      ..updatedAt = now.subtract(const Duration(days: 3))
      ..tags = ['Documentation', 'FlowState']
      ..processingScore = 85.0);

    _notify();
  }

  void _addInternal(Note note) {
    note.id = _nextId++;
    _notes.add(note);
  }

  Future<List<Note>> getAllNotes() async {
    final sorted = List<Note>.from(_notes);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Stream<List<Note>> watchNotesByState(NoteState state) async* {
    // Emit current state immediately
    yield _notesByState(state);
    // Then yield on every change
    await for (final _ in _controller.stream) {
      yield _notesByState(state);
    }
  }

  List<Note> _notesByState(NoteState state) {
    final filtered = _notes.where((n) => n.state == state).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Future<void> addNote(String title, String content, NoteState state) async {
    final note = Note()
      ..title = title
      ..content = content
      ..state = state
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    _addInternal(note);
    _notify();
  }

  Future<void> updateNoteState(int id, NoteState newState) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final note = _notes[idx];
      if (newState == NoteState.library && note.state != NoteState.library) {
        final hours = DateTime.now().difference(note.createdAt).inHours;
        note.processingScore = 100.0 / (hours + 1);
      }
      note.state = newState;
      note.updatedAt = DateTime.now();
      _notify();
    }
  }

  Future<void> updateNote(int id, {String? title, String? content, List<String>? tags, bool? isFavorite}) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final note = _notes[idx];
      if (title != null) note.title = title;
      if (content != null) note.content = content;
      if (tags != null) note.tags = tags;
      if (isFavorite != null) note.isFavorite = isFavorite;
      note.updatedAt = DateTime.now();
      _notify();
    }
  }

  Future<List<Note>> searchNotes(String query) async {
    final q = query.toLowerCase();
    final results = _notes.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q) ||
          (n.tags?.any((t) => t.toLowerCase().contains(q)) ?? false);
    }).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  Stream<List<Note>> watchFilteredNotes(NoteState state, String query) async* {
    yield _filteredNotes(state, query);
    await for (final _ in _controller.stream) {
      yield _filteredNotes(state, query);
    }
  }

  List<Note> _filteredNotes(NoteState state, String query) {
    final q = query.toLowerCase();
    final results = _notes.where((n) {
      if (n.state != state) return false;
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q);
    }).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  // --- Phase 3 Algorithmic Intelligence ---

  Future<DijkstraResult?> findShortestPath(int startId, int targetId) async {
    final graph = _notes.map((n) {
      Map<int, double> neighbors = {};
      if (n.linkedNoteIds != null) {
        for (var id in n.linkedNoteIds!) {
          neighbors[id] = 1.0;
        }
      }
      return GraphNote(n.id, neighbors);
    }).toList();
    return DijkstraSolver.solve(graph, startId, targetId);
  }

  Future<KnapsackResult> getOptimizedSession(int timeCapacity) async {
    final rawNotes = _notes.where((n) => n.state == NoteState.raw).toList();
    final items = rawNotes.map((n) {
      final int favValue = n.isFavorite ? 50 : 0;
      final int scoreValue = n.processingScore?.toInt() ?? 10;
      int value = favValue + scoreValue;
      int weight = (n.content.length / 50.0).ceil().toInt().clamp(1, 10);
      return KnapsackItem(n.id, weight, value);
    }).toList();
    return KnapsackSolver.solve(items, timeCapacity);
  }

  Future<Map<int, int>> matchNotesToCategories(List<int> noteIds, List<String> categories) async {
    List<List<int>> notePrefs = List.generate(noteIds.length, (i) => List.generate(categories.length, (j) => j));
    List<List<int>> categoryPrefs = List.generate(categories.length, (i) => List.generate(noteIds.length, (j) => j));
    return GaleShapleySolver.solve(notePrefs, categoryPrefs);
  }

  FlowLinkedList<Note> getStreamAsLinkedList(List<Note> notes) {
    final list = FlowLinkedList<Note>();
    for (var n in notes) {
      list.insertFirst(n);
    }
    return list;
  }

  List<Note> getSortedNotes(List<Note> notes) {
    return NoteSorter.sort(notes);
  }

  void dispose() {
    _controller.close();
  }
}
