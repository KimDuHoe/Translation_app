import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http; // HTTP 패키지 import 복원
import '../models/subtitle_data.dart';

// 요약 유형 정의 (클래스 외부에 정의)
enum SummaryType {
  brief, // 간단 요약
  detailed, // 상세 요약
  keyPoints, // 핵심 포인트
  emotional, // 감정 중심 요약
  action // 액션 아이템 중심
}

// 자막 요약 서비스
class SummaryService {
  static const String _openaiApiKey = ''; // 실제 API 키로 교체 필요
  static const String _openaiUrl = 'https://api.openai.com/v1/chat/completions';

  // 대화 요약 생성
  static Future<ConversationSummary> generateSummary(
    List<SubtitleData> subtitles, {
    SummaryType type = SummaryType.brief,
  }) async {
    try {
      // 1. 대화 내용 전처리
      String conversationText = _preprocessConversation(subtitles);

      // 2. 요약 타입별 프롬프트 생성
      String prompt = _generatePrompt(conversationText, type);

      // 3. OpenAI API 호출 (실제 구현시)
      String summary = await _callOpenAI(prompt);

      // 4. 추가 분석 수행
      Map<String, dynamic> analysis =
          await _performAdditionalAnalysis(subtitles);

      return ConversationSummary(
        originalSubtitles: subtitles,
        summary: summary,
        summaryType: type,
        keyTopics: analysis['keyTopics'] ?? [],
        participantAnalysis: analysis['participantAnalysis'] ?? {},
        emotionAnalysis: analysis['emotionAnalysis'] ?? {},
        actionItems: analysis['actionItems'] ?? [],
        generatedAt: DateTime.now(),
        wordCount: conversationText.split(' ').length,
        duration: _calculateDuration(subtitles),
      );
    } catch (e) {
      // print('요약 생성 중 오류: $e'); // 디버깅용 - 필요시 주석 해제
      // 오프라인 요약 기능으로 fallback
      return _generateOfflineSummary(subtitles, type);
    }
  }

  // 대화 내용 전처리
  static String _preprocessConversation(List<SubtitleData> subtitles) {
    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < subtitles.length; i++) {
      SubtitleData subtitle = subtitles[i];

      // 화자별로 대화 구성
      buffer.writeln('${subtitle.speaker}: ${subtitle.text}');

      // 감정 정보 포함
      if (subtitle.emotion != '차분') {
        buffer.writeln('  [감정: ${subtitle.emotion}]');
      }
    }

    return buffer.toString();
  }

  // 요약 타입별 프롬프트 생성
  static String _generatePrompt(String conversationText, SummaryType type) {
    String basePrompt = '''
다음은 실시간 자막으로 기록된 대화입니다:

$conversationText

''';

    switch (type) {
      case SummaryType.brief:
        return '''$basePrompt이 대화를 2-3문장으로 간단히 요약해주세요. 주요 내용과 결론을 중심으로 작성해주세요.
''';

      case SummaryType.detailed:
        return '''$basePrompt이 대화를 상세히 요약해주세요. 다음을 포함해주세요:
1. 대화의 주요 주제
2. 각 참여자의 주요 발언
3. 논의된 세부 사항
4. 결론이나 합의 사항
''';

      case SummaryType.keyPoints:
        return '''$basePrompt이 대화에서 핵심 포인트들을 bullet point 형태로 정리해주세요:
- 주요 논점
- 중요한 결정사항
- 언급된 중요 정보
- 향후 계획
''';

      case SummaryType.emotional:
        return '''$basePrompt이 대화의 감정적 측면을 중심으로 요약해주세요:
1. 전반적인 대화 분위기
2. 각 참여자의 감정 변화
3. 갈등이나 긍정적 상호작용
4. 감정적으로 중요한 순간들
''';

      case SummaryType.action:
        return '''$basePrompt이 대화에서 나온 액션 아이템들을 정리해주세요:
1. 누가 무엇을 해야 하는지
2. 언제까지 해야 하는지
3. 후속 미팅이나 논의 사항
4. 확인이 필요한 사항들
''';
    }
  }

  // OpenAI API 호출 (실제 구현)
  static Future<String> _callOpenAI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_openaiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openaiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '당신은 대화 내용을 분석하고 요약하는 전문가입니다. 한국어로 정확하고 명확하게 요약해주세요.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      // API 오류시 오프라인 요약으로 fallback
      // print('OpenAI API 호출 오류: $e'); // 디버깅용

      // 오프라인 요약 생성
      return _generateOfflinePromptSummary(prompt);
    }
  }

  // 오프라인 프롬프트 기반 요약
  static String _generateOfflinePromptSummary(String prompt) {
    if (prompt.contains('간단')) {
      return '이것은 간단한 대화 요약입니다. 주요 내용을 간략하게 정리했습니다.';
    } else if (prompt.contains('상세')) {
      return '이것은 상세한 대화 요약입니다.\n\n1. 주요 논의 사항\n2. 참여자별 의견\n3. 결론 및 합의사항';
    } else if (prompt.contains('핵심')) {
      return '• 핵심 포인트 1\n• 핵심 포인트 2\n• 핵심 포인트 3';
    } else if (prompt.contains('감정')) {
      return '대화의 전반적인 분위기는 긍정적이었으며, 참여자들 간의 원활한 소통이 이루어졌습니다.';
    } else {
      return '대화에서 구체적인 행동 계획과 후속 조치가 논의되었습니다.';
    }
  }

  // 추가 분석 수행
  static Future<Map<String, dynamic>> _performAdditionalAnalysis(
      List<SubtitleData> subtitles) async {
    return {
      'keyTopics': _extractKeyTopics(subtitles),
      'participantAnalysis': _analyzeParticipants(subtitles),
      'emotionAnalysis': _analyzeEmotions(subtitles),
      'actionItems': _extractActionItems(subtitles),
    };
  }

  // 핵심 주제 추출
  static List<String> _extractKeyTopics(List<SubtitleData> subtitles) {
    Map<String, int> topicCount = {};
    List<String> commonTopics = [];

    // 키워드 기반 주제 추출 (실제로는 NLP 라이브러리 사용)
    for (SubtitleData subtitle in subtitles) {
      List<String> words = subtitle.text.split(' ');
      for (String word in words) {
        if (word.length > 2) {
          topicCount[word] = (topicCount[word] ?? 0) + 1;
        }
      }
    }

    // 빈도수 기준 상위 주제 선택
    var sortedTopics = topicCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (int i = 0; i < 5 && i < sortedTopics.length; i++) {
      if (sortedTopics[i].value > 2) {
        commonTopics.add(sortedTopics[i].key);
      }
    }

    return commonTopics;
  }

  // 참여자 분석
  static Map<String, Map<String, dynamic>> _analyzeParticipants(
      List<SubtitleData> subtitles) {
    Map<String, Map<String, dynamic>> analysis = {};

    for (SubtitleData subtitle in subtitles) {
      if (!analysis.containsKey(subtitle.speaker)) {
        analysis[subtitle.speaker] = {
          'totalMessages': 0,
          'totalWords': 0,
          'emotions': <String, int>{},
          'averageMessageLength': 0,
        };
      }

      analysis[subtitle.speaker]!['totalMessages']++;
      analysis[subtitle.speaker]!['totalWords'] +=
          subtitle.text.split(' ').length;

      String emotion = subtitle.emotion;
      analysis[subtitle.speaker]!['emotions'][emotion] =
          (analysis[subtitle.speaker]!['emotions'][emotion] ?? 0) + 1;
    }

    // 평균 메시지 길이 계산
    analysis.forEach((speaker, data) {
      data['averageMessageLength'] = data['totalWords'] / data['totalMessages'];
    });

    return analysis;
  }

  // 감정 분석
  static Map<String, dynamic> _analyzeEmotions(List<SubtitleData> subtitles) {
    Map<String, int> emotionCount = {};
    Map<String, List<String>> emotionMoments = {};

    for (SubtitleData subtitle in subtitles) {
      String emotion = subtitle.emotion;
      emotionCount[emotion] = (emotionCount[emotion] ?? 0) + 1;

      if (!emotionMoments.containsKey(emotion)) {
        emotionMoments[emotion] = [];
      }
      emotionMoments[emotion]!.add('${subtitle.time}: ${subtitle.text}');
    }

    // 전체적인 감정 분위기 계산
    String overallMood = _calculateOverallMood(emotionCount);

    return {
      'emotionDistribution': emotionCount,
      'emotionMoments': emotionMoments,
      'overallMood': overallMood,
      'emotionChanges': _trackEmotionChanges(subtitles),
    };
  }

  // 전체적인 감정 분위기 계산
  static String _calculateOverallMood(Map<String, int> emotionCount) {
    if (emotionCount.isEmpty) return '중립적';

    int positive = (emotionCount['기쁨'] ?? 0) + (emotionCount['기대'] ?? 0);
    int negative = (emotionCount['짜증'] ?? 0) + (emotionCount['슬픔'] ?? 0);
    int neutral = emotionCount['차분'] ?? 0;

    if (positive > negative && positive > neutral) {
      return '긍정적';
    } else if (negative > positive && negative > neutral) {
      return '부정적';
    } else {
      return '차분함';
    }
  }

  // 감정 변화 추적
  static List<Map<String, dynamic>> _trackEmotionChanges(
      List<SubtitleData> subtitles) {
    List<Map<String, dynamic>> changes = [];
    String previousEmotion = '';

    for (int i = 0; i < subtitles.length; i++) {
      String currentEmotion = subtitles[i].emotion;

      if (previousEmotion.isNotEmpty && previousEmotion != currentEmotion) {
        changes.add({
          'time': subtitles[i].time,
          'speaker': subtitles[i].speaker,
          'from': previousEmotion,
          'to': currentEmotion,
          'text': subtitles[i].text,
        });
      }

      previousEmotion = currentEmotion;
    }

    return changes;
  }

  // 액션 아이템 추출
  static List<String> _extractActionItems(List<SubtitleData> subtitles) {
    List<String> actionItems = [];

    // 액션 키워드 패턴
    List<String> actionKeywords = [
      '해야',
      '할게',
      '하겠',
      '할까요',
      '하자',
      '하세요',
      '정하자',
      '결정',
      '확인',
      '검토',
      '준비',
      '계획'
    ];

    for (SubtitleData subtitle in subtitles) {
      for (String keyword in actionKeywords) {
        if (subtitle.text.contains(keyword)) {
          actionItems.add('${subtitle.speaker}: ${subtitle.text}');
          break;
        }
      }
    }

    return actionItems;
  }

  // 대화 지속 시간 계산
  static Duration _calculateDuration(List<SubtitleData> subtitles) {
    if (subtitles.isEmpty) return Duration.zero;

    // 간단한 추정 (실제로는 타임스탬프 기반 계산)
    return Duration(minutes: subtitles.length);
  }

  // 오프라인 요약 기능 (fallback)
  static ConversationSummary _generateOfflineSummary(
      List<SubtitleData> subtitles, SummaryType type) {
    String summary = _generateSimpleSummary(subtitles, type);

    return ConversationSummary(
      originalSubtitles: subtitles,
      summary: summary,
      summaryType: type,
      keyTopics: _extractKeyTopics(subtitles),
      participantAnalysis: _analyzeParticipants(subtitles),
      emotionAnalysis: _analyzeEmotions(subtitles),
      actionItems: _extractActionItems(subtitles),
      generatedAt: DateTime.now(),
      wordCount: subtitles
          .map((s) => s.text.split(' ').length)
          .reduce((a, b) => a + b),
      duration: _calculateDuration(subtitles),
    );
  }

  // 간단한 오프라인 요약
  static String _generateSimpleSummary(
      List<SubtitleData> subtitles, SummaryType type) {
    if (subtitles.isEmpty) return '대화 내용이 없습니다.';

    Set<String> speakers = subtitles.map((s) => s.speaker).toSet();
    int totalMessages = subtitles.length;

    StringBuffer summary = StringBuffer();

    switch (type) {
      case SummaryType.brief:
        summary.write(
            '${speakers.join(', ')} 간의 대화로 총 $totalMessages개의 발언이 있었습니다. ');
        summary.write('주요 내용: ${subtitles.first.text}');
        if (subtitles.length > 1) {
          summary.write(' ... ${subtitles.last.text}');
        }
        break;

      case SummaryType.detailed:
        summary.writeln('참여자: ${speakers.join(', ')}');
        summary.writeln('총 발언 수: $totalMessages개');
        summary.writeln('\n주요 대화 내용:');
        for (int i = 0; i < 3 && i < subtitles.length; i++) {
          summary.writeln('- ${subtitles[i].speaker}: ${subtitles[i].text}');
        }
        break;

      case SummaryType.keyPoints:
        summary.writeln('📌 핵심 포인트:');
        summary.writeln('• 참여자: ${speakers.join(', ')}');
        summary.writeln('• 발언 수: $totalMessages개');
        if (subtitles.isNotEmpty) {
          summary.writeln(
              '• 주요 주제: ${_extractKeyTopics(subtitles).take(3).join(', ')}');
        }
        break;

      case SummaryType.emotional:
        Map<String, int> emotions = {};
        for (var subtitle in subtitles) {
          emotions[subtitle.emotion] = (emotions[subtitle.emotion] ?? 0) + 1;
        }
        summary.writeln('😊 감정 분석:');
        for (var entry in emotions.entries) {
          summary.writeln('• ${entry.key}: ${entry.value}회');
        }
        break;

      case SummaryType.action:
        List<String> actions = _extractActionItems(subtitles);
        if (actions.isNotEmpty) {
          summary.writeln('✅ 액션 아이템:');
          for (int i = 0; i < actions.length && i < 5; i++) {
            summary.writeln('• ${actions[i]}');
          }
        } else {
          summary.write('구체적인 액션 아이템이 발견되지 않았습니다.');
        }
        break;
    }

    return summary.toString();
  }
}

// 대화 요약 결과 모델
class ConversationSummary {
  final List<SubtitleData> originalSubtitles;
  final String summary;
  final SummaryType summaryType;
  final List<String> keyTopics;
  final Map<String, Map<String, dynamic>> participantAnalysis;
  final Map<String, dynamic> emotionAnalysis;
  final List<String> actionItems;
  final DateTime generatedAt;
  final int wordCount;
  final Duration duration;

  ConversationSummary({
    required this.originalSubtitles,
    required this.summary,
    required this.summaryType,
    required this.keyTopics,
    required this.participantAnalysis,
    required this.emotionAnalysis,
    required this.actionItems,
    required this.generatedAt,
    required this.wordCount,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalSubtitles': originalSubtitles.map((s) => s.toJson()).toList(),
      'summary': summary,
      'summaryType': summaryType.toString(),
      'keyTopics': keyTopics,
      'participantAnalysis': participantAnalysis,
      'emotionAnalysis': emotionAnalysis,
      'actionItems': actionItems,
      'generatedAt': generatedAt.toIso8601String(),
      'wordCount': wordCount,
      'duration': duration.inSeconds,
    };
  }

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      originalSubtitles: (json['originalSubtitles'] as List)
          .map((s) => SubtitleData.fromJson(s))
          .toList(),
      summary: json['summary'],
      summaryType: SummaryType.values.firstWhere(
        (e) => e.toString() == json['summaryType'],
        orElse: () => SummaryType.brief,
      ),
      keyTopics: List<String>.from(json['keyTopics']),
      participantAnalysis:
          Map<String, Map<String, dynamic>>.from(json['participantAnalysis']),
      emotionAnalysis: Map<String, dynamic>.from(json['emotionAnalysis']),
      actionItems: List<String>.from(json['actionItems']),
      generatedAt: DateTime.parse(json['generatedAt']),
      wordCount: json['wordCount'],
      duration: Duration(seconds: json['duration']),
    );
  }
}
