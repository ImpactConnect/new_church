import 'package:hive/hive.dart';
import '../features/berean/models/berean_evaluation_model.dart';
import '../features/exegesis/storage/exegesis_final_hive_storage.dart';

/// Application configuration constants for the Bible AI feature.
class AppConfig {
  /// Hive box name used by AiConfigService for caching AI configuration.
  static const String cacheBoxName = 'bible_ai_cache';

  /// Hive box name for chat sessions
  static const String chatSessionsBoxName = 'bible_ai_cache';

  /// Hive box name for Berean evaluations
  static const String bereanBoxName = 'berean_evaluations';

  /// Firestore collection for users
  static const String usersCollection = 'users';

  /// Initialize all Hive adapters and open boxes for Pneuma AI.
  static Future<void> initHive() async {
    // 1. Register Berean adapters if not registered
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(BereanEvaluationModelAdapter());
    }
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(BereanScriptureRefAdapter());
    }
    if (!Hive.isAdapterRegistered(32)) {
      Hive.registerAdapter(AlignmentVerdictAdapter());
    }
    if (!Hive.isAdapterRegistered(33)) {
      Hive.registerAdapter(InterpretiveTensionsAdapter());
    }
    if (!Hive.isAdapterRegistered(34)) {
      Hive.registerAdapter(InterpretiveViewAdapter());
    }
    if (!Hive.isAdapterRegistered(35)) {
      Hive.registerAdapter(RhetoricalFlagAdapter());
    }
    if (!Hive.isAdapterRegistered(36)) {
      Hive.registerAdapter(ContextWarningAdapter());
    }
    if (!Hive.isAdapterRegistered(37)) {
      Hive.registerAdapter(DoctrineClassificationAdapter());
    }
    if (!Hive.isAdapterRegistered(38)) {
      Hive.registerAdapter(ExampleScenarioAdapter());
    }
    if (!Hive.isAdapterRegistered(39)) {
      Hive.registerAdapter(UserGuidanceAdapter());
    }

    // 2. Register Exegesis final adapters
    ExegesisFinalHiveAdapters.registerAdapters();

    // 3. Open Berean evaluations box
    await Hive.openBox<BereanEvaluationModel>(bereanBoxName);
  }
}
