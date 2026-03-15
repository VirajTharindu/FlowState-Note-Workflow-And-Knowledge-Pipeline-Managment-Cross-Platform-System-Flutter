# FlowState — Product Roadmap

This document tracks what has been built and defines clear phases for future development.

---

## ✅ Phase 1 — Foundation (Current State)

### Core Pipeline
- [x] `NoteState` enum: `raw → processing → library`
- [x] Note model with gamification field (`processingScore`)
- [x] Bidirectional note linking schema (`linkedNoteIds`)
- [x] Hierarchical tag system (TagTree / Trie)
- [x] Isar Community DB — offline-first local DB for Mobile & Desktop ⚠️ _(temporary)_
- [x] In-memory Web repository — seeded data for web ⚠️ _(temporary)_

> **Note on Current Databases**: Both the Isar Community DB (native) and the in-memory web repository are **temporary development databases**. They will be replaced by MongoDB Atlas in Phase 2.

### Platform-Adaptive UI
- [x] `AdaptiveScaffold` — routes Mobile / Desktop / Web to correct view
- [x] **CaptureView** (Mobile): Minimalist raw note stream, quick capture sheet
- [x] **StudioView** (Desktop): Multi-pane editor with processing queue
- [x] **PortalView** (Web): Searchable knowledge grid
- [x] Markdown preview/edit toggle in Studio

### Algorithm Engine
- [x] Dijkstra's Algorithm → Knowledge Graph "Shortest Path to Root"
- [x] Knapsack Algorithm → Smart Review "15-Minute Optimized Session"
- [x] Gale-Shapley → "Find Optimal Category" auto-matching
- [x] MergeSort → Priority note sorting (favorites > score > recency)

### Data & State
- [x] Isar Community DB — offline-first, native (Mobile + Desktop)
- [x] Web-compatible in-memory repository (stub)
- [x] Riverpod state management with real-time `StreamProvider`
- [x] Search and filter by state

### Design
- [x] Vibrant dark theme (Rose → Indigo gradient palette)
- [x] Google Fonts typography (Outfit + Inter)
- [x] flutter_animate micro-animations

---

## 🔄 Phase 2 — MongoDB Atlas Cloud Integration (Next Priority)

> The primary goal of Phase 2 is to **replace the temporary databases** with MongoDB Atlas as the single cloud brain, connecting all three devices in real-time.

### Why MongoDB Atlas?
- **Real-time sync**: MongoDB Change Streams push updates from Desktop to Mobile and Web instantly.
- **Single source of truth**: One document database for all platforms — no more Isar + web stub split.
- **Document model fit**: The `Note` entity (with embedded `tags[]` and `linkedNoteIds[]`) maps naturally to MongoDB's BSON document schema.
- **Flexible schema**: Future fields (media links, AI embeddings) can be added without migrations.
- **Built-in Atlas Search**: Enables powerful full-text search across the knowledge library natively.

### Migration Tasks
- [ ] Set up MongoDB Atlas cluster with a `notes` collection matching the `Note` schema
- [ ] Implement `MongoDbNotesRepository` (replaces `IsarNotesRepository` + `WebNotesRepository`)
- [ ] Real-time sync via MongoDB Change Streams — cross-device live updates
- [ ] Document-level access control for multi-user support
- [ ] Conflict resolution strategy (last-write-wins approach)
- [ ] JWT-based authentication (Email / Google OAuth)
- [ ] Per-user note isolation + profile persistence

### Media Capture (Mobile)
- [ ] Voice note recording (audio attachment)
- [ ] Camera photo attachment
- [ ] Media storage to MongoDB GridFS or a cloud storage bucket

---

## 🚀 Phase 3 — Intelligence Layer

> Phase 3 makes FlowState smart about your notes.

### AI-Powered Features
- [ ] Dart Frog backend for AI processing endpoint
- [ ] Auto-summarization: condense `raw` notes into a draft on Desktop
- [ ] Semantic linking: AI suggests related notes when you edit
- [ ] Auto-tagging: AI suggests hierarchical tags based on note content

### Full Knowledge Graph
- [ ] Visual interactive knowledge graph (node/edge visualization)
- [ ] Link by concept, not just manual `linkedNoteIds`
- [ ] Graph-based note discovery ("What notes relate to this idea?")

### Gamification
- [ ] Processing streaks ("You processed 5 notes this week!")
- [ ] Processing score leaderboard (personal history)
- [ ] Level-up system based on consistent note processing

---

## 💡 Future Ideas (Parking Lot)

| Idea | Description |
| :--- | :--- |
| **Obsidian Export** | Export notes as a `.md` vault for power users |
| **Browser Extension** | Capture from web pages directly into the Mobile queue |
| **Team Mode** | Shared note pipelines for teams |
| **iOS App** | Native iOS compilation via Flutter |
| **macOS App** | Desktop mode compiled for macOS |
| **Contextual Reminders** | Remind the user to process notes after 24h |
