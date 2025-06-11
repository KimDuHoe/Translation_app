import 'package:flutter/material.dart';
import '../models/subtitle_data.dart';
import '../models/conversation_data.dart';
import '../services/stt_service.dart';
import 'settings_screen.dart';
import 'saved_conversations_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _dotsController;

  // STT 서비스
  STTService? _sttService;
  bool _isInitialized = false;

  // 현재 상태
  bool _isListening = false;
  String _currentText = '';
  double _confidence = 0.0;
  String _currentSpeaker = '화자';

  // 자막 데이터
  List<SubtitleData> _subtitles = [];

  // 저장된 대화 목록
  final List<ConversationData> _savedConversations = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _initializeSTT();
  }

  Future<void> _initializeSTT() async {
    _sttService = STTService();
    bool success = await _sttService!.initialize();

    setState(() {
      _isInitialized = success;
    });

    if (!success) {
      _showErrorDialog('STT 초기화에 실패했습니다. 마이크 권한을 확인해주세요.');
    }

    // STT 서비스의 상태 변화를 감지하기 위한 리스너 추가
    _sttService!.addListener(_onSTTStateChanged);
  }

  void _onSTTStateChanged() {
    if (_sttService != null) {
      setState(() {
        _isListening = _sttService!.isListening;
        _currentText = _sttService!.currentText;
        _confidence = _sttService!.confidence;
        _currentSpeaker = _sttService!.currentSpeaker;
        _subtitles = List.from(_sttService!.subtitles);
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
    _sttService?.removeListener(_onSTTStateChanged);
    _sttService?.dispose();
    super.dispose();
  }

  Future<void> toggleRecording() async {
    if (_sttService == null || !_isInitialized) return;

    if (_isListening) {
      await _sttService!.stopListening();
    } else {
      await _sttService!.startListening();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),

            // 실시간 자막 영역
            Expanded(
              child: _buildSubtitleArea(),
            ),

            // AI 요약 안내 배너 (새로 추가)
            if (_subtitles.length >= 3) _buildSummaryPromoBanner(),

            // 화자 구분 범례
            _buildSpeakerLegend(),

            // 하단 컨트롤
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.purple[600]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '마일스톤',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI 기반 스마트 음성 보조',
                  style: TextStyle(
                    color: Colors.blue[100],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (_subtitles.isNotEmpty)
                  GestureDetector(
                    onTap: _showQuickSummary,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(77)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AI 요약',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    );
                  },
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleArea() {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // 상태 표시
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '실시간 자막',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? Colors.green
                                    .withValues(alpha: _pulseController.value)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isListening ? "음성 인식 중..." : "음성 인식 대기",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 자막 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _subtitles.length + (_isListening ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _subtitles.length && _isListening) {
                  return _buildCurrentInputSubtitle();
                }
                return _buildSubtitleItem(_subtitles[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[100]!, Colors.amber[100]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Colors.orange[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 요약 기능',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                Text(
                  '대화 내용을 AI가 자동으로 요약해드립니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showQuickSummary,
            style: TextButton.styleFrom(
              backgroundColor: Colors.orange[200],
              foregroundColor: Colors.orange[800],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '요약하기',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitleItem(SubtitleData subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getSpeakerBackgroundColor(subtitle.speaker),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: _getSpeakerColor(subtitle.speaker),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      subtitle.speaker,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getEmotionBackgroundColor(subtitle.emotion),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        subtitle.emotion,
                        style: TextStyle(
                          color: _getEmotionTextColor(subtitle.emotion),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle.time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle.text,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Colors.grey[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentInputSubtitle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: Colors.orange[500]!,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _currentSpeaker,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '인식중',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currentText.isNotEmpty ? _currentText : "음성을 인식하고 있습니다...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[900],
                fontStyle:
                    _currentText.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const SizedBox(height: 8),
            _buildTypingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          children: List.generate(3, (index) {
            double delay = index * 0.2;
            double animationValue =
                (_dotsController.value - delay).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.only(right: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.orange[400]!.withValues(
                    alpha: 0.3 +
                        0.7 *
                            (1 - (animationValue - 0.5).abs() * 2)
                                .clamp(0.0, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSpeakerLegend() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '화자 구분 범례',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem("화자1", Colors.blue[500]!),
              const SizedBox(width: 16),
              _buildLegendItem("화자2", Colors.green[500]!),
              const SizedBox(width: 16),
              _buildLegendItem("화자3", Colors.purple[500]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 메인 녹음 버튼
                GestureDetector(
                  onTap: toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red[500] : Colors.blue[500],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : Colors.blue)
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _isListening ? "탭하여 음성 인식 중지" : "탭하여 음성 인식 시작",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),

                // 확신도 표시
                if (_isListening && _confidence > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '확신도: ${(_confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // 기능 버튼들
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeatureButton(
                      Icons.people,
                      "화자구분",
                      onTap: _showSpeakerDialog,
                    ),
                    _buildFeatureButton(
                      Icons.auto_awesome,
                      "AI요약",
                      onTap: _subtitles.isNotEmpty ? _showQuickSummary : null,
                      isHighlighted: _subtitles.length >= 3,
                    ),
                    _buildFeatureButton(
                      Icons.save,
                      "저장",
                      onTap: _saveCurrentConversation,
                    ),
                    _buildFeatureButton(
                      Icons.history,
                      "저장목록",
                      onTap: _showSavedConversations,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(IconData icon, String label,
      {VoidCallback? onTap, bool isHighlighted = false}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isHighlighted ? Colors.orange[100] : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isHighlighted ? Colors.orange[700] : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isHighlighted ? Colors.orange[700] : Colors.grey[600],
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 빠른 요약 표시
  void _showQuickSummary() {
    if (_subtitles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('요약할 대화 내용이 없습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 임시 ConversationData 생성
    final tempConversation = ConversationData(
      title: '현재 대화',
      createdAt: DateTime.now(),
      subtitles: _subtitles,
      speakers: _subtitles.map((s) => s.speaker).toSet().toList(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SummaryScreen(conversation: tempConversation),
      ),
    );
  }

  // 화자 선택 다이얼로그
  void _showSpeakerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('화자 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('현재 화자: $_currentSpeaker'),
            const SizedBox(height: 16),
            ...['화자1', '화자2', '화자3'].map(
              (speaker) => ListTile(
                title: Text(speaker),
                leading: Radio<String>(
                  value: speaker,
                  groupValue: _currentSpeaker,
                  onChanged: (value) {
                    if (value != null && _sttService != null) {
                      _sttService!.changeSpeaker(value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  // 현재 대화 저장
  void _saveCurrentConversation() {
    if (_subtitles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장할 대화가 없습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final title = '대화 ${now.month}월 ${now.day}일 ${now.hour}시 ${now.minute}분';

    final speakers = _subtitles.map((s) => s.speaker).toSet().toList();

    final conversation = ConversationData(
      title: title,
      createdAt: now,
      subtitles: List.from(_subtitles),
      speakers: speakers,
    );

    setState(() {
      _savedConversations.insert(0, conversation);
    });

    // 현재 대화 내용 클리어
    if (_sttService != null) {
      _sttService!.clearSubtitles();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(child: Text('대화가 저장되었습니다.')),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SummaryScreen(conversation: conversation),
                  ),
                );
              },
              child: const Text(
                'AI 요약',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // 저장된 대화 목록 보기
  void _showSavedConversations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedConversationsScreen(
          conversations: _savedConversations,
        ),
      ),
    );
  }

  // 색상 관련 메서드들
  Color _getSpeakerColor(String speaker) {
    switch (speaker) {
      case "화자1":
        return Colors.blue[500]!;
      case "화자2":
        return Colors.green[500]!;
      case "화자3":
        return Colors.purple[500]!;
      default:
        return Colors.grey[500]!;
    }
  }

  Color _getSpeakerBackgroundColor(String speaker) {
    switch (speaker) {
      case "화자1":
        return Colors.blue[50]!;
      case "화자2":
        return Colors.green[50]!;
      case "화자3":
        return Colors.purple[50]!;
      default:
        return Colors.grey[50]!;
    }
  }

  Color _getEmotionTextColor(String emotion) {
    switch (emotion) {
      case "기쁨":
        return Colors.blue[600]!;
      case "차분":
        return Colors.green[600]!;
      case "기대":
        return Colors.purple[600]!;
      case "짜증":
        return Colors.red[600]!;
      case "놀람":
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Color _getEmotionBackgroundColor(String emotion) {
    switch (emotion) {
      case "기쁨":
        return Colors.blue[50]!;
      case "차분":
        return Colors.green[50]!;
      case "기대":
        return Colors.purple[50]!;
      case "짜증":
        return Colors.red[50]!;
      case "놀람":
        return Colors.orange[50]!;
      default:
        return Colors.grey[50]!;
    }
  }
}
