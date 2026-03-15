# FlowState — Design Decisions

This document records the key design decisions made during the creation of FlowState — covering UX philosophy, interaction design, visual system, and information architecture. Each decision was deliberate, user-research-informed, and shaped by the core philosophy that **Device = Context**.

---

## 1. Three Separate Views, Not One Responsive Layout

**Decision**: Design three entirely distinct screens — CaptureView (Mobile), StudioView (Desktop), Portal View (Web) — rather than one responsive layout that adjusts column count.

**Reasoning**:
A "bigger phone screen" is not a desktop. Attempting to use the same UI on all platforms forces compromises that make every platform experience worse. The StudioView's multi-pane editor would be completely unusable on a phone screen. The CaptureView's minimalist stream would be a waste of desktop real estate.

Each view was designed around one question: **What is the user's primary intent on this device?**

| Device | Intent | UI Optimized For |
| :--- | :--- | :--- |
| Mobile | Speed of capture | Minimal friction, big tap targets, one action |
| Desktop | Depth of processing | Multi-pane, keyboard shortcuts, dense information |
| Web | Clean consumption | Search-first, grid layout, read-only |

---

## 2. Vibrant Dark Theme — The Design Language

**Decision**: Use a vibrant dark theme with Rose-to-Indigo gradients as the primary visual language, rather than the standard flat/pastel productivity app aesthetic.

**Reasoning**:
FlowState targets focused, productive users who likely work late and use dark mode by default. A dark theme reduces eye strain during long processing sessions. However, rather than a "charcoal gray" productivity aesthetic (Notion, Obsidian), FlowState uses vibrant gradient colors to signal energy and momentum — reinforcing the "flow state" brand promise.

**Color System**:
- **Background**: Rose (`#FB7185`) → Deep Indigo (`#1E1B4B`) gradient — dynamic, energetic.
- **Cards**: Light Pink (`#FBCFE8`) → Rose (`#FDA4AF`) gradient — warm, tactile.
- **Primary Actions**: Indigo (`#6366F1`) → Sky Blue (`#0EA5E9`) — focused, directional.
- **Success/Publish**: Light Green (`#4ADE80`) → Emerald (`#10B981`) — completion feels rewarding.
- **Typography**: Outfit (display) + Inter (body) from Google Fonts — modern, readable.

**Design principle**: Every color has semantic meaning. The gradient direction (top-left to bottom-right) mirrors the "flow" of ideas downward through the pipeline.

---

## 3. NoteState as the Visual Pipeline Metaphor

**Decision**: Model each note's position in the workflow as an explicit `NoteState` enum (`raw`, `processing`, `library`) and use it to gate what appears on each platform's UI.

**Reasoning**:
Most note apps show everything everywhere. This is what creates the "Digital Graveyard" — a pile of unsorted ideas that never get used. FlowState makes the pipeline visible:
- Mobile users only see `raw` notes → they feel the pressure to process.
- Web users only see `library` notes → they get a clean, polished result.
- The Desktop is the "processing plant" that moves notes between states.

**UX benefit**: The user can see exactly how many ideas are "waiting" to be processed. An empty capture queue on mobile means they have processed everything — a small but powerful motivational reward.

---

## 4. Quick Capture Sheet — Frictionless Mobile Entry

**Decision**: Implement the primary capture action as a bottom sheet modal (70% screen height) rather than a full-screen page, triggered by a single FAB tap.

**Reasoning**:
The mobile view's single job is to get an idea from the user's head into the system as fast as possible. A full navigation push adds 300ms of animation, a back button to press, and extra cognitive load. A bottom sheet:
- Is dismissible with a downward swipe (natural gesture).
- Keeps the note stream visible behind it (context preservation).
- Auto-focuses the keyboard immediately (`autofocus: true`).

The FAB uses the `primaryGradient` (Indigo → Sky Blue) to match the "Capture" button inside the sheet — a deliberate visual consistency decision to say "these two elements are the same action."

---

## 5. Processing Score as a Visible Gamification Signal

**Decision**: Show the `processingScore` (a computed double) as a small "⚡ X pts" badge on library cards in the Portal View.

**Reasoning**:
Without visible feedback, gamification has no value. The score badge does two things:
1. Tells the user which notes had the most effort invested in them.
2. Creates a visual hierarchy in the grid — higher-scored notes feel "heavier" and more valuable.

The score is also used by the Knapsack algorithm in Smart Review Mode (Studio), creating a loop: the score you set on Desktop determines which notes surface in your next review session.

---

## 6. Hierarchical Tags — Folder Mental Model

**Decision**: Implement tags as path-like strings (`Work/Projects/FlowState`) rather than flat labels (`work`, `projects`, `flowstate`).

**Reasoning**:
Users already understand filesystem folder hierarchies. Forcing them to manage a flat tag namespace for complex knowledge systems creates cognitive overhead. Hierarchical tags:
- Map directly to how people already organize their thinking.
- Reduce tag clutter (one entry for `Work/Projects/FlowState` instead of three separate tags).
- Enable the TagTree Trie to surface smart autocomplete suggestions based on prefix matching.

**UX implementation**: Tags are displayed and entered as slash-separated paths. The TagTree is built in-memory from the note's stored tag strings on each session.

---

## 7. Studio Mode — Multi-Pane Mental Model

**Decision**: Design the StudioView as a three-column layout: Left panel (processing queue with search), Center panel (markdown editor), Right panel (context, connections, and smart actions).

**Reasoning**:
Desktop power users expect a spatial layout they can internalize. The three-column structure maps directly to the mental model of "inbox → focused work → metadata":
- **Left**: What needs my attention? (queue + search)
- **Center**: Deep, focused editing (distraction-free)
- **Right**: Context (tags, graph connections, stable matching suggestions)

The right panel is conditionally rendered only when a note is selected, avoiding visual noise when no work is in progress.

---

## 8. Adaptive Bottom Navigation vs. Side Navigation

**Decision**: On mobile, show three platform-native navigation patterns (bottom sheet for quick capture, stream list as main view). On desktop, use a multi-column layout without a navigation bar at all.

**Reasoning**:
Desktop apps do not typically have a bottom navigation bar — that is a mobile pattern. Force-fitting mobile navigation patterns onto a desktop app makes it feel like a "big phone app." FlowState's desktop Studio is a self-contained workspace, not a navigable multi-screen app — it doesn't need navigation because all three panels are always visible.

**Result**: The app feels native on each platform, not like a cross-platform compromise.

---

## 9. Developer UX: "Feature-First" Cognitive Mapping

**Decision**: Design the codebase schema itself (the folder structure) to reflect User Features rather than Technical Types (Model-View-Controller).

**Reasoning**:
A key design principle extended to **Developer UX (DX)**. When a new developer opens `lib/`, seeing `controllers/`, `views/`, and `services/` requires them to mentally reconstruct how features are built across disparate folders.

By using a **Feature-First** structure (`lib/features/notes/`), everything related to a Note — its UI, its state, its database schema — is self-contained. The cognitive load required to understand "How does the Note feature work?" is vastly reduced because the context is constrained to a single, localized directory structure.
