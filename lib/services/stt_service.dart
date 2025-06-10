import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/subtitle_data.dart';

// STT 서비스 구현 (강화된 감정 분석 포함)
class STTService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  String _currentText = '';
  String _lastRecognizedText = '';
  double _confidence = 0.0;
  String _currentSpeaker = '화자1';
  int _speakerCount = 1;

  // 강화된 음성 분석 관련 변수들
  double _currentPitch = 150.0;
  double _currentVolume = 50.0;
  double _currentSpeechRate = 140.0;
  double _currentEnergy = 0.5;
  DateTime? _lastSpeechTime;
  Duration _pauseDuration = Duration.zero;

  // 감정 분석 히스토리
  final List<String> _emotionHistory = [];
  String _currentEmotion = '차분';
  double _emotionConfidence = 0.0;
  String _emotionPattern = '안정적';

  final List<SubtitleData> _subtitles = [];
  final StreamController<SubtitleData> _subtitleController =
      StreamController<SubtitleData>.broadcast();

  // 고급 기능 설정
  bool _advancedEmotionAnalysis = true;
  double _emotionSensitivity = 1.0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isNotListening => !_isListening;
  String get currentText => _currentText;
  String get lastRecognizedText => _lastRecognizedText;
  double get confidence => _confidence;
  List<SubtitleData> get subtitles => List.unmodifiable(_subtitles);
  Stream<SubtitleData> get subtitleStream => _subtitleController.stream;
  String get currentSpeaker => _currentSpeaker;
  String get currentEmotion => _currentEmotion;
  double get emotionConfidence => _emotionConfidence;
  String get emotionPattern => _emotionPattern;

  // 음성 특징 Getters
  double get currentPitch => _currentPitch;
  double get currentVolume => _currentVolume;
  double get currentSpeechRate => _currentSpeechRate;
  double get currentEnergy => _currentEnergy;

  // 고급 기능 Getters
  bool get advancedEmotionAnalysis => _advancedEmotionAnalysis;
  double get emotionSensitivity => _emotionSensitivity;

  // STT 초기화
  Future<bool> initialize() async {
    try {
      bool hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        if (kDebugMode) print('마이크 권한이 거부되었습니다.');
        return false;
      }

      _isInitialized = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: kDebugMode,
      );

      if (_isInitialized) {
        if (kDebugMode) print('STT 초기화 성공');
      } else {
        if (kDebugMode) print('STT 초기화 실패');
      }

      notifyListeners();
      return _isInitialized;
    } catch (e) {
      if (kDebugMode) print('STT 초기화 중 오류: $e');
      return false;
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  // 음성 인식 시작
  Future<void> startListening() async {
    if (!_isInitialized) {
      if (kDebugMode) print('STT가 초기화되지 않았습니다.');
      return;
    }

    if (_isListening) {
      if (kDebugMode) print('이미 음성 인식 중입니다.');
      return;
    }

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'ko_KR',
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );

      _isListening = true;
      _currentText = '';
      _lastSpeechTime = DateTime.now();
      notifyListeners();
      if (kDebugMode) print('음성 인식 시작');
    } catch (e) {
      if (kDebugMode) print('음성 인식 시작 중 오류: $e');
    }
  }

  // 음성 인식 중지
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;

      if (_currentText.isNotEmpty) {
        _addSubtitle(_currentText, isPartial: false);
      }

      notifyListeners();
      if (kDebugMode) print('음성 인식 중지');
    } catch (e) {
      if (kDebugMode) print('음성 인식 중지 중 오류: $e');
    }
  }

  // 음성 인식 취소
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.cancel();
      _isListening = false;
      _currentText = '';
      notifyListeners();
      if (kDebugMode) print('음성 인식 취소');
    } catch (e) {
      if (kDebugMode) print('음성 인식 취소 중 오류: $e');
    }
  }

  // 음성 인식 결과 처리
  void _onSpeechResult(SpeechRecognitionResult result) {
    _currentText = result.recognizedWords;
    _confidence = result.confidence;

    // 음성 특징 추출 및 업데이트
    _updateVoiceFeatures(result);

    if (kDebugMode) {
      print(
          '인식된 텍스트: $_currentText (확신도: ${(_confidence * 100).toStringAsFixed(1)}%)');
    }

    if (result.finalResult) {
      _lastRecognizedText = _currentText;
      _addSubtitle(_currentText, isPartial: false);
      _detectSpeakerChange();
    } else {
      notifyListeners();
    }
  }

  // 음성 특징 추출 및 업데이트
  void _updateVoiceFeatures(SpeechRecognitionResult result) {
    double textLength = _currentText.length.toDouble();
    double confidenceBoost = _confidence;

    // 피치 추정 (텍스트 특성 기반)
    if (_currentText.contains('?') ||
        _currentText.contains('어?') ||
        _currentText.contains('정말?')) {
      _currentPitch = 200 + (confidenceBoost * 100);
    } else if (_currentText.contains('!') ||
        _currentText.contains('와') ||
        _currentText.contains('대박')) {
      _currentPitch = 250 + (confidenceBoost * 150);
    } else {
      _currentPitch = 120 + (confidenceBoost * 60);
    }

    // 볼륨 추정
    if (_currentText.contains('!') ||
        _currentText.toUpperCase() == _currentText) {
      _currentVolume = 70 + (confidenceBoost * 20);
    } else {
      _currentVolume = 45 + (confidenceBoost * 15);
    }

    // 말하기 속도 추정
    DateTime now = DateTime.now();
    if (_lastSpeechTime != null) {
      Duration elapsed = now.difference(_lastSpeechTime!);
      if (elapsed.inMilliseconds > 0) {
        _currentSpeechRate = (textLength / elapsed.inSeconds) * 60;
        _pauseDuration = elapsed;
      }
    }

    _currentEnergy = _confidence * (1.0 + (textLength / 100));
    _lastSpeechTime = now;
  }

  // 강화된 감정 분석
  String _analyzeEmotion(String text) {
    if (!_advancedEmotionAnalysis) {
      return _analyzeEmotionSimple(text);
    }

    // 멀티모달 감정 분석
    Map<String, double> voiceScores = _analyzeVoiceFeatures();
    Map<String, double> textScores = _analyzeTextEmotion(text);
    Map<String, double> contextScores = _analyzeContext();

    // 가중치 적용하여 최종 감정 결정
    Map<String, double> finalScores =
        _combineScores(voiceScores, textScores, contextScores);

    String detectedEmotion = _getTopEmotion(finalScores);

    // 감정 히스토리 업데이트
    _emotionHistory.insert(0, detectedEmotion);
    if (_emotionHistory.length > 10) {
      _emotionHistory.removeRange(10, _emotionHistory.length);
    }

    // 감정 패턴 분석
    _emotionPattern = _analyzeEmotionPattern();
    _emotionConfidence = _calculateEmotionConfidence(detectedEmotion);

    return detectedEmotion;
  }

  // 음성 특징 기반 감정 분석
  Map<String, double> _analyzeVoiceFeatures() {
    Map<String, double> scores = {
      '기쁨': 0.0,
      '슬픔': 0.0,
      '화남': 0.0,
      '놀람': 0.0,
      '차분': 0.0
    };

    // 피치 기반 분석
    if (_currentPitch > 200) {
      scores['기쁨'] = (scores['기쁨']! + 0.3).clamp(0.0, 1.0);
      scores['놀람'] = (scores['놀람']! + 0.2).clamp(0.0, 1.0);
    } else if (_currentPitch < 120) {
      scores['슬픔'] = (scores['슬픔']! + 0.3).clamp(0.0, 1.0);
    }

    // 볼륨 기반 분석
    if (_currentVolume > 70) {
      scores['화남'] = (scores['화남']! + 0.2).clamp(0.0, 1.0);
      scores['기쁨'] = (scores['기쁨']! + 0.1).clamp(0.0, 1.0);
    } else if (_currentVolume < 45) {
      scores['슬픔'] = (scores['슬픔']! + 0.2).clamp(0.0, 1.0);
    }

    // 말하기 속도 기반 분석
    if (_currentSpeechRate > 180) {
      scores['기쁨'] = (scores['기쁨']! + 0.2).clamp(0.0, 1.0);
      scores['화남'] = (scores['화남']! + 0.1).clamp(0.0, 1.0);
    } else if (_currentSpeechRate < 100) {
      scores['슬픔'] = (scores['슬픔']! + 0.2).clamp(0.0, 1.0);
    }

    // 에너지 기반 분석
    if (_currentEnergy > 0.7) {
      scores['기쁨'] = (scores['기쁨']! + 0.1).clamp(0.0, 1.0);
      scores['화남'] = (scores['화남']! + 0.1).clamp(0.0, 1.0);
    }

    // 신뢰도 가중치 적용
    scores.updateAll((key, value) => value * _confidence * _emotionSensitivity);

    return scores;
  }

  // 텍스트 기반 감정 분석
  Map<String, double> _analyzeTextEmotion(String text) {
    Map<String, double> scores = {
      '기쁨': 0.0,
      '슬픔': 0.0,
      '화남': 0.0,
      '놀람': 0.0,
      '차분': 0.0
    };

    // 감정별 키워드 사전
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

    // 강도 부사
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
          baseScore = 0.0;
          scores['슬픔'] = (scores['슬픔']! + 0.3).clamp(0.0, 1.0);
        }
      }

      // 의문문 분석
      if (text.contains('?') || text.contains('까')) {
        if (emotion == '놀람') {
          intensityBonus += 0.3;
        }
      }

      scores[emotion] =
          (baseScore * intensityBonus * _emotionSensitivity).clamp(0.0, 1.0);
    }

    return scores;
  }

  // 컨텍스트 분석
  Map<String, double> _analyzeContext() {
    Map<String, double> scores = {
      '기쁨': 0.0,
      '슬픔': 0.0,
      '화남': 0.0,
      '놀람': 0.0,
      '차분': 0.0
    };

    // 말 사이의 멈춤 분석
    if (_pauseDuration.inMilliseconds > 2000) {
      scores['슬픔'] = (scores['슬픔']! + 0.2).clamp(0.0, 1.0);
      scores['놀람'] = (scores['놀람']! + 0.1).clamp(0.0, 1.0);
    } else if (_pauseDuration.inMilliseconds < 500) {
      scores['기쁨'] = (scores['기쁨']! + 0.1).clamp(0.0, 1.0);
      scores['화남'] = (scores['화남']! + 0.1).clamp(0.0, 1.0);
    }

    return scores;
  }

  // 점수 결합
  Map<String, double> _combineScores(
    Map<String, double> voiceScores,
    Map<String, double> textScores,
    Map<String, double> contextScores,
  ) {
    Map<String, double> finalScores = {};

    const double voiceWeight = 0.4;
    const double textWeight = 0.4;
    const double contextWeight = 0.2;

    for (String emotion in voiceScores.keys) {
      finalScores[emotion] = (voiceScores[emotion]! * voiceWeight) +
          (textScores[emotion]! * textWeight) +
          (contextScores[emotion]! * contextWeight);
    }

    return finalScores;
  }

  // 최고 점수 감정 선택
  String _getTopEmotion(Map<String, double> scores) {
    String topEmotion = '차분';
    double maxScore = 0.0;

    for (String emotion in scores.keys) {
      if (scores[emotion]! > maxScore) {
        maxScore = scores[emotion]!;
        topEmotion = emotion;
      }
    }

    // 최소 임계값 검사
    if (maxScore < 0.3) {
      return '차분';
    }

    return topEmotion;
  }

  // 간단한 감정 분석 (기존 방식)
  String _analyzeEmotionSimple(String text) {
    if (text.contains('좋') ||
        text.contains('감사') ||
        text.contains('기쁨') ||
        text.contains('행복')) {
      return '기쁨';
    } else if (text.contains('화나') ||
        text.contains('짜증') ||
        text.contains('싫') ||
        text.contains('!')) {
      return '짜증';
    } else if (text.contains('놀랍') ||
        text.contains('어?') ||
        text.contains('정말?') ||
        text.contains('와!')) {
      return '놀람';
    } else if (text.contains('슬프') ||
        text.contains('아쉽') ||
        text.contains('안타깝')) {
      return '슬픔';
    } else {
      return '차분';
    }
  }

  // 감정 패턴 분석
  String _analyzeEmotionPattern() {
    if (_emotionHistory.length < 3) return '안정적';

    List<String> last3 = _emotionHistory.take(3).toList();

    if (last3.every((e) => e == last3.first)) {
      return '지속적';
    } else if (last3.contains('화남') && last3.contains('슬픔')) {
      return '불안정';
    } else if (last3.where((e) => e == '기쁨').length >= 2) {
      return '긍정적';
    } else {
      return '변화적';
    }
  }

  // 감정 신뢰도 계산
  double _calculateEmotionConfidence(String emotion) {
    double baseConfidence = _confidence;

    // 최근 감정 일관성 보너스
    if (_emotionHistory.length >= 3) {
      int sameEmotionCount =
          _emotionHistory.take(3).where((e) => e == emotion).length;
      baseConfidence += (sameEmotionCount / 3.0) * 0.2;
    }

    // 음성 특징 신뢰도 보너스
    if (_currentEnergy > 0.7) baseConfidence += 0.1;
    if (_currentVolume > 60) baseConfidence += 0.1;

    // 감정 신뢰도 계산
    double calculateEmotionConfidence(String emotion) {
      double baseConfidence = _confidence;

      // 최근 감정 일관성 보너스
      if (_emotionHistory.length >= 3) {
        int sameEmotionCount =
            _emotionHistory.take(3).where((e) => e == emotion).length;
        baseConfidence += (sameEmotionCount / 3.0) * 0.2;
      }

      // 음성 특징 신뢰도 보너스
      if (_currentEnergy > 0.7) baseConfidence += 0.1;
      if (_currentVolume > 60) baseConfidence += 0.1;

      return baseConfidence.clamp(0.0, 1.0);
    }

    return baseConfidence.clamp(0.0, 1.0);
  }

  // 자막 추가
  void _addSubtitle(String text, {bool isPartial = false}) {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    String emotion = _analyzeEmotion(text);
    _currentEmotion = emotion;

    final subtitle = SubtitleData(
      speaker: _currentSpeaker,
      text: text.trim(),
      emotion: emotion,
      time: timeString,
    );

    if (!isPartial) {
      _subtitles.add(subtitle);
      _subtitleController.add(subtitle);
    }

    notifyListeners();
  }

  // 화자 변화 감지
  void _detectSpeakerChange() {
    if (_subtitles.isNotEmpty) {
      if (_shouldChangeSpeaker()) {
        _switchToNextSpeaker();
      }
    }
  }

  bool _shouldChangeSpeaker() {
    // 감정 변화도 화자 변경의 단서가 될 수 있음
    if (_emotionHistory.length >= 2) {
      String currentEmotion = _emotionHistory[0];
      String previousEmotion = _emotionHistory[1];

      if ((currentEmotion == '화남' && previousEmotion == '기쁨') ||
          (currentEmotion == '기쁨' && previousEmotion == '슬픔')) {
        return true;
      }
    }

    // 긴 침묵 후의 발화는 새로운 화자일 가능성
    if (_pauseDuration.inSeconds > 5) {
      return true;
    }

    return false;
  }

  void _switchToNextSpeaker() {
    _speakerCount++;
    if (_speakerCount > 3) _speakerCount = 1;
    _currentSpeaker = '화자$_speakerCount';
  }

  // 화자 수동 변경
  void changeSpeaker(String speaker) {
    _currentSpeaker = speaker;
    notifyListeners();
  }

  // 음성 인식 상태 변화 처리
  void _onSpeechStatus(String status) {
    if (kDebugMode) print('STT 상태: $status');

    switch (status) {
      case 'listening':
        _isListening = true;
        break;
      case 'notListening':
        _isListening = false;
        break;
      case 'done':
        _isListening = false;
        break;
    }

    notifyListeners();
  }

  // 음성 인식 오류 처리
  void _onSpeechError(dynamic error) {
    if (kDebugMode) print('STT 오류: $error');
    _isListening = false;
    notifyListeners();
  }

  // 실시간 감정 모니터링 스트림
  Stream<Map<String, dynamic>> get emotionStream async* {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      yield {
        'emotion': _currentEmotion,
        'confidence': _emotionConfidence,
        'pattern': _emotionPattern,
        'voiceFeatures': {
          'pitch': _currentPitch,
          'volume': _currentVolume,
          'speechRate': _currentSpeechRate,
          'energy': _currentEnergy,
        }
      };
    }
  }

  // 감정 통계 가져오기
  Map<String, dynamic> getEmotionStatistics() {
    Map<String, int> emotionCounts = {};

    for (var subtitle in _subtitles) {
      emotionCounts[subtitle.emotion] =
          (emotionCounts[subtitle.emotion] ?? 0) + 1;
    }

    String dominantEmotion = '차분';
    int maxCount = 0;
    for (var entry in emotionCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        dominantEmotion = entry.key;
      }
    }

    double emotionStability = _getEmotionStability();

    return {
      'emotionCounts': emotionCounts,
      'dominantEmotion': dominantEmotion,
      'emotionStability': emotionStability,
      'currentPattern': _emotionPattern,
      'totalUtterances': _subtitles.length,
    };
  }

  double _getEmotionStability() {
    if (_emotionHistory.length < 3) return 1.0;

    List<String> recent = _emotionHistory.take(5).toList();
    Set<String> uniqueEmotions = recent.toSet();

    return 1.0 - (uniqueEmotions.length / recent.length);
  }

  // 감정 기반 추천 기능
  String getEmotionBasedRecommendation() {
    switch (_currentEmotion) {
      case '슬픔':
        return '차분한 음악을 들어보시거나 잠시 휴식을 취해보세요.';
      case '화남':
        return '심호흡을 하고 잠시 대화를 멈춰보세요.';
      case '기쁨':
        return '좋은 분위기네요! 이 기분을 유지해보세요.';
      case '놀람':
        return '놀라운 소식이 있었나요? 차근차근 정리해보세요.';
      default:
        return '안정적인 대화가 이어지고 있습니다.';
    }
  }

  // 고급 감정 분석 활성화/비활성화
  void toggleAdvancedEmotionAnalysis() {
    _advancedEmotionAnalysis = !_advancedEmotionAnalysis;
    notifyListeners();
  }

  // 감정 민감도 조정
  void setEmotionSensitivity(double sensitivity) {
    _emotionSensitivity = sensitivity.clamp(0.1, 2.0);
    notifyListeners();
  }

  // 자막 저장
  Future<void> saveSubtitles() async {
    if (kDebugMode) print('자막 저장: ${_subtitles.length}개 항목');
  }

  // 자막 삭제
  void clearSubtitles() {
    _subtitles.clear();
    _emotionHistory.clear();
    _currentEmotion = '차분';
    _emotionConfidence = 0.0;
    _emotionPattern = '안정적';
    notifyListeners();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _subtitleController.close();
    super.dispose();
  }
}
