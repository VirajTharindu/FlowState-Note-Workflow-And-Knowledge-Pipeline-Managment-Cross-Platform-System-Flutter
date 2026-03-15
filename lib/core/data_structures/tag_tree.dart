class TagNode {
  final String name;
  final Map<String, TagNode> children = {};
  bool isEndOfTag = false;

  TagNode(this.name);
}

class TagTree {
  final TagNode root = TagNode('');

  /// Insert a hierarchical tag (e.g., "Work/Projects/FlowState")
  void insert(String path) {
    List<String> parts = path.split('/');
    TagNode current = root;
    
    for (String part in parts) {
      current = current.children.putIfAbsent(part, () => TagNode(part));
    }
    current.isEndOfTag = true;
  }

  /// Search for a tag and return its node
  TagNode? find(String path) {
    List<String> parts = path.split('/');
    TagNode current = root;
    
    for (String part in parts) {
      if (!current.children.containsKey(part)) return null;
      current = current.children[part]!;
    }
    return current;
  }

  /// Get all child tags of a prefix
  List<String> getSuggestions(String prefix) {
    TagNode? node = find(prefix);
    if (node == null) return [];
    
    List<String> results = [];
    _traverse(node, prefix, results);
    return results;
  }

  void _traverse(TagNode node, String currentPath, List<String> results) {
    if (node.isEndOfTag) results.add(currentPath);
    
    for (var entry in node.children.entries) {
      _traverse(entry.value, "$currentPath/${entry.key}", results);
    }
  }
}
