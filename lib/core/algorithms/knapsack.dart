import 'dart:math';

class KnapsackItem {
  final int id;
  final int weight; // Time/Cost to process
  final int value;  // Importance/Utility

  KnapsackItem(this.id, this.weight, this.value);
}

class KnapsackResult {
  final List<int> selectedIds;
  final int totalValue;

  KnapsackResult(this.selectedIds, this.totalValue);
}

class KnapsackSolver {
  /// Solves the 0/1 Knapsack problem to maximize value within a weight capacity.
  static KnapsackResult solve(List<KnapsackItem> items, int capacity) {
    int n = items.length;
    if (n == 0 || capacity <= 0) return KnapsackResult([], 0);

    // dp[i][w] will be the maximum value that can be attained with weight less than or equal to w using items up to i
    List<List<int>> dp = List.generate(n + 1, (_) => List.filled(capacity + 1, 0));

    for (int i = 1; i <= n; i++) {
      for (int w = 1; w <= capacity; w++) {
        if (items[i - 1].weight <= w) {
          dp[i][w] = max(
            items[i - 1].value + dp[i - 1][w - items[i - 1].weight],
            dp[i - 1][w],
          );
        } else {
          dp[i][w] = dp[i - 1][w];
        }
      }
    }

    // Backtrack to find selected items
    List<int> selectedIds = [];
    int res = dp[n][capacity];
    int w = capacity;
    for (int i = n; i > 0 && res > 0; i--) {
      if (res != dp[i - 1][w]) {
        selectedIds.add(items[i - 1].id);
        res -= items[i - 1].value;
        w -= items[i - 1].weight;
      }
    }

    return KnapsackResult(selectedIds, dp[n][capacity]);
  }
}
