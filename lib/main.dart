import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/local_notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'firebase_options.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/bible_screen.dart';
import 'screens/bible_ai_entry_screen.dart';
import 'features/bible_ai/features/bible/screens/bible_home_screen.dart';
import 'features/bible_ai/features/bible/widgets/verse_of_day_card.dart';
import 'features/pneuma_ai/screens/pneuma_ai_hub_screen.dart';
import 'package:church_mobile/features/pneuma_ai/config/app_config.dart' as pneuma_config;
import 'screens/bible_reading_plan_screen.dart';
import 'screens/blog/blog_detail_screen.dart';
import 'screens/blog/blog_list_screen.dart';
import 'screens/devotional_screen.dart';
import 'screens/event_details_screen.dart';
import 'screens/event_screen.dart';
import 'models/event.dart' as app_event;
import 'screens/hymn_screen.dart';
import 'screens/library/library_screen.dart';
import 'screens/live_stream_screen.dart';
import 'screens/media/gallery_screen.dart';
import 'screens/media/video_screen.dart';
import 'screens/members/members_connect_screen.dart';
import 'features/notes/presentation/screens/standalone_notes_screen.dart';
import 'screens/sermon_screen.dart';
import 'services/audio_player_service.dart';
import 'services/bible_service.dart';
import 'services/note_service.dart';
import 'services/fcm_service.dart'; // Replaced OneSignal
import 'services/sermon_service.dart';
import 'services/event_service.dart';
import 'utils/data_migration.dart';
import 'utils/toast_utils.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/home/upcoming_event_card.dart';
import 'widgets/home_carousel.dart';
import 'features/notes/data/models/standalone_note_model.dart';
import 'features/notes/data/models/linked_content_reference.dart';
import 'features/notes/data/models/note_tag_model.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Enable offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    print('Firebase initialized successfully');

    // Initialize local notifications
    await LocalNotificationService().initialize();
    await LocalNotificationService().requestPermission();

    // Initialize FCM and request permissions
    await FcmService.initialize();

    // Test Firestore connection
    try {
      print('Testing Firestore connection...');
      await FirebaseFirestore.instance.collection('test').limit(1).get();
      print('Firestore connection successful');

      // Run data migrations
      print('Running data migrations...');
      await DataMigration.migrateCarouselItems();
      print('Data migrations completed');
    } catch (e) {
      print('Error connecting to Firestore: $e');
      ToastUtils.showToast('Error connecting to database');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
    ToastUtils.showToast('Error initializing app');
  }

  // Initialize audio service
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.church_mobile.channel.audio',
    androidNotificationChannelName: 'Church Mobile Audio',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  // Initialize Hive for Bible AI offline config caching
  await Hive.initFlutter();
  await Hive.openBox<String>('bible_ai_cache');
  await pneuma_config.AppConfig.initHive();

  // Register adapters and open boxes for the new Notes feature
  if (!Hive.isAdapterRegistered(100)) {
    Hive.registerAdapter(StandaloneNoteAdapter());
  }
  if (!Hive.isAdapterRegistered(101)) {
    Hive.registerAdapter(LinkedContentTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(102)) {
    Hive.registerAdapter(LinkedContentReferenceAdapter());
  }
  if (!Hive.isAdapterRegistered(103)) {
    Hive.registerAdapter(NoteTagAdapter());
  }
  await Hive.openBox<StandaloneNote>('notes_box');
  await Hive.openBox<NoteTag>('tags_box');
  await Hive.openBox('notes_preferences_box');

  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  final bibleService = BibleService(prefs);
  final sermonService = SermonService();
  final audioPlayerService = AudioPlayerService();
  final noteService = NoteService(prefs);

  await bibleService.loadBible();

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
          ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
        ],
        child: MyApp(
          prefs: prefs,
          bibleService: bibleService,
          sermonService: sermonService,
          audioPlayerService: audioPlayerService,
          noteService: noteService,
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.prefs,
    required this.bibleService,
    required this.sermonService,
    required this.audioPlayerService,
    required this.noteService,
  }) : super(key: key);
  final SharedPreferences prefs;
  final BibleService bibleService;
  final SermonService sermonService;
  final AudioPlayerService audioPlayerService;
  final NoteService noteService;

  static MyApp of(BuildContext context) {
    final _MyAppScope scope =
        context.dependOnInheritedWidgetOfExactType<_MyAppScope>()!;
    return scope.data;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        return _MyAppScope(
          data: this,
          child: MaterialApp(
            scaffoldMessengerKey: ToastUtils.messengerKey,
            title: 'GSWMI',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: languageProvider.currentLocale,
            supportedLocales: [
              ...LanguageProvider.supportedLocales.values,
              ...FlutterQuillLocalizations.supportedLocales,
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            home: const SplashScreen(),
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              if (isDark) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0A0E17), // Deepest dark midnight blue
                        Color(0xFF121B2D), // Rich dark navy
                        Color(0xFF1B283F), // Lighter slate blue at the top
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: child,
                );
              }
              return child ?? const SizedBox.shrink();
            },
            routes: {
              '/home': (context) => const HomePage(),
              '/bible': (context) => const BibleAiEntryScreen(),
              '/notes': (context) => const StandaloneNotesScreen(),
              '/sermons': (context) => SermonScreen(
                    sermonService: MyApp.of(context).sermonService,
                    audioPlayerService: MyApp.of(context).audioPlayerService,
                  ),
              '/devotional': (context) => const DevotionalScreen(),
              '/live': (context) => const LiveStreamScreen(),
              '/events': (context) => const EventScreen(),
              '/hymns': (context) => const HymnScreen(),
              '/blog': (context) => const BlogListScreen(),
              '/library': (context) => const LibraryScreen(),
              '/members': (context) => const MembersConnectScreen(),
              '/videos': (context) => const VideoScreen(),
              '/gallery': (context) => const GalleryScreen(),
            },
            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '');

              // Handle event details route
              if (uri.path == '/event-details') {
                final eventId = uri.queryParameters['id'];
                if (eventId != null) {
                  return MaterialPageRoute(
                    builder: (context) => FutureBuilder<app_event.Event?>(
                      future: EventService().getEventById(eventId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Scaffold(
                              body: Center(child: CircularProgressIndicator()));
                        }
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data == null) {
                          return Scaffold(
                            appBar: AppBar(title: const Text('Event Details')),
                            body: const Center(child: Text('Event not found')),
                          );
                        }
                        return Scaffold(
                          backgroundColor: Colors.black45,
                          appBar: AppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            leading: const BackButton(color: Colors.white),
                          ),
                          body: EventDetailsScreen(event: snapshot.data!),
                        );
                      },
                    ),
                  );
                }
              }

              // Handle blog detail route
              if (uri.path == '/blog-detail') {
                final postId = uri.queryParameters['id'];
                if (postId != null) {
                  return MaterialPageRoute(
                    builder: (context) => BlogDetailScreen(postId: postId),
                  );
                }
              }

              // Handle sermon detail route
              if (uri.path.startsWith('/sermons/')) {
                final sermonId = uri.pathSegments.last;
                return MaterialPageRoute(
                  builder: (context) => SermonScreen(
                    sermonService: MyApp.of(context).sermonService,
                    audioPlayerService: MyApp.of(context).audioPlayerService,
                    initialSermonId: sermonId,
                  ),
                );
              }

              // If no matching route is found
              return MaterialPageRoute(
                builder: (context) => const HomePage(),
              );
            },
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Page Not Found')),
                  body: Center(
                    child: Text('Route ${settings.name} not found'),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MyAppScope extends InheritedWidget {
  const _MyAppScope({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);
  final MyApp data;

  @override
  bool updateShouldNotify(_MyAppScope oldWidget) => data != oldWidget.data;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      FlutterNativeSplash.remove();
      // Skip SharedPreferences initialization on web
      if (!kIsWeb) {
        await SharedPreferences.getInstance();
      }

      // Delay for splash screen
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing app: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BibleService? _bibleService;
  NoteService? _noteService;
  bool _isLoading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initServices();
      _initialized = true;
    }
  }

  Future<void> _initServices() async {
    try {
      setState(() => _isLoading = true);
      _bibleService = MyApp.of(context).bibleService;
      _noteService = MyApp.of(context).noteService;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  final List<Map<String, dynamic>> quickActions = [
    {
      'icon': Icons.live_tv,
      'label': 'Live Stream',
      'color': Colors.red,
      'route': (BuildContext context) => const LiveStreamScreen(),
    },
    {
      'icon': Icons.play_circle_filled,
      'label': 'Sermons',
      'color': Colors.orange,
      'route': (BuildContext context) => SermonScreen(
            sermonService: MyApp.of(context).sermonService,
            audioPlayerService: MyApp.of(context).audioPlayerService,
          ),
    },
    {
      'icon': Icons.menu_book,
      'label': 'AI Bible',
      'color': Colors.indigo,
      'route': (BuildContext context) => const BibleAiEntryScreen(),
    },
    {
      'icon': Icons.book,
      'label': 'Devotional',
      'color': Colors.purple,
      'route': (BuildContext context) => const DevotionalScreen(),
    },
    {
      'icon': Icons.auto_awesome,
      'label': 'Pneuma AI',
      'color': Color(0xFF6B2FC8),
      'route': (BuildContext context) => const PneumaAiHubScreen(),
    },
  ];

  final List<Map<String, dynamic>> mediaButtons = [
    {
      'icon': Icons.play_circle_filled,
      'label': 'Sermons',
      'color': Colors.orange,
      'route': (BuildContext context) => SermonScreen(
            sermonService: MyApp.of(context).sermonService,
            audioPlayerService: MyApp.of(context).audioPlayerService,
          ),
    },
    {
      'icon': Icons.video_library,
      'label': 'Videos',
      'color': Colors.red,
      'route': (BuildContext context) => const VideoScreen(),
    },
    {
      'icon': Icons.photo_library,
      'label': 'Gallery',
      'color': Colors.purple,
      'route': (BuildContext context) => const GalleryScreen(),
    },
    {
      'icon': Icons.radio,
      'label': 'Radio',
      'color': Colors.blue,
      'route': null,
    },
    {
      'icon': Icons.local_library,
      'label': 'Library',
      'color': Colors.brown,
      'route': (BuildContext context) => const LibraryScreen(),
    },
  ];

  final List<Map<String, dynamic>> engagementButtons = [
    {
      'icon': Icons.music_note,
      'label': 'Hymns',
      'color': Colors.indigo,
      'route': (BuildContext context) => const HymnScreen(),
    },
    {
      'icon': Icons.monetization_on,
      'label': 'Donation',
      'color': Colors.green,
      'route': null,
    },
    {
      'icon': Icons.note_alt,
      'label': 'Notes',
      'color': Colors.amber,
      'route': (BuildContext context) => const StandaloneNotesScreen(),
    },
    {
      'icon': Icons.event,
      'label': 'Events',
      'color': Colors.orange,
      'route': (BuildContext context) => const EventScreen(),
    },
    {
      'icon': Icons.rss_feed,
      'label': 'Blog',
      'color': Colors.blue,
      'route': (BuildContext context) => const BlogListScreen(),
    },
  ];

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildButtonGrid(List<Map<String, dynamic>> buttons) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 5,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      mainAxisSpacing: 12,
      crossAxisSpacing: 8,
      childAspectRatio: 0.6,
      children: buttons.map((button) {
        return InkWell(
          onTap: () {
            if (button['route'] != null) {
              final routeBuilder = button['route'] as Function;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => routeBuilder(context),
                ),
              );
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (button['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  button['icon'] as IconData,
                  color: button['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  button['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black87,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Verse of the Day replaced with ContinueReadingCard

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: MediaQuery.of(context).size.width * (178 / 1105),
            collapsedHeight: MediaQuery.of(context).size.width * (178 / 1105),
            expandedHeight: MediaQuery.of(context).size.width * (178 / 1105),
            pinned: true,
            elevation: 4.0,
            backgroundColor: const Color(0xFF0D1B2A),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(
                'assets/images/home_hero.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeCarousel(collectionPath: 'carousel_items'),
                _buildSectionTitle('Quick Actions'),
                _buildButtonGrid(quickActions),
                const VerseOfDayCard(),
                _buildSectionTitle('Media'),
                _buildButtonGrid(mediaButtons),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UpcomingEventCard(),
                    ],
                  ),
                ),
                _buildSectionTitle('Engagement'),
                _buildButtonGrid(engagementButtons),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
