/// Web platform initialization.
/// This file is imported when running on web (dart.library.html).
import 'package:flow_state/features/notes/providers/web_notes_repository.dart';

Future<WebNotesRepository> initPlatform() async {
  final repo = WebNotesRepository();
  await repo.seedInitialData();
  return repo;
}
