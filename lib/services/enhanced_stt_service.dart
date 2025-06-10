import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/subtitle_data.dart';
import 'enhanced_emotion_analysis.dart';

// 강화된 STT 서비스
class EnhancedSTTService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  String _currentText = '';
  String _lastRecognizedText = '';
  double _confidence = 0.0;
  String _currentSpeaker = '화자1';
  int _speakerCount = 1;

  // 음성 분석 관련 변수들
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

  // STT 초기화
  Future<bool> initialize() async {
    try {
      // 마이크 권한 확인
      bool hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        if (kDebugMode) print('마이크 권한이 거부되었습니다.');
        return false;
      }

      // STT 초기화
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

  // 마이크 권한 요청
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

      // 마지막 텍스트가 있으면 자막으로 추가
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

  // 음성 인식 결과 처리 (강화된 버전)
  void _onSpeechResult(SpeechRecognitionResult result) {
    _currentText = result.recognizedWords;
    _confidence = result.confidence;

    // 음성 특징 추출 및 업데이트
    _updateVoiceFeatures(result);

    if (kDebugMode) {
      print(
          '인식된 텍스트: $_currentText (확신도: ${(_confidence * 100).toStringAsFixed(1)}%)');
      print(
          '음성 특징 - 피치: $_currentPitch, 볼륨: $_currentVolume, 속도: $_currentSpeechRate');
    }

    // 최종 결과일 때만 자막 추가
    if (result.finalResult) {
      _lastRecognizedText = _currentText;
      _addSubtitle(_currentText, isPartial: false);

      // 화자 전환 감지
      _detectSpeakerChange();
    } else {
      // 부분 결과는 실시간으로 표시
      notifyListeners();
    }
  }

  // 음성 특징 추출 및 업데이트
  void _updateVoiceFeatures(SpeechRecognitionResult result) {
    // 실제 구현에서는 음성 신호 분석 라이브러리 필요
    // 여기서는 시뮬레이션된 값들 사용

    // 텍스트 길이와 신뢰도를 기반으로 한 추정치
    double textLength = _currentText.length.toDouble();
    double confidenceBoost = _confidence;

    // 피치 추정 (텍스트 특성 기반)
    if (_currentText.contains('?') ||
        _currentText.contains('어?') ||
        _currentText.contains('정말?')) {
      _currentPitch = 200 + (confidenceBoost * 100); // 의문문은 높은 피치
    } else if (_currentText.contains('!') ||
        _currentText.contains('와') ||
        _currentText.contains('대박')) {
      _currentPitch = 250 + (confidenceBoost * 150); // 감탄문은 매우 높은 피치
    } else {
      _currentPitch = 120 + (confidenceBoost * 60); // 평서문은 보통 피치
    }

    // 볼륨 추정 (텍스트 강도 기반)
    if (_currentText.contains('!') ||
        _currentText.toUpperCase() == _currentText) {
      _currentVolume = 70 + (confidenceBoost * 20);
    } else {
      _currentVolume = 45 + (confidenceBoost * 15);
    }

    // 말하기 속도 추정 (시간당 글자 수)
    DateTime now = DateTime.now();
    if (_lastSpeechTime != null) {
      Duration elapsed = now.difference(_lastSpeechTime!);
      if (elapsed.inMilliseconds > 0) {
        _currentSpeechRate = (textLength / elapsed.inSeconds) * 60; // 분당 글자 수
        _pauseDuration = elapsed;
      }
    }

    // 에너지 추정 (신뢰도와 텍스트 특성 기반)
    _currentEnergy = _confidence * (1.0 + (textLength / 100));

    _lastSpeechTime = now;
  }

  // 강화된 감정 분석
  String _analyzeEmotionEnhanced(String text) {
    // 음성 특징 객체 생성
    VoiceFeatures features = VoiceFeatures(
      pitch: _currentPitch,
      volume: _currentVolume,
      speechRate: _currentSpeechRate,
      energy: _currentEnergy,
      confidence: _confidence,
      text: text,
      pauseDuration: _pauseDuration,
    );

    // 강화된 감정 분석 실행
    String detectedEmotion = EnhancedEmotionAnalyzer.analyzeEmotion(features);

    // 감정 히스토리 업데이트
    _emotionHistory.insert(0, detectedEmotion);
    if (_emotionHistory.length > 10) {
      _emotionHistory.removeRange(10, _emotionHistory.length);
    }

    // 감정 히스토리에 추가
    EmotionHistory.addEmotion(detectedEmotion, _confidence, DateTime.now());

    // 감정 패턴 분석
    _emotionPattern =
        EnhancedEmotionAnalyzer.analyzeEmotionPattern(_emotionHistory);

    // 감정 신뢰도 계산
    _emotionConfidence = _calculateEmotionConfidence(detectedEmotion);

    if (kDebugMode) {
      print(
          '감정 분석 결과: $detectedEmotion (신뢰도: ${_emotionConfidence.toStringAsFixed(2)})');
      print('감정 패턴: $_emotionPattern');
    }

    return detectedEmotion;
  }

  // 감정 신뢰도 계산
  double _calculateEmotionConfidence(String emotion) {
    // 기본 신뢰도는 STT 신뢰도에서 시작
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

  // 자막 추가 (강화된 버전)
  void _addSubtitle(String text, {bool isPartial = false}) {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 강화된 감정 분석 적용
    String emotion = _analyzeEmotionEnhanced(text);
    _currentEmotion = emotion;

    final subtitle = SubtitleData(
      speaker: _currentSpeaker,
      text: text.trim(),
      emotion: emotion,
      time: timeString,
    );

    // 부분 결과가 아닐 때만 리스트에 추가
    if (!isPartial) {
      _subtitles.add(subtitle);
      _subtitleController.add(subtitle);
    }

    notifyListeners();
  }

  // 화자 변화 감지 (음성 특징 기반)
  void _detectSpeakerChange() {
    if (_subtitles.isNotEmpty) {
      // 음성 특징 변화를 기반으로 한 화자 감지
      if (_shouldChangeSpeakerByVoice()) {
        _switchToNextSpeaker();
      }
    }
  }

  // 음성 특징 기반 화자 변경 감지
  bool _shouldChangeSpeakerByVoice() {
    if (_subtitles.length < 2) return false;

    // 이전 발화와 현재 발화의 음성 특징 비교
    // 실제로는 더 정교한 voice embedding 기술 사용 권장

    // 피치 변화가 50Hz 이상이면 다른 화자일 가능성
    double pitchThreshold = 50.0;

    // 볼륨 변화가 20dB 이상이면 다른 화자일 가능성
    double volumeThreshold = 20.0;

    // 말하기 속도 변화가 50단어/분 이상이면 다른 화자일 가능성
    double speedThreshold = 50.0;

    // 간단한 변화 감지 로직 (실제로는 ML 모델 사용 권장)
    bool significantChange = false;

    // 감정 변화도 화자 변경의 단서가 될 수 있음
    if (_emotionHistory.length >= 2) {
      String currentEmotion = _emotionHistory[0];
      String previousEmotion = _emotionHistory[1];

      // 극단적인 감정 변화는 화자 변경 가능성
      if ((currentEmotion == '화남' && previousEmotion == '기쁨') ||
          (currentEmotion == '기쁨' && previousEmotion == '슬픔')) {
        significantChange = true;
      }
    }

    // 긴 침묵 후의 발화는 새로운 화자일 가능성
    if (_pauseDuration.inSeconds > 5) {
      significantChange = true;
    }

    return significantChange;
  }

  void _switchToNextSpeaker() {
    _speakerCount++;
    if (_speakerCount > 3) _speakerCount = 1; // 최대 3명까지
    _currentSpeaker = '화자$_speakerCount';

    if (kDebugMode) print('화자 변경: $_currentSpeaker');
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

    double emotionStability = EmotionHistory.getEmotionStability();

    return {
      'emotionCounts': emotionCounts,
      'dominantEmotion': dominantEmotion,
      'emotionStability': emotionStability,
      'currentPattern': _emotionPattern,
      'totalUtterances': _subtitles.length,
    };
  }

  // 음성 특징 통계 가져오기
  Map<String, dynamic> getVoiceStatistics() {
    if (_subtitles.isEmpty) {
      return {
        'averagePitch': 0.0,
        'averageVolume': 0.0,
        'averageSpeechRate': 0.0,
        'averageConfidence': 0.0,
      };
    }

    // 간단한 평균 계산 (실제로는 각 발화별 데이터 저장 필요)
    return {
      'averagePitch': _currentPitch,
      'averageVolume': _currentVolume,
      'averageSpeechRate': _currentSpeechRate,
      'averageConfidence': _confidence,
      'currentEmotion': _currentEmotion,
      'emotionConfidence': _emotionConfidence,
    };
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

  // 고급 감정 분석 활성화/비활성화
  bool _advancedEmotionAnalysis = true;
  bool get advancedEmotionAnalysis => _advancedEmotionAnalysis;

  void toggleAdvancedEmotionAnalysis() {
    _advancedEmotionAnalysis = !_advancedEmotionAnalysis;
    notifyListeners();
  }

  // 감정 민감도 조정
  double _emotionSensitivity = 1.0;
  double get emotionSensitivity => _emotionSensitivity;

  void setEmotionSensitivity(double sensitivity) {
    _emotionSensitivity = sensitivity.clamp(0.1, 2.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _subtitleController.close();
    super.dispose();
  }
}
