import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/channel.dart';
import '../models/playlist.dart';
import '../models/profile.dart';
import '../models/epg.dart';

class DatabaseService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ChannelSchema, PlaylistSchema, ProfileSchema, EpgChannelSchema, EpgProgramSchema],
      directory: dir.path,
    );

    // Create default profile if none exists
    final profileCount = await isar.collection<Profile>().count();
    if (profileCount == 0) {
      final defaultProfile = Profile.create(
        name: 'Default',
        avatarUrl: '0_0', // Default icon and color
      );
      await isar.writeTxn(() => isar.collection<Profile>().put(defaultProfile));
    }
  }

  static Future<List<Playlist>> getAllPlaylists() async {
    return await isar.collection<Playlist>().where().findAll();
  }

  static Future<Playlist?> getPlaylistById(int id) async {
    return await isar.collection<Playlist>().get(id);
  }

  static Future<void> addPlaylist(Playlist playlist) async {
    await isar.writeTxn(() => isar.collection<Playlist>().put(playlist));
  }

  static Future<void> deletePlaylist(int id) async {
    await isar.writeTxn(() async {
      await isar.collection<Channel>().filter().playlistIdEqualTo(id).deleteAll();
      await isar.collection<Playlist>().delete(id);
    });
  }

  static Future<List<Channel>> getAllChannels() async {
    return await isar.collection<Channel>().where().findAll();
  }

  static Future<List<Channel>> getChannelsByPlaylistId(int playlistId) async {
    return await isar.collection<Channel>().filter().playlistIdEqualTo(playlistId).findAll();
  }

  static Future<void> addChannels(List<Channel> channels) async {
    await isar.writeTxn(() => isar.collection<Channel>().putAll(channels));
  }

  static Future<void> toggleFavorite(Channel channel) async {
    channel.isFavorite = !channel.isFavorite;
    await isar.writeTxn(() => isar.collection<Channel>().put(channel));
  }

  static Future<void> updateChannelRating(Channel channel, double rating) async {
    channel.rating = rating;
    await isar.writeTxn(() => isar.collection<Channel>().put(channel));
  }

  static Future<void> updateChannelPlayCount(Channel channel) async {
    channel.playCount++;
    channel.lastPlayed = DateTime.now();
    await isar.writeTxn(() => isar.collection<Channel>().put(channel));
  }

  static Future<List<Channel>> getRecentlyPlayedChannels({int limit = 10}) async {
    return await isar.collection<Channel>()
        .filter()
        .lastPlayedIsNotNull()
        .sortByLastPlayedDesc()
        .limit(limit)
        .findAll();
  }

  static Future<List<Channel>> getFavoriteChannels() async {
    return await isar.collection<Channel>().filter().isFavoriteEqualTo(true).findAll();
  }

  static Future<List<Profile>> getAllProfiles() async {
    return await isar.collection<Profile>().where().findAll();
  }

  static Future<Profile?> getActiveProfile() async {
    return await isar.collection<Profile>().filter().isActiveEqualTo(true).findFirst();
  }

  static Future<void> setActiveProfile(Profile profile) async {
    await isar.writeTxn(() async {
      final allProfiles = await isar.collection<Profile>().where().findAll();
      for (final p in allProfiles) {
        p.isActive = (p.id == profile.id);
      }
      await isar.collection<Profile>().putAll(allProfiles);
    });
  }

  static Future<void> addProfile(Profile profile) async {
    await isar.writeTxn(() => isar.collection<Profile>().put(profile));
  }

  static Future<void> deleteProfile(int id) async {
    await isar.writeTxn(() => isar.collection<Profile>().delete(id));
  }

  static Future<void> clearAllData() async {
    await isar.writeTxn(() => isar.clear());
  }
}
