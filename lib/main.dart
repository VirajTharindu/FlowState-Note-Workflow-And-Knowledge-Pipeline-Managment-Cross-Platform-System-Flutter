import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/theme/app_theme.dart';
import 'features/notes/providers/notes_provider.dart';
import 'features/notes/providers/web_notes_repository.dart';
import 'features/notes/views/capture_view.dart';
import 'features/notes/views/studio_view.dart';
import 'features/notes/views/portal_view.dart';
import 'shared/layout/adaptive_scaffold.dart';

// Conditional import: on web, import the stub; on native, import real Isar+window_manager
import 'main_native.dart' if (dart.library.html) 'main_web.dart' as platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform-specific initialization and repository creation
  final repository = await platform.initPlatform();

  runApp(
    ProviderScope(
      overrides: [
        notesRepositoryProvider.overrideWithValue(repository),
      ],
      child: const FlowStateApp(),
    ),
  );
}

class FlowStateApp extends StatelessWidget {
  const FlowStateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowState',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const FlowStateHome(),
    );
  }
}

class FlowStateHome extends StatelessWidget {
  const FlowStateHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScaffold(
      mobile: CaptureView(),
      desktop: StudioView(),
      web: PortalView(),
    );
  }
}
