# FlowState — Engineering Decisions

This document is a deep technical retrospective on the key engineering choices made during the development of FlowState. Each decision represents a deliberate trade-off that shaped the system's architecture, scalability, and developer experience.

---

## 1. Single Codebase, Three Distinct UX Experiences (Flutter)

**Decision**: Use Flutter to compile a single Dart codebase to Android, Web, Windows, macOS, and Linux — but render an entirely different view on each platform rather than simply resizing the same UI.

**Reasoning**:
Most tools that claim "cross-platform" just shrink a desktop layout onto a phone. FlowState takes the stance that Device = Context. The entire philosophy collapses if the mobile user sees the same complex editor as the desktop user. Flutter's compilation targets make this possible: the `AdaptiveScaffold` detects the screen width breakpoint and renders a completely different widget tree — `CaptureView` on mobile, `StudioView` on desktop, and `PortalView` on web — from a single codebase.

**Trade-offs**:
- Pro: One language, one state management layer, one data model for all platforms.
- Con: Extra complexity maintaining three view implementations simultaneously.
- Con: Flutter's web rendering (CanvasKit) introduces larger bundle sizes vs. native HTML.

**Outcome**: The unified codebase resulted in approximately 60% less duplicated business logic compared to maintaining three separate apps. The `AdaptiveScaffold` breakpoint-based routing pattern proved clean and extensible.

---

## 2. Repository Pattern for Database Abstraction

**Decision**: Define a `NotesRepository` abstract interface and provide two concrete implementations: `IsarNotesRepository` (native) and `WebNotesRepository` (in-memory). Inject the correct one at startup using Riverpod's `overrideWithValue`.

**Reasoning**:
The app needs to run on both native targets (where Isar's FFI-based database works) and on the web (where Isar cannot run). Instead of scattering `if (kIsWeb)` checks throughout the UI and business logic, the Repository Pattern provides a clean seam. All providers and views depend only on the abstract interface — they have no idea whether they are talking to Isar or an in-memory list.

**Future Impact**:
This is the exact same seam where MongoDB Atlas will be plugged in during Phase 2. Switching the database will require **zero changes** to Views, Providers, or the Algorithm Engine — only a new `MongoDbNotesRepository` implementation.

**Trade-offs**:
- Pro: Platform isolation; clean upgrade path to MongoDB Atlas.
- Con: Slightly more boilerplate (interface + two implementations).

---

## 3. CS Algorithm Integration as Core Feature

**Decision**: Implement four Computer Science algorithms — Dijkstra, 0/1 Knapsack, Gale-Shapley, and MergeSort — as core, active features rather than theoretical demonstrations.

**Reasoning**:

| Algorithm | User-Facing Feature |
| :--- | :--- |
| Dijkstra's Shortest Path | Knowledge Graph: "Find connected path between ideas" |
| 0/1 Knapsack | Smart Review: "Select 15-minute optimal study session" |
| Gale-Shapley Stable Matching | Auto-Categorize: "Match notes → topic categories" |
| MergeSort (Multi-key) | Note queue sorted by favorites → score → recency |

Each algorithm was purpose-built with a clear Dart class, a static `solve()` method, and a dartdoc contract. They are pure Dart (no Flutter imports), making them independently testable and provably correct.

**Engineering principle applied**: Every feature at the Intelligence Layer should be traceable to a proven algorithm with known time/space complexity guarantees — not a heuristic or hard-coded rule.

---

## 4. Hierarchical Tag System — Trie Data Structure

**Decision**: Build the tag system on a Trie (Prefix Tree) rather than a flat list or relational join table.

**Reasoning**:
Tags in FlowState are hierarchical by design: `Work/Projects/FlowState`, not just `work`. A flat list cannot represent this naturally. A Trie:
- Stores tags in O(k) time/space where k = path depth.
- Returns all children of a prefix in O(n) — powering instant auto-complete suggestions.
- Maps naturally to folder-like mental models users already have.

**Trade-offs**:
- Pro: O(k) insert and lookup; O(n) subtree suggestion traversal.
- Con: In-memory only during Phase 1 — persistence handled through storing the flat string paths in Isar.

---

## 5. Gamified Processing Score

**Decision**: Add a `processingScore` (double) field to the `Note` model to represent how "valuable" a note has become after processing.

**Reasoning**:
The core problem FlowState solves is that captured notes are never actually processed. Assigning a numeric score to processed notes creates a feedback loop — the Knapsack algorithm uses this score as the `value` dimension when selecting an optimized review session. Higher-scored notes are more likely to be included in a 15-minute session, creating an incentive to score notes accurately during processing.

**Future Impact**: Processing streaks, leaderboards, and level-up gamification in Phase 3 all build on this single numeric field.

---

## 6. Conditional Import Pattern for Platform Divergence

**Decision**: Use Dart's `import 'A.dart' if (dart.library.html) 'B.dart'` conditional import at `main.dart` level to initialize platform-specific code, rather than runtime `kIsWeb` branching.

**Reasoning**:
`kIsWeb` checks scatter platform logic throughout the codebase and are invisible to the compiler. Dart's conditional imports are resolved at compile time — the web build literally does not include any Isar code, which prevents tree-shaking failures and reduces bundle size significantly.

```dart
// Platform selection resolved at compile time
import 'main_native.dart' if (dart.library.html) 'main_web.dart' as platform;
```

---

## 7. Riverpod 2.x for State Management

**Decision**: Use `flutter_riverpod` with typed `StreamProvider`, `StateProvider`, and `Provider` — not `setState`, `BLoC`, or `GetX`.

**Reasoning**:
- `StreamProvider` wraps Isar's native `watchAll()` reactive streams, meaning the UI automatically rebuilds when the database changes.
- Providers can be `overrideWithValue()` at app startup to inject the correct repository — powering the platform-specific repository pattern.
- No `BuildContext` dependency in business logic; providers are globally accessible.

**Trade-offs**:
- Pro: Reactive, testable, and zero boilerplate for dependency injection.
- Con: Riverpod's compile-time code generation (`riverpod_generator`) was not used in Phase 1 to keep the setup minimal.

---

## 8. Temporary Database Strategy (Isar → MongoDB Atlas Migration Path)

**Decision**: Use Isar Community as the offline-first native DB during Phase 1, with a clear and explicit migration path to MongoDB Atlas in Phase 2.

**Reasoning**:
Isar is the fastest Flutter-compatible embedded database available, with native FFI bindings. Using it in Phase 1 allows offline-first development with zero network dependencies — ideal for a solo developer iterating fast. The `Note` model maps naturally to MongoDB's document-oriented storage: its `tags` and `linkedNoteIds` fields are arrays, which are first-class citizens in MongoDB documents. The Repository Pattern (Decision #2 above) ensures this is a safe, clean swap without architectural surgery.

**Current Status**: Isar (native) and in-memory (web) are explicit placeholders, documented in the README and ARCHITECTURE files with `⚠️ Temporary` annotations.

---

## 9. Feature-First Layered Architecture

**Decision**: Organize the `lib/` directory using a **Feature-First Layered approach**, strongly separating pure Dart logic (`core/`) from Flutter UI elements (`features/`).

**Reasoning**:
Standard Flutter tutorials encourage grouping by technical type (`models/`, `views/`, `controllers/` at the root). As projects scale, this becomes unmaintainable. FlowState uses a structure that maps to the business domain:

```
lib/
├── core/             # Pure Dart. Zero Flutter dependencies.
├── features/         # Encapsulated feature pods (e.g., 'notes').
└── shared/           # Cross-feature UI components.
```

Inside `features/notes/`, the project uses **Layered Architecture**:
1. `views/` (Presentation)
2. `providers/` (State + Data Repositories)
3. `models/` (Domain Entities)

By forcing algorithms and data structures into `core/` and enforcing a strictly "pure Dart" rule, the system ensures that complex CS logic remains 100% decoupled from the UI, making it immensely easier to write unit tests and migrate between state management solutions if necessary.
