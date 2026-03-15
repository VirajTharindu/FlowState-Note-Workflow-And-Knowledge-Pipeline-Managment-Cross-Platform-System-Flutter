class LinkedListNode<T> {
  T data;
  LinkedListNode<T>? next;
  LinkedListNode<T>? prev;

  LinkedListNode(this.data);
}

class FlowLinkedList<T> {
  LinkedListNode<T>? head;
  LinkedListNode<T>? tail;
  int _length = 0;

  int get length => _length;

  /// Insert at the head (most recent first) - O(1)
  void insertFirst(T data) {
    var newNode = LinkedListNode(data);
    if (head == null) {
      head = tail = newNode;
    } else {
      newNode.next = head;
      head!.prev = newNode;
      head = newNode;
    }
    _length++;
  }

  /// Remove a node - O(1) if node is provided
  void removeNode(LinkedListNode<T> node) {
    if (node.prev != null) {
      node.prev!.next = node.next;
    } else {
      head = node.next;
    }

    if (node.next != null) {
      node.next!.prev = node.prev;
    } else {
      tail = node.prev;
    }
    _length--;
  }

  List<T> toList() {
    List<T> list = [];
    var curr = head;
    while (curr != null) {
      list.add(curr.data);
      curr = curr.next;
    }
    return list;
  }
}
