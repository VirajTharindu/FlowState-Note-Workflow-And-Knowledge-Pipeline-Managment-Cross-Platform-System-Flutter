import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;
import '../models/note.dart';
import '../models/note_schema.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  return await initIsar();
});

Future<Isar> initIsar() async {
  if (Isar.instanceNames.isEmpty) {
    String? directory;
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      directory = dir.path;
    }

    return await Isar.open(
      [NoteSchema],
      directory: kIsWeb ? '' : directory!,
    );
  }
  return Isar.getInstance()!;
}
