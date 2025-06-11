import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // flutter_dotenv 패키지 임포트
import 'package:http/http.dart' as http;
import '../models/subtitle_data.dart'; // SubtitleData 모델 경로에 맞게 확인

// 요약 유형 정의
enum SummaryType {
  brief, // 간단 요약
  detailed, // 상세 요약
  keyPoints, // 핵심 포인트
  emotional, // 감정 중심 요약
  action // 액션 아이템 중심
}

// 자막 요약 서비스
class SummaryService {
  // === 핵심 변경 부분 시작 ===
  // .env 파일에서 'OPENAI_API_KEY'라는 이름의 키를 가져옵니다.
  // 이 키 이름은 .env 파일 (예: 프로젝트 루트의 .env)에 정의된 이름과 정확히 일치해야 합니다.
  // 예: .env 파일 내용 -> OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  static final String _openaiApiKey = dotenv.env['OPENAI_API_KEY']!;
  // === 핵심 변경 부분 끝 ===

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

      // 3. OpenAI API 호출
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
      // API 호출 실패 시 오프라인 요약 기능으로 fallback
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

      // 감정 정보 포함 (감정 필터링)
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
          'Authorization': 'Bearer $_openaiApiKey', // .env에서 로드한 키 사용
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo', // 사용하는 모델에 따라 변경 가능
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
        // API 오류 발생 시 상세한 에러 메시지 출력 (디버깅용)
        print('OpenAI API 호출 실패: ${response.statusCode}, ${response.body}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      // API 오류 발생 시 오프라인 요약으로 fallback
      print('OpenAI API 호출 오류: $e'); // 디버깅용
      return _generateOfflinePromptSummary(prompt);
    }
  }

  // 오프라인 프롬프트 기반 요약
  static String _generateOfflinePromptSummary(String prompt) {
    // 프롬프트 내용에 따라 간단한 오프라인 요약을 생성
    if (prompt.contains('간단히 요약해주세요')) {
      return '이것은 간단한 대화 요약입니다. 주요 내용을 간략하게 정리했습니다.';
    } else if (prompt.contains('상세히 요약해주세요')) {
      return '이것은 상세한 대화 요약입니다.\n\n1. 주요 논의 사항\n2. 참여자별 의견\n3. 결론 및 합의사항';
    } else if (prompt.contains('핵심 포인트들을 정리해주세요')) {
      return '• 핵심 포인트 1\n• 핵심 포인트 2\n• 핵심 포인트 3';
    } else if (prompt.contains('감정적 측면을 중심으로 요약해주세요')) {
      return '대화의 전반적인 분위기는 긍정적이었으며, 참여자들 간의 원활한 소통이 이루어졌습니다.';
    } else if (prompt.contains('액션 아이템들을 정리해주세요')) {
      return '대화에서 구체적인 행동 계획과 후속 조치가 논의되었습니다.';
    } else {
      return '요약 유형에 대한 오프라인 요약입니다. 네트워크 연결을 확인해주세요.';
    }
  }

  // 추가 분석 수행 (예시 로직, 실제 구현은 더 복잡할 수 있음)
  static Future<Map<String, dynamic>> _performAdditionalAnalysis(
      List<SubtitleData> subtitles) async {
    return {
      'keyTopics': _extractKeyTopics(subtitles),
      'participantAnalysis': _analyzeParticipants(subtitles),
      'emotionAnalysis': _analyzeEmotions(subtitles),
      'actionItems': _extractActionItems(subtitles),
    };
  }

  // 핵심 주제 추출 (간단한 키워드 빈도 분석)
  static List<String> _extractKeyTopics(List<SubtitleData> subtitles) {
    Map<String, int> topicCount = {};
    List<String> commonTopics = [];

    for (SubtitleData subtitle in subtitles) {
      List<String> words = subtitle.text.split(' ');
      for (String word in words) {
        // 2글자 이상 단어만 카운트 (불용어 필터링 필요)
        if (word.length > 2) {
          topicCount[word] = (topicCount[word] ?? 0) + 1;
        }
      }
    }

    // 빈도수 기준 상위 주제 선택
    var sortedTopics = topicCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 상위 5개 주제 중 빈도수가 2보다 큰 것만 추가
    for (int i = 0; i < 5 && i < sortedTopics.length; i++) {
      if (sortedTopics[i].value > 2) {
        commonTopics.add(sortedTopics[i].key);
      }
    }

    return commonTopics;
  }

  // 참여자별 발언 통계 및 감정 분석
  static Map<String, Map<String, dynamic>> _analyzeParticipants(
      List<SubtitleData> subtitles) {
    Map<String, Map<String, dynamic>> analysis = {};

    for (SubtitleData subtitle in subtitles) {
      if (!analysis.containsKey(subtitle.speaker)) {
        analysis[subtitle.speaker] = {
          'totalMessages': 0, // 총 발언 수
          'totalWords': 0, // 총 단어 수
          'emotions': <String, int>{}, // 감정별 빈도
          'averageMessageLength': 0.0, // 평균 메시지 길이
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
      if (data['totalMessages'] > 0) {
        data['averageMessageLength'] =
            data['totalWords'] / data['totalMessages'];
      }
    });

    return analysis;
  }

  // 전체 감정 분석
  static Map<String, dynamic> _analyzeEmotions(List<SubtitleData> subtitles) {
    Map<String, int> emotionCount = {}; // 감정별 총 빈도
    Map<String, List<String>> emotionMoments = {}; // 감정 발생 시점 및 내용

    for (SubtitleData subtitle in subtitles) {
      String emotion = subtitle.emotion;
      emotionCount[emotion] = (emotionCount[emotion] ?? 0) + 1;

      if (!emotionMoments.containsKey(emotion)) {
        emotionMoments[emotion] = [];
      }
      emotionMoments[emotion]!.add('${subtitle.time}: ${subtitle.text}');
    }

    // 전체적인 대화 분위기 계산
    String overallMood = _calculateOverallMood(emotionCount);

    return {
      'emotionDistribution': emotionCount,
      'emotionMoments': emotionMoments,
      'overallMood': overallMood,
      'emotionChanges': _trackEmotionChanges(subtitles), // 감정 변화 추적
    };
  }

  // 전체적인 감정 분위기 추정
  static String _calculateOverallMood(Map<String, int> emotionCount) {
    if (emotionCount.isEmpty) return '중립적';

    // 긍정, 부정, 중립 감정 분류 (당신이 정의한 감정 레이블에 따라 조정)
    int positive = (emotionCount['기쁨'] ?? 0) +
        (emotionCount['기대'] ?? 0) +
        (emotionCount['긍정'] ?? 0);
    int negative = (emotionCount['짜증'] ?? 0) +
        (emotionCount['슬픔'] ?? 0) +
        (emotionCount['화남'] ?? 0);
    int neutral = emotionCount['차분'] ?? 0;

    if (positive > negative && positive > neutral) {
      return '긍정적';
    } else if (negative > positive && negative > neutral) {
      return '부정적';
    } else {
      return '차분함'; // 차분하거나 긍정/부정 비율이 비슷할 때
    }
  }

  // 감정 변화 추적
  static List<Map<String, dynamic>> _trackEmotionChanges(
      List<SubtitleData> subtitles) {
    List<Map<String, dynamic>> changes = [];
    String previousEmotion = '';

    for (int i = 0; i < subtitles.length; i++) {
      String currentEmotion = subtitles[i].emotion;

      // 이전 감정과 현재 감정이 다르고, 이전 감정이 비어있지 않을 때 (첫 발화 제외)
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

  // 액션 아이템 추출 (키워드 기반)
  static List<String> _extractActionItems(List<SubtitleData> subtitles) {
    List<String> actionItems = [];

    // 액션 관련 키워드 패턴 (필요에 따라 더 추가하거나 정교화)
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
      '계획',
      '제출',
      '완료',
      '시작',
      '마무리',
      '보고',
      '알아볼',
      '찾아볼'
    ];

    for (SubtitleData subtitle in subtitles) {
      // 대소문자 구분 없이 검색하고, 한 번 찾으면 다음 자막으로 이동
      String lowerText = subtitle.text.toLowerCase();
      for (String keyword in actionKeywords) {
        if (lowerText.contains(keyword)) {
          actionItems.add('${subtitle.speaker}: ${subtitle.text}');
          break; // 해당 자막에서 키워드를 찾았으면 다음 자막으로 넘어감
        }
      }
    }
    return actionItems;
  }

  // 대화 지속 시간 계산 (간단한 추정)
  static Duration _calculateDuration(List<SubtitleData> subtitles) {
    if (subtitles.isEmpty) return Duration.zero;

    // 실제로는 SubtitleData에 타임스탬프가 있다면 그것을 기반으로 정확히 계산해야 합니다.
    // 여기서는 자막 개수 기반으로 분 단위로 간단히 추정합니다.
    // 예를 들어, 각 자막이 대략 1분 간격이라고 가정
    return Duration(minutes: subtitles.length);
  }

  // 오프라인 요약 기능 (API 호출 실패 시 사용될 fallback)
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
          .reduce((a, b) => a + b), // 모든 자막의 단어 수 합계
      duration: _calculateDuration(subtitles),
    );
  }

  // 오프라인 간단 요약 생성 (다양한 요약 타입에 대응)
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
        // 처음 3개 자막만 예시로 포함
        for (int i = 0; i < 3 && i < subtitles.length; i++) {
          summary.writeln('- ${subtitles[i].speaker}: ${subtitles[i].text}');
        }
        // 더 많은 자막을 포함하고 싶다면 for 루프 조건 변경
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
            summary.writeln('• ${actions[i]}'); // 최대 5개 액션 아이템
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

  // JSON 직렬화 (저장 등에 활용)
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

  // JSON 역직렬화 (불러오기 등에 활용)
  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      originalSubtitles: (json['originalSubtitles'] as List)
          .map((s) => SubtitleData.fromJson(s))
          .toList(),
      summary: json['summary'],
      summaryType: SummaryType.values.firstWhere(
        (e) => e.toString() == json['summaryType'],
        orElse: () => SummaryType.brief, // 기본값 설정
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
