import 'package:isar_community/isar.dart';


enum NoteState {
  raw,        // Mobile: Captured, not yet processed
  processing, // Desktop: In the queue being linked/edited
  library     // Web/All: Finalized and archived
}

@collection
class Note {
  Id id = Isar.autoIncrement;

  late String title;
  
  late String content;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;

  @enumerated
  late NoteState state;

  @Index()
  List<String>? tags;

  bool isFavorite = false;

  // Gamification: metadata for tracking processing speed or "level"
  double? processingScore;

  // For future implementation: media links, linking to other notes, etc.
  List<int>? linkedNoteIds;
}
