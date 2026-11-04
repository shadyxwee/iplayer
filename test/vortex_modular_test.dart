import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riptv/models/channel.dart';
import 'package:riptv/models/playlist.dart';
import 'package:riptv/screens/home/vortex_home_view.dart';
import 'package:riptv/screens/live/vortex_live_view.dart';
import 'package:riptv/screens/movies/vortex_movies_view.dart';
import 'package:riptv/screens/series/vortex_series_view.dart';
import 'package:riptv/screens/settings/vortex_settings_view.dart';
import 'package:riptv/screens/sidebar/vortex_nav_types.dart';
import 'package:riptv/screens/search/vortex_search_bar.dart';

void main() {
  group('VortexTube Modular UI Component Tests', () {
    testWidgets('VortexSidebar renders VortexTube brand and navigation items', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: VortexSidebar(
            isSidebarExpanded: true,
            isSidebarHovered: false,
            activeNav: VortexNavTarget.home,
            currentZone: VortexZone.content,
            focusedNavIndex: 1,
            activePlaylist: Playlist()..name = 'Test Playlist',
            navItems: const [
              {'target': VortexNavTarget.search, 'icon': Icons.search_rounded, 'label': 'Search'},
              {'target': VortexNavTarget.home, 'icon': Icons.home_rounded, 'label': 'Home'},
              {'target': VortexNavTarget.movies, 'icon': Icons.movie_outlined, 'label': 'Movies'},
              {'target': VortexNavTarget.liveTv, 'icon': Icons.live_tv_rounded, 'label': 'Live TV'},
              {'target': VortexNavTarget.series, 'icon': Icons.video_collection_outlined, 'label': 'Series'},
              {'target': VortexNavTarget.settings, 'icon': Icons.settings_outlined, 'label': 'Settings'},
            ],
            onMouseEnter: () {},
            onMouseExit: () {},
            onSelectNavTarget: (_) {},
            onSidebarTap: (_, __) {},
          ),
        ),
      ));

      expect(find.text('VortexTube'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('Live TV'), findsOneWidget);
      expect(find.text('Series'), findsOneWidget);
      expect(find.text('Test Playlist'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('VortexSearchBar renders search field and sort controls', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: VortexSearchBar(
            searchController: controller,
            searchFocusNode: focusNode,
            searchQuery: '',
            currentZone: VortexZone.content,
            activeNav: VortexNavTarget.movies,
            sortOption: VortexSortOption.recommended,
            isSidebarExpanded: true,
            onToggleSidebar: () {},
            onSearchChanged: (_) {},
            onSearchSubmitted: (_) {},
            onClearSearch: () {},
            onCycleSort: () {},
          ),
        ),
      ));

      expect(find.text('Search VortexTube...'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('VortexMoviesView renders movie cards with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final channel = Channel()
        ..name = 'Inception'
        ..group = 'Action Movies'
        ..contentType = ContentType.movie
        ..rating = 8.8;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 600,
            child: VortexMoviesView(
              items: [channel],
              favoriteCategories: const {'Action Movies'},
              activeFilter: VortexActiveFilter.all,
              currentZone: VortexZone.content,
              focusedGridIndex: 0,
              mainScrollController: ScrollController(),
              cardKeys: {},
              onItemTap: (_, __) {},
            ),
          ),
        ),
      ));

      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('Action Movies'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('VortexSeriesView renders series cards with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final channel = Channel()
        ..name = 'Breaking Bad'
        ..group = 'Drama Series'
        ..contentType = ContentType.series
        ..rating = 9.5;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 600,
            child: VortexSeriesView(
              items: [channel],
              favoriteCategories: const {'Drama Series'},
              activeFilter: VortexActiveFilter.all,
              currentZone: VortexZone.content,
              focusedGridIndex: 0,
              mainScrollController: ScrollController(),
              cardKeys: {},
              onItemTap: (_, __) {},
            ),
          ),
        ),
      ));

      expect(find.text('Breaking Bad'), findsOneWidget);
      expect(find.text('Drama Series'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('VortexLiveView renders live channel circular items with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final channel = Channel()
        ..name = 'HBO HD'
        ..group = 'Premium TV'
        ..contentType = ContentType.live;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 600,
            child: VortexLiveView(
              items: [channel],
              favoriteCategories: const {'Premium TV'},
              activeFilter: VortexActiveFilter.all,
              currentZone: VortexZone.content,
              focusedGridIndex: 0,
              mainScrollController: ScrollController(),
              cardKeys: {},
              onItemTap: (_, __) {},
            ),
          ),
        ),
      ));

      expect(find.text('HBO HD'), findsOneWidget);
      expect(find.text('Premium TV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('VortexSettingsView renders TV OS categories and panels', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1280,
            height: 720,
            child: VortexSettingsView(
              onBackToSidebar: () {},
              onDataChanged: () {},
            ),
          ),
        ),
      ));

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('CATEGORIES'), findsOneWidget);
      expect(find.text('Add to VortexTube'), findsWidgets);
      expect(find.text('Playlists Manager'), findsOneWidget);
      expect(find.text('EPG & TV Guide'), findsOneWidget);
      expect(find.text('About VortexTube'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
