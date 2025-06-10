import 'dart:math';
import 'dart:math' as math;

// 감정 분석을 위한 음성 특징 데이터
class VoiceFeatures {
  final double pitch; // 음성 높이 (Hz)
  final double volume; // 음량 (dB)
  final double speechRate; // 말하기 속도 (단어/분)
  final double energy; // 음성 에너지
  final double confidence; // STT 신뢰도
  final String text; // 인식된 텍스트
  final Duration pauseDuration; // 말 사이의 멈춤

  VoiceFeatures({
    required this.pitch,
    required this.volume,
    required this.speechRate,
    required this.energy,
    required this.confidence,
    required this.text,
    required this.pauseDuration,
  });
}

// 강화된 감정 분석 엔진
class EnhancedEmotionAnalyzer {
  // 감정별 음성 특징 임계값 (실제 데이터 기반으로 조정 필요)
  static const Map<String, Map<String, double>> _emotionThresholds = {
    '기쁨': {
      'pitchMin': 180.0,
      'pitchMax': 300.0,
      'volumeMin': 60.0,
      'energyMin': 0.7,
      'speechRateMin': 150.0,
      'speechRateMax': 200.0,
    },
    '슬픔': {
      'pitchMin': 80.0,
      'pitchMax': 150.0,
      'volumeMin': 40.0,
      'energyMin': 0.3,
      'speechRateMin': 80.0,
      'speechRateMax': 120.0,
    },
    '화남': {
      'pitchMin': 200.0,
      'pitchMax': 400.0,
      'volumeMin': 70.0,
      'energyMin': 0.8,
      'speechRateMin': 180.0,
      'speechRateMax': 250.0,
    },
    '놀람': {
      'pitchMin': 250.0,
      'pitchMax': 450.0,
      'volumeMin': 65.0,
      'energyMin': 0.8,
      'speechRateMin': 120.0,
      'speechRateMax': 180.0,
    },
    '차분': {
      'pitchMin': 120.0,
      'pitchMax': 180.0,
      'volumeMin': 45.0,
      'energyMin': 0.4,
      'speechRateMin': 120.0,
      'speechRateMax': 160.0,
    },
  };

  // 1. 멀티모달 감정 분석 (음성 + 텍스트)
  static String analyzeEmotion(VoiceFeatures features) {
    // 음성 특징 기반 분석
    Map<String, double> voiceScores = _analyzeVoiceFeatures(features);

    // 텍스트 감정 분석
    Map<String, double> textScores = _analyzeTextEmotion(features.text);

    // 컨텍스트 분석 (이전 발화와의 관계)
    Map<String, double> contextScores = _analyzeContext(features);

    // 가중치 적용하여 최종 감정 결정
    Map<String, double> finalScores =
        _combineScores(voiceScores, textScores, contextScores);

    return _getTopEmotion(finalScores);
  }

  // 2. 음성 특징 기반 분석
  static Map<String, double> _analyzeVoiceFeatures(VoiceFeatures features) {
    Map<String, double> scores = {};

    for (String emotion in _emotionThresholds.keys) {
      double score = 0.0;
      Map<String, double> thresholds = _emotionThresholds[emotion]!;

      // 음성 높이 분석
      if (features.pitch >= thresholds['pitchMin']! &&
          features.pitch <= thresholds['pitchMax']!) {
        score += 0.3;
      }

      // 음량 분석
      if (features.volume >= thresholds['volumeMin']!) {
        score += 0.2;
      }

      // 말하기 속도 분석
      if (features.speechRate >= thresholds['speechRateMin']! &&
          features.speechRate <= thresholds['speechRateMax']!) {
        score += 0.2;
      }

      // 에너지 분석
      if (features.energy >= thresholds['energyMin']!) {
        score += 0.2;
      }

      // 신뢰도 가중치
      score *= features.confidence;

      scores[emotion] = score;
    }

    return scores;
  }

  // 3. 고급 텍스트 감정 분석
  static Map<String, double> _analyzeTextEmotion(String text) {
    Map<String, double> scores = {
      '기쁨': 0.0,
      '슬픔': 0.0,
      '화남': 0.0,
      '놀람': 0.0,
      '차분': 0.0
    };

    // 감정별 키워드 사전 (더 확장 가능)
    Map<String, List<String>> emotionKeywords = {
      '기쁨': [
        '좋',
        '기쁨',
        '행복',
        '웃',
        '즐거',
        '신나',
        '최고',
        '완전',
        '대박',
        '축하',
        '감사',
        '사랑',
        '💕',
        '😄',
        '👍'
      ],
      '슬픔': [
        '슬프',
        '아쉬',
        '안타깝',
        '우울',
        '힘들',
        '괴로',
        '아프',
        '눈물',
        '절망',
        '외로',
        '😢',
        '😭'
      ],
      '화남': [
        '화나',
        '짜증',
        '싫',
        '미워',
        '열받',
        '빡쳐',
        '분노',
        '악',
        '!!!',
        '진짜',
        '😡',
        '💢'
      ],
      '놀람': [
        '어?',
        '정말?',
        '와!',
        '헐',
        '대박',
        '세상에',
        '놀라',
        '어떻게',
        '믿을 수 없',
        '😲',
        '😱'
      ],
      '차분': ['그렇', '음', '네', '알겠', '이해', '괜찮', '보통', '그냥', '😐']
    };

    // 감정 강도 분석
    Map<String, double> intensityMultipliers = {
      '매우': 1.5,
      '정말': 1.4,
      '너무': 1.3,
      '완전': 1.3,
      '엄청': 1.2,
      '좀': 0.8,
      '조금': 0.7,
      '약간': 0.6
    };

    text = text.toLowerCase();

    for (String emotion in emotionKeywords.keys) {
      double baseScore = 0.0;
      double intensityBonus = 1.0;

      // 키워드 매칭
      for (String keyword in emotionKeywords[emotion]!) {
        if (text.contains(keyword)) {
          baseScore += 0.2;
        }
      }

      // 강도 부사 분석
      for (String intensifier in intensityMultipliers.keys) {
        if (text.contains(intensifier)) {
          intensityBonus =
              max(intensityBonus, intensityMultipliers[intensifier]!);
        }
      }

      // 부정문 분석
      if (text.contains('안 ') || text.contains('않') || text.contains('못')) {
        if (emotion == '기쁨') {
          baseScore = 0.0; // 부정문이면 기쁨 점수 취소
          scores['슬픔'] = (scores['슬픔']! + 0.3).clamp(0.0, 1.0);
        }
      }

      // 의문문 분석 (놀람 증가)
      if (text.contains('?') || text.contains('까')) {
        if (emotion == '놀람') {
          intensityBonus += 0.3;
        }
      }

      scores[emotion] = (baseScore * intensityBonus).clamp(0.0, 1.0);
    }

    return scores;
  }

  // 4. 컨텍스트 분석 (대화 흐름 고려)
  static Map<String, double> _analyzeContext(VoiceFeatures features) {
    Map<String, double> scores = {
      '기쁨': 0.0,
      '슬픔': 0.0,
      '화남': 0.0,
      '놀람': 0.0,
      '차분': 0.0
    };

    // 말 사이의 멈춤 분석
    if (features.pauseDuration.inMilliseconds > 2000) {
      // 긴 멈춤 = 고민, 슬픔, 또는 놀람
      scores['슬픔'] = (scores['슬픔']! + 0.2).clamp(0.0, 1.0);
      scores['놀람'] = (scores['놀람']! + 0.1).clamp(0.0, 1.0);
    } else if (features.pauseDuration.inMilliseconds < 500) {
      // 짧은 멈춤 = 흥분, 화남
      scores['기쁨'] = (scores['기쁨']! + 0.1).clamp(0.0, 1.0);
      scores['화남'] = (scores['화남']! + 0.1).clamp(0.0, 1.0);
    }

    // 말하기 속도와 감정의 관계
    if (features.speechRate > 200) {
      scores['기쁨'] = (scores['기쁨']! + 0.15).clamp(0.0, 1.0);
      scores['화남'] = (scores['화남']! + 0.1).clamp(0.0, 1.0);
    } else if (features.speechRate < 100) {
      scores['슬픔'] = (scores['슬픔']! + 0.2).clamp(0.0, 1.0);
    }

    return scores;
  }

  // 5. 점수 결합 및 가중치 적용
  static Map<String, double> _combineScores(
    Map<String, double> voiceScores,
    Map<String, double> textScores,
    Map<String, double> contextScores,
  ) {
    Map<String, double> finalScores = {};

    // 가중치 설정 (조정 가능)
    const double voiceWeight = 0.4; // 음성 특징
    const double textWeight = 0.4; // 텍스트 내용
    const double contextWeight = 0.2; // 컨텍스트

    for (String emotion in voiceScores.keys) {
      finalScores[emotion] = (voiceScores[emotion]! * voiceWeight) +
          (textScores[emotion]! * textWeight) +
          (contextScores[emotion]! * contextWeight);
    }

    return finalScores;
  }

  // 6. 최고 점수 감정 선택
  static String _getTopEmotion(Map<String, double> scores) {
    String topEmotion = '차분';
    double maxScore = 0.0;

    for (String emotion in scores.keys) {
      if (scores[emotion]! > maxScore) {
        maxScore = scores[emotion]!;
        topEmotion = emotion;
      }
    }

    // 최소 임계값 검사 (불확실하면 차분으로)
    if (maxScore < 0.3) {
      return '차분';
    }

    return topEmotion;
  }

  // 7. 감정 변화 패턴 분석
  static String analyzeEmotionPattern(List<String> recentEmotions) {
    if (recentEmotions.length < 3) return '안정적';

    // 최근 3개 감정의 변화 패턴
    List<String> last3 = recentEmotions.take(3).toList();

    if (last3.every((e) => e == last3.first)) {
      return '지속적'; // 같은 감정 지속
    } else if (last3.contains('화남') && last3.contains('슬픔')) {
      return '불안정'; // 부정적 감정 혼재
    } else if (last3.where((e) => e == '기쁨').length >= 2) {
      return '긍정적'; // 긍정적 분위기
    } else {
      return '변화적'; // 감정 변화 중
    }
  }

  // 8. 억양 패턴 분석
  static Map<String, dynamic> analyzeIntonationPattern(
      List<double> pitchContour) {
    if (pitchContour.isEmpty) {
      return {'pattern': '평조', 'confidence': 0.0};
    }

    double start = pitchContour.first;
    double end = pitchContour.last;
    double max = pitchContour.reduce(math.max);
    double min = pitchContour.reduce(math.min);
    double range = max - min;

    String pattern;
    double confidence = 0.8;

    if (end > start + 20) {
      pattern = '상승조'; // 의문문, 놀람
    } else if (end < start - 20) {
      pattern = '하강조'; // 평서문, 확신
    } else if (range > 100) {
      pattern = '굴곡조'; // 감정적, 강조
    } else {
      pattern = '평조'; // 차분, 단조로움
    }

    return {
      'pattern': pattern,
      'confidence': confidence,
      'range': range,
      'direction': end - start,
    };
  }
}

// 감정 이력 관리
class EmotionHistory {
  static final List<Map<String, dynamic>> _history = [];
  static const int maxHistorySize = 10;

  static void addEmotion(
      String emotion, double confidence, DateTime timestamp) {
    _history.insert(0, {
      'emotion': emotion,
      'confidence': confidence,
      'timestamp': timestamp,
    });

    if (_history.length > maxHistorySize) {
      _history.removeRange(maxHistorySize, _history.length);
    }
  }

  static List<String> getRecentEmotions(int count) {
    return _history.take(count).map((e) => e['emotion'] as String).toList();
  }

  static double getEmotionStability() {
    if (_history.length < 3) return 1.0;

    List<String> recent = getRecentEmotions(5);
    Set<String> uniqueEmotions = recent.toSet();

    return 1.0 - (uniqueEmotions.length / recent.length);
  }
}
