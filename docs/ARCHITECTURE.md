# FlowState — Architecture Deep Dive

This document describes the technical architecture of FlowState in detail, intended for developers who want to understand or contribute to the system.

FlowState uses a **Feature-First, Layered, Modular, Decoupled, Monorepo(Fullstack Workspace) Architecture** combined with the **Repository Pattern** for database independence.

---

## 1. The First Principle: Device = Context

The core architectural decision is that **the device type dictates the UX mode**. This is not a responsive resize — it is an entirely different widget tree based on screen size, determined at runtime by `AdaptiveScaffold`.

```
< 800px width  →   CaptureView   (Mobile mode)
≥ 800px width  →   StudioView    (Desktop mode)
Web target     →   PortalView    (Web mode — served via web compilation)
```

---

## 2. Layered Architecture

```
┌─────────────────────────────────────────────┐
│  Presentation Layer (Views)                 │
│  CaptureView | StudioView | PortalView      │
├─────────────────────────────────────────────┤
│  State Layer (Riverpod Providers)           │
│  notesRepositoryProvider                    │
│  rawNotesProvider | filteredNotesProvider   │
│  searchQueryProvider | selectedNoteProvider │
├─────────────────────────────────────────────┤
│  Domain Layer (Models + Algorithms)         │
│  Note (Isar Entity) | NoteState (enum)      │
│  Dijkstra | Knapsack | GaleShapley | Sort   │
├─────────────────────────────────────────────┤
│  Data Layer (Repository Pattern)            │
│  IsarNotesRepository   ← TEMPORARY (native) │
│  WebNotesRepository    ← TEMPORARY (web)    │
│  MongoDbRepository     ← PLANNED (Phase 2)  │
└─────────────────────────────────────────────┘
```

---

## 3. Data Flow

### 3.1 Note Lifecycle
Every `Note` has a `NoteState` that tracks its position in the pipeline:

```
[Mobile] Captured → NoteState.raw
[Desktop] Editor → NoteState.processing (transitional)
[Desktop] Published → NoteState.library
[Web] Visible when NoteState.library
```

### 3.2 Platform-Specific Initialization

The app uses a conditional import pattern to initialize the correct platform:

```dart
// main.dart
import 'main_native.dart' if (dart.library.html) 'main_web.dart' as platform;
```

- **Native (mobile/desktop)**: `main_native.dart` → initializes **Isar DB** ⚠️ _(temporary local DB)_, seeds demo data, configures window manager for desktop.
- **Web**: `main_web.dart` → uses `WebNotesRepository` with an **in-memory** list of seeded notes ⚠️ _(temporary — resets on page refresh)_.

> **Phase 2 Plan**: Both will be replaced by a single `MongoDbNotesRepository` that connects all three platforms to the same MongoDB Atlas cloud database, enabling real-time cross-device sync via MongoDB Change Streams.

---

## 4. Algorithm Implementations

### 4.1 Dijkstra's Algorithm (`dijkstra.dart`)
- **Purpose**: Find the shortest conceptual path between notes in the Knowledge Graph.
- **Input**: A list of `GraphNote` objects (each with a `Map<int, double> neighbors`).
- **Output**: `DijkstraResult` containing the `path` (list of note IDs) and total `distance`.
- **Applied in**: `StudioView` → `_GraphConnections` widget → "Find Shortest Path to Root" button.

```dart
// Example: Find path between Note #5 and Note #1
DijkstraResult? result = DijkstraSolver.solve(graph, 5, 1);
```

### 4.2 0/1 Knapsack Algorithm (`knapsack.dart`)
- **Purpose**: Select the maximum-value subset of notes that fits within a given time budget (e.g., 15 minutes).
- **Input**: A list of `KnapsackItem` objects (each with `weight` = processing time, `value` = importance), and a `capacity` in minutes.
- **Output**: `KnapsackResult` containing the `selectedIds` (optimal note IDs) and `totalValue`.
- **Applied in**: `StudioView` → `_SmartReviewButton` → "Start 15-min Session" button.

### 4.3 Gale-Shapley (Stable Matching) (`gale_shapley.dart`)
- **Purpose**: Optimally and stably match raw notes to topic categories (e.g., "Work", "Personal", "Finance").
- **Input**: `proposerPrefs` (notes' preference list of categories) and `receiverPrefs` (categories' preference list of notes).
- **Output**: A stable `Map<int, int>` matching (note → category).
- **Applied in**: `StudioView` → `_StableMarriageSuggestions` widget → "Find Optimal Category" button.

### 4.4 MergeSort — Note Sorting (`sorting.dart`)
- **Purpose**: Sort the note list using a multi-criteria stable sort.
- **Criteria Order**: `isFavorite` (boolean) > `processingScore` (double) > `updatedAt` (DateTime).
- **Time Complexity**: O(n log n) — stable sort guarantees equal elements maintain their relative order.

---

## 5. Data Structures

### 5.1 TagTree — Hierarchical Trie (`tag_tree.dart`)
A **Prefix Tree (Trie)** that stores hierarchical tags using `/` as a delimiter.

```
Root
├── Work
│   ├── Projects
│   │   └── FlowState  ← End of Tag
│   └── Admin
│       └── Taxes      ← End of Tag
└── Personal
    └── Health
        └── Gym        ← End of Tag
```

Operations:
- `insert("Work/Projects/FlowState")` — O(depth)
- `find("Work")` — O(depth)
- `getSuggestions("Work")` → `["Work/Projects/FlowState", "Work/Admin/Taxes"]` — O(n)

### 5.2 FlowLinkedList — Doubly Linked List (`flow_linked_list.dart`)
A **generic doubly-linked list** used for the note capture stream, enabling O(1) prepend (most-recent-first) and O(1) removal.

```dart
class FlowLinkedList<T> {
  void insertFirst(T data);    // O(1) — prepend to stream
  void removeNode(LinkedListNode<T> node); // O(1) — remove from stream
  List<T> toList(); // O(n)
}
```

---

## 6. State Management (Riverpod)

All application state is managed via `flutter_riverpod`. Key providers:

| Provider | Type | Description |
| :--- | :--- | :--- |
| `notesRepositoryProvider` | `Provider<NotesRepository>` | The active repository (overridden per platform) |
| `rawNotesProvider` | `StreamProvider<List<Note>>` | Live stream of `NoteState.raw` notes |
| `filteredNotesProvider` | `StreamProvider<List<Note>>` | Filtered notes by state + search |
| `searchQueryProvider` | `StateProvider<String>` | Current search string |
| `selectedNoteProvider` | `StateProvider<Note?>` | Currently selected note in Studio |
| `optimizedSessionProvider`| `StateProvider<List<int>?>` | Knapsack-optimized session note IDs |

---

## 7. Theme System

The theme is fully defined in `lib/core/theme/`:

- **`app_colors.dart`**: All color constants and `LinearGradient` definitions.
- **`app_text_styles.dart`**: Google Fonts (`Outfit` for headings, `Inter` for body) with semantic sizes.
- **`app_theme.dart`**: Full `ThemeData` configuration using the color constants.

## 8. Database Strategy

### Current State (Temporary)

| Platform | Database | Status |
| :--- | :--- | :--- |
| Mobile & Desktop | Isar Community DB (local, offline-first) | ⚠️ **Temporary** |
| Web | In-memory repository (seeded on startup) | ⚠️ **Temporary** |

Both databases are **development placeholders**. Data persists on native (Isar), but the web version resets on page refresh.

### Future State — Phase 2 (MongoDB Atlas)

**MongoDB Atlas** will become the single source of truth for all platforms. The Note document model maps naturally to MongoDB's document-oriented schema — embedded arrays for `tags` and `linkedNoteIds` are a native MongoDB pattern.

```
Mobile ─────┐
Desktop ────┼──→  MongoDB Atlas (Cloud)  ←──  All platforms read/write to one DB
Web ────────┘    (Document DB)
```

The migration plan:
1. Create a `MongoDbNotesRepository` implementing the same `NotesRepository` interface.
2. Override `notesRepositoryProvider` to use `MongoDbNotesRepository` on all platforms.
3. Enable MongoDB Change Streams so note changes on Desktop appear instantly on Mobile.
4. Add JWT-based authentication for user isolation and document-level access control.
5. Deprecate `IsarNotesRepository` and `WebNotesRepository`.

> **Key benefit of the current Repository Pattern**: Switching to MongoDB Atlas requires zero changes to the Views, Providers, or Algorithm layers — only a new repository implementation.
