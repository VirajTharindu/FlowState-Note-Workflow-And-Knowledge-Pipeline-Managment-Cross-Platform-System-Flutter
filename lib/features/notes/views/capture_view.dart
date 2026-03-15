import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flow_state/features/notes/providers/notes_provider.dart';
import 'package:flow_state/features/notes/models/note.dart';
import 'package:flow_state/core/theme/app_colors.dart';
import 'package:flow_state/core/theme/app_text_styles.dart';
import 'package:flow_state/core/constants/app_spacing.dart';
import 'package:flow_state/core/data_structures/tag_tree.dart';

class CaptureView extends ConsumerWidget {
  const CaptureView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawNotes = ref.watch(rawNotesProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: Text('FlowState: Stream', style: AppTextStyles.h1),
              actions: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
              ],
            ),
            rawNotes.when(
              data: (notes) => notes.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(child: Text('Your flux is empty. Capture something!')),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final note = notes[index];
                            return _CaptureCard(note: note).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
                          },
                          childCount: notes.length,
                        ),
                      ),
                    ),
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddNoteDialog(context, ref),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusXl),
            topRight: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: TextField(
                controller: contentController,
                autofocus: true,
                maxLines: null,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Quick capture...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
            Row(
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.mic_none_rounded)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined)),
                IconButton(
                  onPressed: () {
                    // Demonstrate TagTree suggestions
                    final tree = TagTree();
                    tree.insert('Work/Projects/FlowState');
                    tree.insert('Work/Admin/Taxes');
                    tree.insert('Personal/Health/Gym');
                    
                    final suggestions = tree.getSuggestions('Work');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Suggestions: ${suggestions.join(", ")}'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.tag_rounded),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (contentController.text.isNotEmpty) {
                        ref.read(notesRepositoryProvider).addNote(
                            'Untiled ${DateTime.now().hour}:${DateTime.now().minute}',
                            contentController.text,
                            NoteState.raw,
                          );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                    child: const Text('Capture', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ).animate().shimmer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  final Note note;
  const _CaptureCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient, // Light Pink to Rose
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                note.updatedAt.toString().split('.')[0].substring(11, 16),
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(note.content, style: AppTextStyles.bodyMedium.copyWith(color: Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
