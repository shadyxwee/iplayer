import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class StorageService {
  static const String _playlistsKey = 'vortextube_playlists';
  static const String _activePlaylistIdKey = 'vortextube_active_playlist_id';
  static const String _favoriteCategoriesKey = 'vortextube_favorite_categories';
  static const String _channelsKey = 'vortextube_channels';

  static Future<List<PlaylistModel>> getPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_playlistsKey) ?? [];
    if (raw.isEmpty) {
      // Seed default sample playlists
      final defaults = [
        PlaylistModel(
          id: 1,
          name: 'benz44.xyz',
          sourceType: PlaylistSourceType.xtreamCodes,
          url: 'http://benz44.xyz:8080',
          username: 'benz_user_44',
          password: 'password123',
          isActive: false,
        ),
        PlaylistModel(
          id: 2,
          name: 'MAC1',
          sourceType: PlaylistSourceType.stalker,
          url: 'http://stalker.portal.net:8080/c/',
          macAddress: '00:1A:79:B4:42:19',
          isActive: true,
        ),
      ];
      await savePlaylists(defaults);
      await setActivePlaylistId(2);
      return defaults;
    }
    return raw.map((s) => PlaylistModel.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  static Future<void> savePlaylists(List<PlaylistModel> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = playlists.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_playlistsKey, raw);
  }

  static Future<int?> getActivePlaylistId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activePlaylistIdKey);
  }

  static Future<void> setActivePlaylistId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activePlaylistIdKey, id);
    final playlists = await getPlaylists();
    for (final p in playlists) {
      p.isActive = (p.id == id);
    }
    await savePlaylists(playlists);
  }

  static Future<Set<String>> getFavoriteCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favoriteCategoriesKey) ?? [
      'Live Sports 4K',
      'Entertainment & General',
      'Kids & Family',
      'Action & Adventure',
      'Crime Thrillers & Mystery',
      'Drama & Award Winners',
      'Trending & Top Rated TV',
      'Crime & Docuseries',
    ];
    return list.toSet();
  }

  static Future<bool> toggleFavoriteCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final list = (await getFavoriteCategories()).toList();
    bool isNowFav;
    if (list.contains(category)) {
      list.remove(category);
      isNowFav = false;
    } else {
      list.add(category);
      isNowFav = true;
    }
    await prefs.setStringList(_favoriteCategoriesKey, list);
    return isNowFav;
  }

  static Future<List<ChannelModel>> getChannels() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_channelsKey) ?? [];
    if (raw.isEmpty) {
      // Seed rich default channels for TV testing
      final seeded = _createDefaultChannels();
      await saveChannels(seeded);
      return seeded;
    }
    return raw.map((s) => ChannelModel.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  static Future<void> saveChannels(List<ChannelModel> channels) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = channels.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_channelsKey, raw);
  }

  static List<ChannelModel> _createDefaultChannels() {
    return [
      // Live Sports
      ChannelModel(
        id: 'c1',
        name: 'Sky Sports Main Event 4K',
        url: 'http://sample.vod/live/sky_sports.m3u8',
        group: 'Live Sports 4K',
        contentType: ContentType.live,
        isFavorite: true,
        playCount: 15,
        rating: 9.2,
      ),
      ChannelModel(
        id: 'c2',
        name: 'TNT Sports 1 Ultra HD',
        url: 'http://sample.vod/live/tnt_sports.m3u8',
        group: 'Live Sports 4K',
        contentType: ContentType.live,
        isFavorite: true,
        playCount: 8,
        rating: 8.9,
      ),
      ChannelModel(
        id: 'c3',
        name: 'ESPN HD',
        url: 'http://sample.vod/live/espn.m3u8',
        group: 'Live Sports 4K',
        contentType: ContentType.live,
        rating: 8.5,
      ),
      // Entertainment
      ChannelModel(
        id: 'c4',
        name: 'HBO HD USA',
        url: 'http://sample.vod/live/hbo.m3u8',
        group: 'Entertainment & General',
        contentType: ContentType.live,
        isFavorite: true,
        playCount: 22,
        rating: 9.4,
      ),
      ChannelModel(
        id: 'c5',
        name: 'BBC One 1080p',
        url: 'http://sample.vod/live/bbc1.m3u8',
        group: 'Entertainment & General',
        contentType: ContentType.live,
        rating: 8.2,
      ),
      // Kids
      ChannelModel(
        id: 'c6',
        name: 'Cartoon Network UK',
        url: 'http://sample.vod/live/cn.m3u8',
        group: 'Kids & Family',
        contentType: ContentType.live,
        isFavorite: true,
        rating: 8.0,
      ),
      // Movies
      ChannelModel(
        id: 'm1',
        name: 'Dune: Part Two (2024)',
        url: 'http://sample.vod/movies/dune2.mp4',
        group: 'Action & Adventure',
        contentType: ContentType.movie,
        isFavorite: true,
        rating: 8.6,
        watchedMilliseconds: 4200000,
        totalMilliseconds: 9600000,
      ),
      ChannelModel(
        id: 'm2',
        name: 'Oppenheimer (2023)',
        url: 'http://sample.vod/movies/oppenheimer.mp4',
        group: 'Drama & Award Winners',
        contentType: ContentType.movie,
        isFavorite: true,
        rating: 8.9,
      ),
      ChannelModel(
        id: 'm3',
        name: 'The Dark Knight (2008)',
        url: 'http://sample.vod/movies/dark_knight.mp4',
        group: 'Action & Adventure',
        contentType: ContentType.movie,
        rating: 9.0,
      ),
      ChannelModel(
        id: 'm4',
        name: 'Killers of the Flower Moon',
        url: 'http://sample.vod/movies/flower_moon.mp4',
        group: 'Crime Thrillers & Mystery',
        contentType: ContentType.movie,
        rating: 7.8,
      ),
      // Series
      ChannelModel(
        id: 's1',
        name: 'House of the Dragon',
        url: 'stalker://series/hotd',
        group: 'Trending & Top Rated TV',
        contentType: ContentType.series,
        isFavorite: true,
        rating: 8.8,
      ),
      ChannelModel(
        id: 's2',
        name: 'Breaking Bad',
        url: 'stalker://series/bb',
        group: 'Crime & Docuseries',
        contentType: ContentType.series,
        isFavorite: true,
        rating: 9.5,
      ),
      ChannelModel(
        id: 's3',
        name: 'Severance',
        url: 'stalker://series/severance',
        group: 'Trending & Top Rated TV',
        contentType: ContentType.series,
        rating: 8.7,
      ),
    ];
  }
}
