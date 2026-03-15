import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flow_state/features/notes/providers/notes_provider.dart';
import 'package:flow_state/features/notes/models/note.dart';
import 'package:flow_state/core/theme/app_colors.dart';
import 'package:flow_state/core/theme/app_text_styles.dart';
import 'package:flow_state/core/constants/app_spacing.dart';
import 'package:flow_state/core/algorithms/dijkstra.dart';

final selectedNoteProvider = StateProvider<Note?>((ref) => null);

class StudioView extends ConsumerWidget {
  const StudioView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredNotes = ref.watch(filteredNotesProvider(NoteState.raw));
    final selectedNote = ref.watch(selectedNoteProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Row(
          children: [
          // Column 1: Processing Queue & Search
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.glassBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Studio Mode', style: AppTextStyles.h2),
                      const SizedBox(height: AppSpacing.md),
                      _SearchBar(),
                      const SizedBox(height: AppSpacing.md),
                      _SmartReviewButton(),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredNotes.when(
                    data: (notes) {
                      final optimizedIds = ref.watch(optimizedSessionProvider);
                      final displayNotes = optimizedIds == null
                          ? notes
                          : notes.where((n) => optimizedIds.contains(n.id)).toList();

                      return ListView.builder(
                        itemCount: displayNotes.length,
                        itemBuilder: (context, index) {
                          final note = displayNotes[index];
                          final isSelected = selectedNote?.id == note.id;
                          return _QueueTile(note: note, isSelected: isSelected);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),
          // Column 2: Editor
          Expanded(
            flex: 2,
            child: selectedNote == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 64, color: AppColors.primary),
                        const SizedBox(height: AppSpacing.md),
                        Text('Select a note to process', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70)),
                      ],
                    ),
                  )
                : _NoteEditor(note: selectedNote),
          ),
          // Column 3: Metadata & Links (Context Column)
          if (selectedNote != null)
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(left: BorderSide(color: AppColors.glassBorder)),
              ),
              child: _ContextPanel(note: selectedNote),
            ).animate().fadeIn().slideX(begin: 0.1),
        ],
      ),
    ),
  );
  }
}

final optimizedSessionProvider = StateProvider<List<int>?>((ref) => null);

class _SmartReviewButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOptimizing = ref.watch(optimizedSessionProvider) != null;

    return InkWell(
      onTap: () async {
        if (isOptimizing) {
          ref.read(optimizedSessionProvider.notifier).state = null;
        } else {
          // Calculate optimized session using Knapsack (15 min capacity)
          final repository = ref.read(notesRepositoryProvider);
          final result = await repository.getOptimizedSession(15);
          ref.read(optimizedSessionProvider.notifier).state = result.selectedIds;
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isOptimizing ? AppColors.accent.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: isOptimizing ? AppColors.accent : AppColors.primary),
        ),
        child: Row(
          children: [
            Icon(
              isOptimizing ? Icons.auto_awesome : Icons.timer_outlined,
              size: 18,
              color: isOptimizing ? AppColors.accent : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              isOptimizing ? 'Review Mode: ON' : 'Start 15-min Session',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isOptimizing ? AppColors.accent : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
        decoration: const InputDecoration(
          hintText: 'Search raw notes...',
          border: InputBorder.none,
          icon: Icon(Icons.search, size: 18),
        ),
      ),
    );
  }
}

class _QueueTile extends ConsumerWidget {
  final Note note;
  final bool isSelected;
  const _QueueTile({required this.note, required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      leading: Container(
        width: 4,
        height: 24,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(note.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall),
      onTap: () => ref.read(selectedNoteProvider.notifier).state = note,
    );
  }
}

class _NoteEditor extends ConsumerStatefulWidget {
  final Note note;
  const _NoteEditor({required this.note});

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _previewMode = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void didUpdateWidget(_NoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      _titleController.text = widget.note.title;
      _contentController.text = widget.note.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  style: AppTextStyles.h1,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Untitled'),
                  onChanged: (val) => ref.read(notesRepositoryProvider).updateNote(widget.note.id, title: val),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _previewMode = !_previewMode),
                icon: Icon(_previewMode ? Icons.edit : Icons.remove_red_eye, color: AppColors.primary),
                tooltip: _previewMode ? 'Edit Mode' : 'Preview Mode',
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _previewMode
                ? Markdown(data: _contentController.text, styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)))
                : TextField(
                    controller: _contentController,
                    style: AppTextStyles.bodyLarge,
                    maxLines: null,
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Start synthesizing your ideas...'),
                    onChanged: (val) => ref.read(notesRepositoryProvider).updateNote(widget.note.id, content: val),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final repo = ref.read(notesRepositoryProvider);
                  repo.updateNoteState(widget.note.id, NoteState.library);
                  ref.read(selectedNoteProvider.notifier).state = null;
                },
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Publish to Library'),
                style: TextButton.styleFrom(backgroundColor: AppColors.success.withOpacity(0.1), foregroundColor: AppColors.success),
              ).animate().shimmer(delay: 2.seconds),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContextPanel extends ConsumerWidget {
  final Note note;
  const _ContextPanel({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Context', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.lg),
          _MetaItem(label: 'Captured', value: note.createdAt.toString().split('.')[0]),
          _MetaItem(label: 'Last Edited', value: note.updatedAt.toString().split('.')[0]),
          const SizedBox(height: AppSpacing.xl),
          Text('Tags', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            children: (note.tags ?? ['General']).map((t) => Chip(
              label: Text(t, style: const TextStyle(fontSize: 12)),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              side: BorderSide.none,
            )).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          _GraphConnections(note: note),
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          _StableMarriageSuggestions(note: note),
        ],
      ),
    );
  }
}

class _StableMarriageSuggestions extends ConsumerStatefulWidget {
  final Note note;
  const _StableMarriageSuggestions({required this.note});

  @override
  ConsumerState<_StableMarriageSuggestions> createState() => _StableMarriageSuggestionsState();
}

class _StableMarriageSuggestionsState extends ConsumerState<_StableMarriageSuggestions> {
  Map<int, int>? _matches;
  bool _calculating = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Stable Idea Matching', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            if (_calculating)
              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
          onPressed: () async {
            setState(() => _calculating = true);
            // Match current note and potential peers to categories
            final categories = ['Work', 'Projects', 'Finance', 'Personal'];
            final repository = ref.read(notesRepositoryProvider);
            final matches = await repository.matchNotesToCategories([widget.note.id], categories);
            setState(() {
              _matches = matches;
              _calculating = false;
            });
          },
          icon: const Icon(Icons.compare_arrows_rounded, size: 16),
          label: const Text('Find Optimal Category'),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: AppColors.secondary,
          ),
        ),
        if (_matches != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Matched to: ${['Work', 'Projects', 'Finance', 'Personal'][_matches![0]!]}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
            ),
          ).animate().fadeIn(),
      ],
    );
  }
}

class _GraphConnections extends ConsumerStatefulWidget {
  final Note note;
  const _GraphConnections({required this.note});

  @override
  ConsumerState<_GraphConnections> createState() => _GraphConnectionsState();
}

class _GraphConnectionsState extends ConsumerState<_GraphConnections> {
  DijkstraResult? _pathResult;
  bool _calculating = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Knowledge Graph', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            if (_calculating)
              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
          onPressed: () async {
            setState(() => _calculating = true);
            // Logic: For demo, we just find path to note ID 1 or another random note
            final repository = ref.read(notesRepositoryProvider);
            final result = await repository.findShortestPath(widget.note.id, 1);
            setState(() {
              _pathResult = result;
              _calculating = false;
            });
          },
          icon: const Icon(Icons.hub_outlined, size: 16),
          label: const Text('Find Shortest Path to Root'),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: AppColors.accent,
          ),
        ),
        if (_pathResult != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connection Path:', style: AppTextStyles.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  children: _pathResult!.path.map((id) {
                    final isLast = id == _pathResult!.path.last;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#$id', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                        if (!isLast) const Icon(Icons.chevron_right, size: 12, color: Colors.white24),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text('Distance: ${_pathResult!.distance.toStringAsFixed(1)}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
