import 'subtitle_data.dart';

class ConversationData {
  final String title;
  final DateTime createdAt;
  final List<SubtitleData> subtitles;
  final List<String> speakers;

  ConversationData({
    required this.title,
    required this.createdAt,
    required this.subtitles,
    required this.speakers,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'subtitles': subtitles.map((s) => s.toJson()).toList(),
      'speakers': speakers,
    };
  }

  factory ConversationData.fromJson(Map<String, dynamic> json) {
    return ConversationData(
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      subtitles: (json['subtitles'] as List)
          .map((s) => SubtitleData.fromJson(s))
          .toList(),
      speakers: List<String>.from(json['speakers']),
    );
  }
}
