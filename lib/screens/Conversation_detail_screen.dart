import 'package:flutter/material.dart';
import '../models/conversation_data.dart';
import 'summary_screen.dart';

class ConversationDetailScreen extends StatelessWidget {
  final ConversationData conversation;

  const ConversationDetailScreen({
    super.key,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(conversation.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // 요약 버튼 추가
          IconButton(
            icon: const Icon(Icons.summarize),
            tooltip: '대화 요약',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SummaryScreen(conversation: conversation),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'summary':
                  _navigateToSummary(context);
                  break;
                case 'export':
                  _exportConversation(context);
                  break;
                case 'share':
                  _shareConversation(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'summary',
                child: Row(
                  children: [
                    Icon(Icons.summarize, size: 20),
                    SizedBox(width: 8),
                    Text('대화 요약'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('내보내기'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('공유하기'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 대화 정보 헤더
          _buildConversationHeader(),

          // 자막 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conversation.subtitles.length,
              itemBuilder: (context, index) {
                final subtitle = conversation.subtitles[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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
                                  color: _getEmotionBackgroundColor(
                                      subtitle.emotion),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  subtitle.emotion,
                                  style: TextStyle(
                                    color:
                                        _getEmotionTextColor(subtitle.emotion),
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToSummary(context),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI 요약'),
      ),
    );
  }

  Widget _buildConversationHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: Colors.blue[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conversation.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHeaderInfo(
                Icons.people,
                '참여자',
                '${conversation.speakers.length}명',
              ),
              const SizedBox(width: 16),
              _buildHeaderInfo(
                Icons.chat,
                '발언',
                '${conversation.subtitles.length}개',
              ),
              const SizedBox(width: 16),
              _buildHeaderInfo(
                Icons.access_time,
                '날짜',
                '${conversation.createdAt.month}/${conversation.createdAt.day}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '참여자: ${conversation.speakers.join(', ')}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.blue[600],
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToSummary(BuildContext context) {
    if (conversation.subtitles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('요약할 대화 내용이 없습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SummaryScreen(conversation: conversation),
      ),
    );
  }

  void _exportConversation(BuildContext context) {
    // 대화 내용을 텍스트 파일로 내보내기
    StringBuffer buffer = StringBuffer();
    buffer.writeln(conversation.title);
    buffer.writeln('생성일: ${conversation.createdAt}');
    buffer.writeln('참여자: ${conversation.speakers.join(', ')}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (var subtitle in conversation.subtitles) {
      buffer.writeln(
          '[${subtitle.time}] ${subtitle.speaker} (${subtitle.emotion})');
      buffer.writeln(subtitle.text);
      buffer.writeln();
    }

    // 실제로는 file_picker나 share_plus 패키지를 사용
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('내보내기 기능이 곧 업데이트될 예정입니다.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareConversation(BuildContext context) {
    // 대화 요약 내용 공유
    StringBuffer shareText = StringBuffer();
    shareText.writeln('📝 ${conversation.title}');
    shareText.writeln('👥 참여자: ${conversation.speakers.join(', ')}');
    shareText.writeln('💬 발언 수: ${conversation.subtitles.length}개');
    shareText.writeln();

    // 첫 3개 발언만 미리보기로 포함
    for (int i = 0; i < 3 && i < conversation.subtitles.length; i++) {
      var subtitle = conversation.subtitles[i];
      shareText.writeln('${subtitle.speaker}: ${subtitle.text}');
    }

    if (conversation.subtitles.length > 3) {
      shareText.writeln('...');
    }

    shareText.writeln();
    shareText.writeln('🎯 마일스톤 앱으로 생성된 대화 기록');

    // 실제로는 share_plus 패키지 사용
    // Share.share(shareText.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('공유 기능이 곧 업데이트될 예정입니다.'),
        backgroundColor: Colors.green,
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
      case "슬픔":
        return Colors.indigo[600]!;
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
      case "슬픔":
        return Colors.indigo[50]!;
      default:
        return Colors.grey[50]!;
    }
  }
}
