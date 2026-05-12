import 'package:isar/isar.dart';

part 'profile.g.dart';

@collection
class Profile {
  Id id = Isar.autoIncrement;

  late String name;
  String? avatarUrl; // format: "iconIndex_colorIndex"
  bool isActive = false;
  bool showAdultContent = false;
  String videoQuality = 'Automatic';
  DateTime createdAt = DateTime.now();

  Profile();

  factory Profile.create({required String name, String? avatarUrl}) {
    final profile = Profile();
    profile.name = name;
    profile.avatarUrl = avatarUrl;
    profile.createdAt = DateTime.now();
    return profile;
  }
}
