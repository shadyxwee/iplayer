import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/image_cache_service.dart';
import 'services/config_service.dart';
import 'services/xtream_service.dart';
import 'services/preferences_service.dart';
import 'services/language_service.dart';
import 'providers/content_provider.dart';
import 'providers/theme_provider.dart';
import 'models/playlist.dart';
import 'screens/vortextube_screen.dart';
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

    await ImageCacheService.initialize();
    print('ImageCacheService initialized');

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(1280, 720),
        minimumSize: Size(800, 600),
        center: true,
        backgroundColor: Color(0xFF0F0F0F),
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
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
                title: 'VortexTube',
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
                  scaffoldBackgroundColor: const Color(0xFF0F0F0F),
                ),
                builder: (context, child) {
                  final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
                  if (!isDesktop) return child ?? const SizedBox.shrink();

                  return Column(
                    children: [
                      const SizedBox(
                        height: 32,
                        child: WindowCaption(
                          backgroundColor: Color(0xFF0F0F0F),
                          brightness: Brightness.dark,
                        ),
                      ),
                      Expanded(child: child ?? const SizedBox.shrink()),
                    ],
                  );
                },
                home: const VortexTubeScreen(),
              );
            },
          ),
        );
      },
    );
  }
}
