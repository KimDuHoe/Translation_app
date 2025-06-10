import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/conversation_data.dart';
import '../services/summary_service.dart';

class SummaryScreen extends StatefulWidget {
  final ConversationData conversation;

  const SummaryScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen>
    with TickerProviderStateMixin {
  ConversationSummary? _summary;
  bool _isGenerating = false;
  SummaryType _selectedSummaryType = SummaryType.brief;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _generateSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final summary = await SummaryService.generateSummary(
        widget.conversation.subtitles,
        type: _selectedSummaryType,
      );

      setState(() {
        _summary = summary;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('요약 생성 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('대화 요약'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_summary != null)
            PopupMenuButton<SummaryType>(
              icon: const Icon(Icons.tune),
              onSelected: (type) {
                setState(() {
                  _selectedSummaryType = type;
                });
                _generateSummary();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: SummaryType.brief,
                  child: Text('간단 요약'),
                ),
                const PopupMenuItem(
                  value: SummaryType.detailed,
                  child: Text('상세 요약'),
                ),
                const PopupMenuItem(
                  value: SummaryType.keyPoints,
                  child: Text('핵심 포인트'),
                ),
                const PopupMenuItem(
                  value: SummaryType.emotional,
                  child: Text('감정 중심'),
                ),
                const PopupMenuItem(
                  value: SummaryType.action,
                  child: Text('액션 아이템'),
                ),
              ],
            ),
        ],
      ),
      body: _isGenerating ? _buildLoadingWidget() : _buildSummaryContent(),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '대화 요약을 생성하고 있습니다...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.conversation.subtitles.length}개 발언 분석 중',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent() {
    if (_summary == null) {
      return const Center(
        child: Text('요약을 생성할 수 없습니다.'),
      );
    }

    return Column(
      children: [
        // 요약 타입 선택 칩
        _buildSummaryTypeSelector(),

        // 탭 바
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.blue[600],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue[600],
            tabs: const [
              Tab(text: '요약'),
              Tab(text: '분석'),
              Tab(text: '감정'),
              Tab(text: '참여자'),
              Tab(text: '액션'),
            ],
          ),
        ),

        // 탭 콘텐츠
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(),
              _buildAnalysisTab(),
              _buildEmotionTab(),
              _buildParticipantTab(),
              _buildActionTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTypeSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '요약 유형',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SummaryType.values.map((type) {
              String label = _getSummaryTypeLabel(type);
              bool isSelected = _selectedSummaryType == type;

              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSummaryType = type;
                    });
                    _generateSummary();
                  }
                },
                selectedColor: Colors.blue[100],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.blue[700] : Colors.grey[600],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getSummaryTypeLabel(SummaryType type) {
    switch (type) {
      case SummaryType.brief:
        return '간단';
      case SummaryType.detailed:
        return '상세';
      case SummaryType.keyPoints:
        return '핵심';
      case SummaryType.emotional:
        return '감정';
      case SummaryType.action:
        return '액션';
    }
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메인 요약
          _buildSummaryCard(),

          const SizedBox(height: 16),

          // 대화 정보
          _buildConversationInfoCard(),

          const SizedBox(height: 16),

          // 핵심 주제
          _buildKeyTopicsCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '대화 요약',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () => _copyToClipboard(_summary!.summary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: _shareSummary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                _summary!.summary,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '대화 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    '참여자',
                    '${widget.conversation.speakers.length}명',
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    '발언 수',
                    '${_summary!.originalSubtitles.length}개',
                    Icons.chat_bubble,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    '단어 수',
                    '${_summary!.wordCount}개',
                    Icons.text_fields,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    '예상 시간',
                    '${_summary!.duration.inMinutes}분',
                    Icons.access_time,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[600], size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyTopicsCard() {
    if (_summary!.keyTopics.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '핵심 주제',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _summary!.keyTopics.map((topic) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    topic,
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOverallAnalysisCard(),
          const SizedBox(height: 16),
          _buildSpeakerContributionCard(),
        ],
      ),
    );
  }

  Widget _buildOverallAnalysisCard() {
    final emotionAnalysis = _summary!.emotionAnalysis;
    final overallMood = emotionAnalysis['overallMood'] ?? '중립적';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '전체 분석',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.mood, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          '전체 분위기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          overallMood,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.timeline,
                            color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          '감정 변화',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${(emotionAnalysis['emotionChanges'] as List?)?.length ?? 0}회',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerContributionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '발언 기여도',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            ..._summary!.participantAnalysis.entries.map((entry) {
              String speaker = entry.key;
              Map<String, dynamic> data = entry.value;
              int totalMessages = data['totalMessages'] ?? 0;
              double percentage =
                  (totalMessages / _summary!.originalSubtitles.length) * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          speaker,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$totalMessages회 (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getSpeakerColor(speaker),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionTab() {
    final emotionAnalysis = _summary!.emotionAnalysis;
    final emotionDistribution =
        emotionAnalysis['emotionDistribution'] as Map<String, int>? ?? {};
    final emotionChanges = emotionAnalysis['emotionChanges'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEmotionDistributionCard(emotionDistribution),
          const SizedBox(height: 16),
          _buildEmotionChangesCard(emotionChanges),
        ],
      ),
    );
  }

  Widget _buildEmotionDistributionCard(Map<String, int> emotionDistribution) {
    if (emotionDistribution.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '감정 데이터가 없습니다.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    int total = emotionDistribution.values.reduce((a, b) => a + b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '감정 분포',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            ...emotionDistribution.entries.map((entry) {
              String emotion = entry.key;
              int count = entry.value;
              double percentage = (count / total) * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getEmotionColor(emotion),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(emotion),
                          ],
                        ),
                        Text(
                          '$count회 (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getEmotionColor(emotion),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionChangesCard(List emotionChanges) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '감정 변화 순간',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            if (emotionChanges.isEmpty)
              Text(
                '감정 변화가 감지되지 않았습니다.',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...emotionChanges.take(5).map((change) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${change['time']} • ${change['speaker']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getEmotionColor(change['from']),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              change['from'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward, size: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getEmotionColor(change['to']),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              change['to'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        change['text'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _summary!.participantAnalysis.entries.map((entry) {
          return _buildParticipantCard(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildParticipantCard(String speaker, Map<String, dynamic> data) {
    int totalMessages = data['totalMessages'] ?? 0;
    int totalWords = data['totalWords'] ?? 0;
    double avgLength = data['averageMessageLength'] ?? 0;
    Map<String, int> emotions = Map<String, int>.from(data['emotions'] ?? {});

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getSpeakerColor(speaker),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      speaker.substring(2, 3),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  speaker,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('발언 수', '$totalMessages개'),
                ),
                Expanded(
                  child: _buildStatItem('총 단어', '$totalWords개'),
                ),
                Expanded(
                  child: _buildStatItem(
                      '평균 길이', '${avgLength.toStringAsFixed(1)}단어'),
                ),
              ],
            ),
            if (emotions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '주요 감정',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: emotions.entries.map((emotion) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getEmotionColor(emotion.key).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getEmotionColor(emotion.key)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${emotion.key} ${emotion.value}회',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getEmotionColor(emotion.key),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_summary!.actionItems.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '액션 아이템이 없습니다',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '대화에서 구체적인 행동 계획이나\n할 일이 언급되지 않았습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._summary!.actionItems.asMap().entries.map((entry) {
              int index = entry.key;
              String actionItem = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    actionItem,
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyToClipboard(actionItem),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

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

  Color _getEmotionColor(String emotion) {
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
      case "슬픔":
        return Colors.indigo[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('클립보드에 복사되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareSummary() {
    // Share 기능 구현 (share_plus 패키지 사용)
    // Share.share(_summary!.summary);

    // 임시로 클립보드 복사
    _copyToClipboard(_summary!.summary);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('요약이 클립보드에 복사되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
