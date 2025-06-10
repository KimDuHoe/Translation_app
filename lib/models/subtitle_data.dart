class SubtitleData {
  final String speaker;
  final String text;
  final String emotion;
  final String time;

  SubtitleData({
    required this.speaker,
    required this.text,
    required this.emotion,
    required this.time,
  });

  // JSON 변환을 위한 메서드들 (나중에 데이터 저장/불러오기용)
  Map<String, dynamic> toJson() {
    return {
      'speaker': speaker,
      'text': text,
      'emotion': emotion,
      'time': time,
    };
  }

  factory SubtitleData.fromJson(Map<String, dynamic> json) {
    return SubtitleData(
      speaker: json['speaker'],
      text: json['text'],
      emotion: json['emotion'],
      time: json['time'],
    );
  }

  // 객체 복사를 위한 메서드
  SubtitleData copyWith({
    String? speaker,
    String? text,
    String? emotion,
    String? time,
  }) {
    return SubtitleData(
      speaker: speaker ?? this.speaker,
      text: text ?? this.text,
      emotion: emotion ?? this.emotion,
      time: time ?? this.time,
    );
  }

  @override
  String toString() {
    return 'SubtitleData(speaker: $speaker, text: $text, emotion: $emotion, time: $time)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubtitleData &&
        other.speaker == speaker &&
        other.text == text &&
        other.emotion == emotion &&
        other.time == time;
  }

  @override
  int get hashCode {
    return speaker.hashCode ^ text.hashCode ^ emotion.hashCode ^ time.hashCode;
  }
}
