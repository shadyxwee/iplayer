import 'package:isar/isar.dart';

part 'epg.g.dart';

@collection
class EpgChannel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String channelId; // From XMLTV id
  String? displayName;
  String? icon;

  EpgChannel();

  factory EpgChannel.create({required String channelId, String? displayName, String? icon}) {
    final channel = EpgChannel();
    channel.channelId = channelId;
    channel.displayName = displayName;
    channel.icon = icon;
    return channel;
  }
}

@collection
class EpgProgram {
  Id id = Isar.autoIncrement;

  @Index()
  late String channelId;
  
  late DateTime startTime;
  late DateTime endTime;
  
  late String title;
  String? description;
  String? category;
  String? icon;
  String? rating;
  String? episode;

  EpgProgram();

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  bool get isNowPlaying {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  double get progress {
    if (!isNowPlaying) return 0.0;
    final total = endTime.difference(startTime).inMinutes;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(startTime).inMinutes;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String get formattedStartTime {
    return "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
  }

  String get formattedEndTime {
    return "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
  }

  String get formattedTimeRange {
    return "$formattedStartTime - $formattedEndTime";
  }

  factory EpgProgram.create({
    required String channelId,
    required DateTime startTime,
    required DateTime endTime,
    required String title,
    String? description,
    String? category,
    String? icon,
    String? rating,
    String? episode,
  }) {
    final program = EpgProgram();
    program.channelId = channelId;
    program.startTime = startTime;
    program.endTime = endTime;
    program.title = title;
    program.description = description;
    program.category = category;
    program.icon = icon;
    program.rating = rating;
    program.episode = episode;
    return program;
  }
}
