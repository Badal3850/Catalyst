import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/notes/providers/notes_provider.dart';
import 'features/voice/providers/voice_provider.dart';
import 'services/ai/llm_service.dart';
import 'services/ai/embedding_service.dart';
import 'services/ai/rag_pipeline.dart';
import 'services/storage/database_service.dart';
import 'services/storage/vector_store.dart';
import 'services/actions/calendar_service.dart';
import 'services/actions/file_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise core services inside a try-catch so that runApp() is always
  // reached. Without this, any exception thrown during initialisation
  // (e.g. SQLite FTS5 not supported on the device, path_provider failure)
  // would leave the app stuck on the native splash screen because Flutter
  // never renders its first frame.
  DatabaseService? databaseService;
  VectorStore? vectorStore;
  String? initError;

  try {
    databaseService = DatabaseService();
    await databaseService.init();

    vectorStore = VectorStore(databaseService: databaseService);
    await vectorStore.init();
  } catch (e) {
    initError = e.toString();
  }

  final llmService = LlmService();
  final embeddingService = EmbeddingService();
  final calendarService = CalendarService();
  final fileService = FileService();

  // If database initialisation failed, show an error screen instead of
  // crashing silently on the splash screen.
  if (databaseService == null ||
      !databaseService.isInitialised ||
      vectorStore == null ||
      initError != null) {
    runApp(_InitErrorApp(error: initError ?? 'Database failed to initialise'));
    return;
  }

  final ragPipeline = RagPipeline(
    vectorStore: vectorStore,
    llmService: llmService,
    embeddingService: embeddingService,
  );

  runApp(
    MultiProvider(
      providers: [
        // Services — exposed so nested providers can access them.
        Provider<DatabaseService>.value(value: databaseService),
        Provider<VectorStore>.value(value: vectorStore),
        Provider<LlmService>.value(value: llmService),
        Provider<EmbeddingService>.value(value: embeddingService),
        Provider<RagPipeline>.value(value: ragPipeline),
        Provider<CalendarService>.value(value: calendarService),
        Provider<FileService>.value(value: fileService),

        // Feature providers.
        ChangeNotifierProvider(
          create:
              (context) => ChatProvider(
                ragPipeline: context.read<RagPipeline>(),
                calendarService: context.read<CalendarService>(),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => NotesProvider(
                databaseService: context.read<DatabaseService>(),
                embeddingService: context.read<EmbeddingService>(),
                vectorStore: context.read<VectorStore>(),
                fileService: context.read<FileService>(),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => VoiceProvider(
                databaseService: context.read<DatabaseService>(),
                llmService: context.read<LlmService>(),
              ),
        ),
      ],
      child: const CoreBrainApp(),
    ),
  );
}

/// Minimal error app shown when core services fail to initialise.
class _InitErrorApp extends StatelessWidget {
  const _InitErrorApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'CoreBrain failed to start',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
