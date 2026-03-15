/// Native platform initialization (Android, iOS, Desktop).
/// This file is imported when NOT running on web.
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flow_state/features/notes/providers/isar_provider.dart';
import 'package:flow_state/features/notes/providers/web_notes_repository.dart';
import 'package:flow_state/features/notes/models/note.dart';
import 'package:isar_community/isar.dart';
import 'package:flow_state/core/algorithms/dijkstra.dart';
import 'package:flow_state/core/algorithms/knapsack.dart';
import 'package:flow_state/core/algorithms/gale_shapley.dart';
import 'package:flow_state/core/algorithms/sorting.dart';
import 'package:flow_state/core/data_structures/flow_linked_list.dart';

/// Wraps Isar in the same API shape as WebNotesRepository.
class IsarNotesRepository {
  final Isar isar;
  IsarNotesRepository(this.isar);

  Future<void> seedInitialData() async {
    final count = await isar.collection<Note>().buildQuery<Note>().count();
    if (count > 0) return;

    await isar.writeTxn(() async {
      final now = DateTime.now();
      final rawNotes = [
        Note()
          ..title = 'Meeting with Flow Team'
          ..content = 'Discuss Phase 3 integration and graph logic improvements.'
          ..state = NoteState.raw
          ..createdAt = now.subtract(const Duration(minutes: 10))
          ..updatedAt = now.subtract(const Duration(minutes: 10))
          ..tags = ['Work', 'Meeting'],
        Note()
          ..title = 'Buy Groceries'
          ..content = 'Need eggs, milk, and high-protein snacks for the week.'
          ..state = NoteState.raw
          ..createdAt = now.subtract(const Duration(hours: 1))
          ..updatedAt = now.subtract(const Duration(hours: 1))
          ..tags = ['Personal', 'Shopping'],
        Note()
          ..title = 'Algorithmic Research'
          ..content = 'Deep dive into Dijkstra performance for sparse graphs.'
          ..state = NoteState.raw
          ..createdAt = now.subtract(const Duration(days: 1))
          ..updatedAt = now.subtract(const Duration(days: 1))
          ..tags = ['Work', 'Research']
          ..isFavorite = true,
      ];
      final processingNotes = [
        Note()
          ..title = 'Feature Roadmap 2026'
          ..content = 'Plan for AI-agent orchestration and cross-platform synchronization.'
          ..state = NoteState.processing
          ..createdAt = now.subtract(const Duration(days: 2))
          ..updatedAt = now.subtract(const Duration(minutes: 5))
          ..tags = ['Strategy'],
      ];
      final libraryNotes = [
        Note()
          ..title = 'FlowState Architecture'
          ..content = 'Reference guide for the platform-adaptive knowledge pipeline.'
          ..state = NoteState.library
          ..createdAt = now.subtract(const Duration(days: 7))
          ..updatedAt = now.subtract(const Duration(days: 3))
          ..tags = ['Documentation', 'FlowState']
          ..processingScore = 85.0,
      ];
      await isar.collection<Note>().putAll([...rawNotes, ...processingNotes, ...libraryNotes]);
    });
  }

  Future<List<Note>> getAllNotes() async {
    return await isar.collection<Note>().buildQuery<Note>(
      sortBy: [const SortProperty(property: 'createdAt', sort: Sort.desc)],
    ).findAll();
  }

  Stream<List<Note>> watchNotesByState(NoteState state) {
    return isar.collection<Note>().buildQuery<Note>(
      filter: FilterCondition.equalTo(property: 'state', value: state.index),
      sortBy: [const SortProperty(property: 'createdAt', sort: Sort.desc)],
    ).watch(fireImmediately: true);
  }

  Stream<List<Note>> watchFilteredNotes(NoteState state, String query) {
    return isar.collection<Note>().buildQuery<Note>(
      filter: FilterGroup.and([
        FilterCondition.equalTo(property: 'state', value: state.index),
        FilterGroup.or([
          FilterCondition.contains(property: 'title', value: query, caseSensitive: false),
          FilterCondition.contains(property: 'content', value: query, caseSensitive: false),
        ]),
      ]),
      sortBy: [const SortProperty(property: 'createdAt', sort: Sort.desc)],
    ).watch(fireImmediately: true);
  }

  Future<void> addNote(String title, String content, NoteState state) async {
    final note = Note()
      ..title = title
      ..content = content
      ..state = state
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.collection<Note>().put(note);
    });
  }

  Future<void> updateNoteState(int id, NoteState newState) async {
    final note = await isar.collection<Note>().get(id);
    if (note != null) {
      if (newState == NoteState.library && note.state != NoteState.library) {
        final hours = DateTime.now().difference(note.createdAt).inHours;
        note.processingScore = 100.0 / (hours + 1);
      }
      note.state = newState;
      note.updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.collection<Note>().put(note);
      });
    }
  }

  Future<void> updateNote(int id, {String? title, String? content, List<String>? tags, bool? isFavorite}) async {
    final note = await isar.collection<Note>().get(id);
    if (note != null) {
      if (title != null) note.title = title;
      if (content != null) note.content = content;
      if (tags != null) note.tags = tags;
      if (isFavorite != null) note.isFavorite = isFavorite;
      note.updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.collection<Note>().put(note);
      });
    }
  }

  Future<List<Note>> searchNotes(String query) async {
    return await isar.collection<Note>().buildQuery<Note>(
      filter: FilterGroup.or([
        FilterCondition.contains(property: 'title', value: query, caseSensitive: false),
        FilterCondition.contains(property: 'content', value: query, caseSensitive: false),
        FilterCondition.contains(property: 'tags', value: query, caseSensitive: false),
      ]),
      sortBy: [const SortProperty(property: 'createdAt', sort: Sort.desc)],
    ).findAll();
  }

  Future<DijkstraResult?> findShortestPath(int startId, int targetId) async {
    final allNotes = await isar.collection<Note>().buildQuery<Note>().findAll();
    final graph = allNotes.map((n) {
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
    final rawNotes = await isar.collection<Note>().buildQuery<Note>(
      filter: FilterCondition.equalTo(property: 'state', value: NoteState.raw.index),
    ).findAll();
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
}

Future<IsarNotesRepository> initPlatform() async {
  // Desktop window configuration
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'FlowState Studio',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize Isar
  final isar = await initIsar();
  final repo = IsarNotesRepository(isar);
  await repo.seedInitialData();
  return repo;
}
