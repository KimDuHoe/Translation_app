import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Azure AI 언어 서비스를 위한 감정 분석 클래스 (실제 API 기반)
class AzureEmotionService {
  // Azure AI 언어 서비스 설정
  static const String _endpoint =
      'YOUR_AZURE_ENDPOINT'; // 예: 'https://your-resource.cognitiveservices.azure.com'
  static const String _apiKey = 'YOUR_AZURE_API_KEY';
  static const String _apiVersion = '2024-11-01'; // 최신 API 버전

  // 감정 분석 API 호출 (실제 Azure API 구조)
  static Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    try {
      final url = Uri.parse(
          '$_endpoint/language/:analyze-text?api-version=$_apiVersion');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': _apiKey,
        },
        body: jsonEncode({
          'kind': 'SentimentAnalysis',
          'parameters': {
            'modelVersion': 'latest',
            'opinionMining': true, // Opinion Mining 활성화
          },
          'analysisInput': {
            'documents': [
              {
                'id': '1',
                'language': 'ko', // 한국어
                'text': text,
              }
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _processAzureResponse(data);
      } else {
        if (kDebugMode) {
          print('Azure API 오류: ${response.statusCode} - ${response.body}');
        }
        return _getFallbackResult(text);
      }
    } catch (e) {
      if (kDebugMode) print('Azure API 호출 실패: $e');
      return _getFallbackResult(text);
    }
  }

  // Azure 응답 처리 (실제 응답 구조 기반)
  static Map<String, dynamic> _processAzureResponse(Map<String, dynamic> data) {
    try {
      final results = data['results'];
      final document = results['documents'][0];
      final sentiment = document['sentiment'];
      final confidenceScores = document['confidenceScores'];
      final sentences = document['sentences'] ?? [];

      // Azure 감정을 한국어 감정으로 매핑
      String koreanEmotion = _mapAzureSentimentToKorean(sentiment);

      // 감정별 신뢰도
      Map<String, double> emotionConfidence = {
        '긍정': (confidenceScores['positive'] ?? 0.0).toDouble(),
        '부정': (confidenceScores['negative'] ?? 0.0).toDouble(),
        '중립': (confidenceScores['neutral'] ?? 0.0).toDouble(),
      };

      // Opinion Mining 결과 처리
      List<Map<String, dynamic>> opinions = [];
      if (sentences.isNotEmpty) {
        for (var sentence in sentences) {
          if (sentence['targets'] != null) {
            for (var target in sentence['targets']) {
              opinions.add({
                'target': target['text'],
                'sentiment': target['sentiment'],
                'confidence': target['confidenceScores'],
                'assessments':
                    target['relations']?.map((r) => r['ref'])?.toList() ?? [],
              });
            }
          }
        }
      }

      // 문장별 감정 분석
      List<Map<String, dynamic>> sentenceAnalysis = [];
      for (var sentence in sentences) {
        sentenceAnalysis.add({
          'text': sentence['text'],
          'sentiment': _mapAzureSentimentToKorean(sentence['sentiment']),
          'confidence': _getMainConfidence(
              sentence['sentiment'], sentence['confidenceScores']),
          'offset': sentence['offset'],
          'length': sentence['length'],
        });
      }

      return {
        'emotion': koreanEmotion,
        'confidence': _getMainConfidence(sentiment, confidenceScores),
        'detailed_confidence': emotionConfidence,
        'sentence_analysis': sentenceAnalysis,
        'opinions': opinions, // Opinion Mining 결과
        'original_sentiment': sentiment,
        'success': true,
      };
    } catch (e) {
      if (kDebugMode) print('Azure 응답 처리 오류: $e');
      return _getFallbackResult('');
    }
  }

  // Azure 감정을 한국어 감정으로 매핑 (더 정교하게)
  static String _mapAzureSentimentToKorean(String azureSentiment) {
    switch (azureSentiment.toLowerCase()) {
      case 'positive':
        return '기쁨';
      case 'negative':
        return '슬픔';
      case 'neutral':
        return '차분';
      case 'mixed':
        return '복합감정'; // Azure의 mixed 감정
      default:
        return '차분';
    }
  }

  // 주요 신뢰도 계산
  static double _getMainConfidence(
      String sentiment, Map<String, dynamic> scores) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return (scores['positive'] ?? 0.0).toDouble();
      case 'negative':
        return (scores['negative'] ?? 0.0).toDouble();
      case 'neutral':
        return (scores['neutral'] ?? 0.0).toDouble();
      case 'mixed':
        // Mixed인 경우 가장 높은 신뢰도 반환
        double positive = (scores['positive'] ?? 0.0).toDouble();
        double negative = (scores['negative'] ?? 0.0).toDouble();
        double neutral = (scores['neutral'] ?? 0.0).toDouble();
        return [positive, negative, neutral].reduce((a, b) => a > b ? a : b);
      default:
        return 0.0;
    }
  }

  // API 실패시 fallback 결과
  static Map<String, dynamic> _getFallbackResult(String text) {
    return {
      'emotion': _simpleEmotionAnalysis(text),
      'confidence': 0.5,
      'detailed_confidence': {'긍정': 0.3, '부정': 0.3, '중립': 0.4},
      'sentence_analysis': [],
      'opinions': [],
      'original_sentiment': 'neutral',
      'success': false,
    };
  }

  // 간단한 키워드 기반 감정 분석 (fallback)
  static String _simpleEmotionAnalysis(String text) {
    if (text.contains('좋') ||
        text.contains('행복') ||
        text.contains('기쁨') ||
        text.contains('최고')) {
      return '기쁨';
    } else if (text.contains('슬프') ||
        text.contains('힘들') ||
        text.contains('아쉽') ||
        text.contains('실망')) {
      return '슬픔';
    } else if (text.contains('화나') ||
        text.contains('짜증') ||
        text.contains('싫') ||
        text.contains('분노')) {
      return '화남';
    } else if (text.contains('놀라') ||
        text.contains('어?') ||
        text.contains('와!') ||
        text.contains('대박')) {
      return '놀람';
    } else {
      return '차분';
    }
  }

  // 배치 감정 분석 (여러 텍스트 한번에) - Azure API 지원
  static Future<List<Map<String, dynamic>>> analyzeBatchSentiment(
      List<String> texts) async {
    try {
      final url = Uri.parse(
          '$_endpoint/language/:analyze-text?api-version=$_apiVersion');

      List<Map<String, dynamic>> documents = [];
      for (int i = 0; i < texts.length; i++) {
        documents.add({
          'id': (i + 1).toString(),
          'language': 'ko',
          'text': texts[i],
        });
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': _apiKey,
        },
        body: jsonEncode({
          'kind': 'SentimentAnalysis',
          'parameters': {
            'modelVersion': 'latest',
            'opinionMining': true,
          },
          'analysisInput': {
            'documents': documents,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> results = [];

        for (var document in data['results']['documents']) {
          results.add(_processAzureResponse({
            'results': {
              'documents': [document]
            }
          }));
        }

        return results;
      } else {
        // 실패시 각 텍스트에 대해 fallback 결과 반환
        return texts.map((text) => _getFallbackResult(text)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('Azure 배치 분석 실패: $e');
      return texts.map((text) => _getFallbackResult(text)).toList();
    }
  }

  // 키 구문 추출 (Azure API)
  static Future<List<String>> extractKeyPhrases(String text) async {
    try {
      final url = Uri.parse(
          '$_endpoint/language/:analyze-text?api-version=$_apiVersion');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': _apiKey,
        },
        body: jsonEncode({
          'kind': 'KeyPhraseExtraction',
          'parameters': {
            'modelVersion': 'latest',
          },
          'analysisInput': {
            'documents': [
              {
                'id': '1',
                'language': 'ko',
                'text': text,
              }
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final keyPhrases =
            data['results']['documents'][0]['keyPhrases'] as List;
        return keyPhrases.cast<String>();
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('키 구문 추출 실패: $e');
      return [];
    }
  }

  // 개체명 인식 (Named Entity Recognition)
  static Future<List<Map<String, dynamic>>> recognizeEntities(
      String text) async {
    try {
      final url = Uri.parse(
          '$_endpoint/language/:analyze-text?api-version=$_apiVersion');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': _apiKey,
        },
        body: jsonEncode({
          'kind': 'EntityRecognition',
          'parameters': {
            'modelVersion': 'latest',
          },
          'analysisInput': {
            'documents': [
              {
                'id': '1',
                'language': 'ko',
                'text': text,
              }
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final entities = data['results']['documents'][0]['entities'] as List;

        return entities
            .map<Map<String, dynamic>>((entity) => {
                  'text': entity['text'],
                  'category': entity['category'],
                  'subcategory': entity['subcategory'],
                  'confidence': entity['confidenceScore'],
                  'offset': entity['offset'],
                  'length': entity['length'],
                })
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('개체명 인식 실패: $e');
      return [];
    }
  }

  // 언어 감지
  static Future<String> detectLanguage(String text) async {
    try {
      final url = Uri.parse(
          '$_endpoint/language/:analyze-text?api-version=$_apiVersion');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': _apiKey,
        },
        body: jsonEncode({
          'kind': 'LanguageDetection',
          'parameters': {
            'modelVersion': 'latest',
          },
          'analysisInput': {
            'documents': [
              {
                'id': '1',
                'text': text,
              }
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final detectedLanguage =
            data['results']['documents'][0]['detectedLanguage'];
        return detectedLanguage['iso6391Name'] ?? 'ko';
      } else {
        return 'ko'; // 기본값: 한국어
      }
    } catch (e) {
      if (kDebugMode) print('언어 감지 실패: $e');
      return 'ko';
    }
  }

  // 종합 텍스트 분석 (감정 + 키구문 + 개체명)
  static Future<Map<String, dynamic>> comprehensiveAnalysis(String text) async {
    try {
      // 병렬로 여러 분석 수행
      final results = await Future.wait([
        analyzeSentiment(text),
        extractKeyPhrases(text),
        recognizeEntities(text),
      ]);

      return {
        'sentiment': results[0],
        'keyPhrases': results[1],
        'entities': results[2],
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) print('종합 분석 실패: $e');
      return {
        'sentiment': _getFallbackResult(text),
        'keyPhrases': <String>[],
        'entities': <Map<String, dynamic>>[],
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // API 연결 테스트
  static Future<bool> testConnection() async {
    try {
      final result = await analyzeSentiment('어서오세요.');
      return result['success'] ?? false;
    } catch (e) {
      if (kDebugMode) print('Azure API 연결 테스트 실패: $e');
      return false;
    }
  }

  // Azure AI 한국어 지원 확인 (2024년 11월 기준)
  static List<String> getSupportedLanguages() {
    return [
      'ko', // 한국어 - 완전 지원
      'en', // 영어
      'es', // 스페인어
      'fr', // 프랑스어
      'de', // 독일어
      'it', // 이탈리아어
      'pt', // 포르투갈어
      'ru', // 러시아어
      'ja', // 일본어
      'zh', // 중국어
    ];
  }

  // 무료 할당량 정보 제공
  static Map<String, dynamic> getPricingInfo() {
    return {
      'free_tier': {
        'text_records_per_month': 5000,
        'description': '월 5,000 텍스트 레코드 무료',
      },
      'standard_tier': {
        'price_per_1000_records': 1.0, // USD
        'description': '1,000 텍스트 레코드당 1달러',
      },
      'note': '실제 가격은 Azure 포털에서 확인하세요',
    };
  }
}
