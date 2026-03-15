import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flow_state/features/notes/providers/notes_provider.dart';
import 'package:flow_state/features/notes/models/note.dart';
import 'package:flow_state/core/theme/app_colors.dart';
import 'package:flow_state/core/theme/app_text_styles.dart';
import 'package:flow_state/core/constants/app_spacing.dart';

class PortalView extends ConsumerWidget {
  const PortalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryNotes = ref.watch(filteredNotesProvider(NoteState.library));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: Text('FlowState: Portal', style: AppTextStyles.h1),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _PortalSearchBar(),
                ),
              ),
            ),
            libraryNotes.when(
              data: (notes) => notes.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(child: Text('Nothing here yet. Process your notes on Desktop!')),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final note = notes[index];
                            return _LibraryCard(note: note)
                                .animate()
                                .fadeIn(delay: (index * 50).ms)
                                .scale(begin: const Offset(0.9, 0.9));
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
    );
  }
}

class _PortalSearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
        decoration: const InputDecoration(
          hintText: 'Search your library...',
          prefixIcon: Icon(Icons.search_rounded),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  final Note note;
  const _LibraryCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Library', style: AppTextStyles.bodySmall.copyWith(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              if (note.processingScore != null)
                Text(
                  '⚡ ${note.processingScore!.toStringAsFixed(0)} pts',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.black54, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(note.title, style: AppTextStyles.h2.copyWith(color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Text(
              note.content,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.black54),
              overflow: TextOverflow.fade,
            ),
          ),
          const Divider(height: 32, color: Colors.black12),
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black12,
                child: Icon(Icons.person, size: 14, color: Colors.black54),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Processed', style: AppTextStyles.bodySmall.copyWith(color: Colors.black54)),
              const Spacer(),
              Text(
                note.updatedAt.toString().split(' ')[0],
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
