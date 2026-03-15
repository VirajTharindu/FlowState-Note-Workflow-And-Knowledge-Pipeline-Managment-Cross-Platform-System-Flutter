import 'package:flow_state/features/notes/models/note.dart';

class NoteSorter {
  /// Sorts notes based on multiple criteria: isFavorite > processingScore > updatedAt.
  /// Uses a custom MergeSort for stability and demonstration.
  static List<Note> sort(List<Note> notes) {
    if (notes.length <= 1) return notes;

    int mid = notes.length ~/ 2;
    List<Note> left = sort(notes.sublist(0, mid));
    List<Note> right = sort(notes.sublist(mid));

    return _merge(left, right);
  }

  static List<Note> _merge(List<Note> left, List<Note> right) {
    List<Note> result = [];
    int i = 0, j = 0;

    while (i < left.length && j < right.length) {
      if (_compare(left[i], right[j]) <= 0) {
        result.add(left[i]);
        i++;
      } else {
        result.add(right[j]);
        j++;
      }
    }

    result.addAll(left.sublist(i));
    result.addAll(right.sublist(j));
    return result;
  }

  /// Returns < 0 if a should come before b, > 0 if b should come before a, 0 if equal.
  static int _compare(Note a, Note b) {
    // 1. Favorites first
    if (a.isFavorite && !b.isFavorite) return -1;
    if (!a.isFavorite && b.isFavorite) return 1;

    // 2. Higher processing score (importance) first
    double scoreA = a.processingScore ?? 0.0;
    double scoreB = b.processingScore ?? 0.0;
    if (scoreA != scoreB) return scoreB.compareTo(scoreA);

    // 3. Newer updates first
    return b.updatedAt.compareTo(a.updatedAt);
  }
}
