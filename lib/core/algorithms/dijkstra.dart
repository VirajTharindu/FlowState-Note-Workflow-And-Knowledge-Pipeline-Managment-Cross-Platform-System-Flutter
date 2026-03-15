import 'dart:collection';

class GraphNote {
  final int id;
  final Map<int, double> neighbors; // Neighbor ID and edge weight

  GraphNote(this.id, this.neighbors);
}

class DijkstraResult {
  final List<int> path;
  final double distance;

  DijkstraResult(this.path, this.distance);
}

class DijkstraSolver {
  /// Finds the shortest path between `startId` and `targetId` in a list of [GraphNote]s.
  static DijkstraResult? solve(List<GraphNote> graph, int startId, int targetId) {
    final Map<int, double> distances = {};
    final Map<int, int?> previous = {};
    final SplayTreeSet<int> queue = SplayTreeSet((a, b) {
      int cmp = (distances[a] ?? double.infinity).compareTo(distances[b] ?? double.infinity);
      return cmp == 0 ? a.compareTo(b) : cmp;
    });

    for (var node in graph) {
      distances[node.id] = double.infinity;
      previous[node.id] = null;
    }

    if (!distances.containsKey(startId)) return null;

    distances[startId] = 0;
    queue.add(startId);

    while (queue.isNotEmpty) {
      int u = queue.first;
      queue.remove(u);

      if (u == targetId) {
        List<int> path = [];
        int? curr = u;
        while (curr != null) {
          path.insert(0, curr);
          curr = previous[curr];
        }
        return DijkstraResult(path, distances[u]!);
      }

      final nodeU = graph.firstWhere((n) => n.id == u);
      for (var neighborEntry in nodeU.neighbors.entries) {
        int v = neighborEntry.key;
        double weight = neighborEntry.value;
        double alt = distances[u]! + weight;

        if (alt < (distances[v] ?? double.infinity)) {
          queue.remove(v); // Remove old distance if exists
          distances[v] = alt;
          previous[v] = u;
          queue.add(v);
        }
      }
    }

    return null;
  }
}
