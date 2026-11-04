import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/tv_theme.dart';
import 'core/image_cache_service.dart';
import 'bridge/rust_bridge.dart';
import 'features/home/vortextube_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android TV Leanback Landscape Setup
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Rust backend bridge & image cache
  RustBridge.initialize();
  await TVImageCacheService.initialize();

  runApp(const VortexTubeApp());
}

class VortexTubeApp extends StatelessWidget {
  const VortexTubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VortexTube',
      debugShowCheckedModeBanner: false,
      theme: TVTheme.themeData,
      home: const VortexTubeHomeScreen(),
    );
  }
}
