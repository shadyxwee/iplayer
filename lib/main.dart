import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'services/config_service.dart';
import 'services/m3u_parser.dart';
import 'services/xtream_service.dart';
import 'services/preferences_service.dart';
import 'services/language_service.dart';
import 'providers/content_provider.dart';
import 'providers/theme_provider.dart';
import 'models/playlist.dart';
import 'screens/dashboard_screen.dart';
import 'screens/mobile_dashboard_screen.dart';
import 'widgets/welcome_dialog.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ConfigService.initialize();
    print('Config service initialized');

    MediaKit.ensureInitialized();
    print('MediaKit initialized');

    await DatabaseService.initialize();
    print('Database initialized');

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(1280, 720),
        minimumSize: Size(800, 600),
        center: true,
        backgroundColor: Colors.black,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: 'RIPTV',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Error during initialization: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 24),
                const Text('Initialization Error', style: TextStyle(color: Colors.white, fontSize: 24)),
                const SizedBox(height: 16),
                Text(error, style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<XtreamService?> _xtreamServiceFuture;

  @override
  void initState() {
    super.initState();
    _xtreamServiceFuture = _initializeXtreamService();
  }

  Future<XtreamService?> _initializeXtreamService() async {
    final activePlaylistId = await PreferencesService.getActivePlaylistId();
    if (activePlaylistId != null) {
      final playlist = await DatabaseService.getPlaylistById(activePlaylistId);
      if (playlist != null &&
          playlist.sourceType == PlaylistSourceType.xtreamCodes &&
          playlist.username != null &&
          playlist.password != null) {
        return XtreamService(
          baseUrl: playlist.url,
          username: playlist.username!,
          password: playlist.password!,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<XtreamService?>(
      future: _xtreamServiceFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator())),
          );
        }

        final xtreamService = snapshot.data;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ContentProvider(xtreamService)),
            ChangeNotifierProvider(create: (_) => LanguageService()..loadSavedLanguage()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return MaterialApp(
                title: 'RIPTV',
                debugShowCheckedModeBanner: false,
                locale: languageService.currentLocale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                themeMode: ThemeMode.dark,
                darkTheme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: const Color(0xFF0A0A0A),
                ),
                home: const SplashScreen(),
              );
            },
          ),
        );
      },
    );
  }
}

// ====================== PROFESSIONAL SPLASH SCREEN ======================

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const String _firstLaunchKey = 'first_launch';

  late AnimationController _controller;
  late Animation<double> _iconFade;
  late Animation<double> _iconScale;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _loadingFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );

    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)),
    );

    _iconScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8)),
    );

    _textSlide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic)),
    );

    _loadingFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0)),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2800));

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

      final bool isAndroid = !kIsWeb && Platform.isAndroid;

      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => isAndroid
              ? MobileDashboardScreen(showWelcomeDialog: isFirstLaunch)
              : DashboardScreen(showWelcomeDialog: isFirstLaunch),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Icon
            FadeTransition(
              opacity: _iconFade,
              child: ScaleTransition(
                scale: _iconScale,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.tv_rounded,
                    size: 110,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),

            // Title & Subtitle
            FadeTransition(
              opacity: _textFade,
              child: SlideTransition(
                position: _textSlide.drive(Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                )),
                child: Column(
                  children: [
                    const Text(
                      'RIPTV',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Premium IPTV Experience',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 90),

            // Elegant Loading
            FadeTransition(
              opacity: _loadingFade,
              child: Column(
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).loading,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}