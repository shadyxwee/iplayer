import 'package:flutter/foundation.dart';
import '../services/xtream_service.dart';

class ContentProvider extends ChangeNotifier {
  final XtreamService? xtreamService;

  ContentProvider(this.xtreamService);
  
  // State management for content fetching/caching could go here
}
