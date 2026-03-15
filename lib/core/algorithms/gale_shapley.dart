import 'dart:collection';

class GaleShapleySolver {
  /// Solves the Stable Marriage problem using the Gale-Shapley algorithm.
  /// Returns a map where key is proposer index and value is receiver index.
  static Map<int, int> solve(
    List<List<int>> proposerPrefs, // Indices of receivers in order of preference
    List<List<int>> receiverPrefs, // Indices of proposers in order of preference
  ) {
    int n = proposerPrefs.length;
    Map<int, int> engagement = {}; // Receiver -> Proposer
    List<int?> proposerMatch = List.filled(n, null); // Proposer -> Receiver
    List<int> nextPropose = List.filled(n, 0); // Next receiver to propose to for each proposer
    Queue<int> freeProposers = Queue.from(Iterable.generate(n, (i) => i));

    while (freeProposers.isNotEmpty) {
      int p = freeProposers.removeFirst();
      int r = proposerPrefs[p][nextPropose[p]];
      nextPropose[p]++;

      if (!engagement.containsKey(r)) {
        engagement[r] = p;
        proposerMatch[p] = r;
      } else {
        int currentP = engagement[r]!;
        List<int> prefs = receiverPrefs[r];
        if (prefs.indexOf(p) < prefs.indexOf(currentP)) {
          engagement[r] = p;
          proposerMatch[p] = r;
          proposerMatch[currentP] = null;
          freeProposers.add(currentP);
        } else {
          freeProposers.add(p);
        }
      }
    }

    // Return Proposer -> Receiver mapping
    Map<int, int> result = {};
    for (int i = 0; i < n; i++) {
      if (proposerMatch[i] != null) {
        result[i] = proposerMatch[i]!;
      }
    }
    return result;
  }
}
