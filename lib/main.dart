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
  try {
    // Initialise core services.
    final databaseService = DatabaseService();
    await databaseService.init();

    final vectorStore = VectorStore(databaseService: databaseService);
    await vectorStore.init();

    final llmService = LlmService();
    final embeddingService = EmbeddingService();
    final ragPipeline = RagPipeline(
      vectorStore: vectorStore,
      llmService: llmService,
      embeddingService: embeddingService,
    );

    final calendarService = CalendarService();
    final fileService = FileService();

    runApp(
      MultiProvider(
        providers: [
          // Services  exposed so nested providers can access them.
        ],
        child: App(
          databaseService: databaseService,
          vectorStore: vectorStore,
          llmService: llmService,
          embeddingService: embeddingService,
          ragPipeline: ragPipeline,
          calendarService: calendarService,
          fileService: fileService,
        ),
      ),
    );
  } catch (e, stack) {
    // Print error to console and show a simple error widget
    print('Startup error: '
        '');
    print(e);
    print(stack);
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Startup error:\n\n'
              '${e.toString()}'),
        ),
      ),
    ));
  }
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
