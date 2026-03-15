import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flow_state/features/notes/models/note.dart';

/// The central repository provider — overridden in main.dart with
/// either a WebNotesRepository or IsarNotesRepository.
final notesRepositoryProvider = Provider<dynamic>((ref) {
  throw UnimplementedError('notesRepositoryProvider must be overridden in main.dart');
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredNotesProvider = StreamProvider.family<List<Note>, NoteState>((ref, state) async* {
  final query = ref.watch(searchQueryProvider);
  final repo = ref.watch(notesRepositoryProvider);

  if (query.isEmpty) {
    yield* repo.watchNotesByState(state) as Stream<List<Note>>;
  } else {
    yield* repo.watchFilteredNotes(state, query) as Stream<List<Note>>;
  }
});

final rawNotesProvider = StreamProvider<List<Note>>((ref) async* {
  final repo = ref.watch(notesRepositoryProvider);
  yield* repo.watchNotesByState(NoteState.raw) as Stream<List<Note>>;
});

final processingNotesProvider = StreamProvider<List<Note>>((ref) async* {
  final repo = ref.watch(notesRepositoryProvider);
  yield* repo.watchNotesByState(NoteState.processing) as Stream<List<Note>>;
});

final libraryNotesProvider = StreamProvider<List<Note>>((ref) async* {
  final repo = ref.watch(notesRepositoryProvider);
  yield* repo.watchNotesByState(NoteState.library) as Stream<List<Note>>;
});
