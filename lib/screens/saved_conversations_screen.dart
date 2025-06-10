import 'package:flutter/material.dart';
import '../models/conversation_data.dart';
import '../models/subtitle_data.dart';
import 'conversation_detail_screen.dart';

class SavedConversationsScreen extends StatefulWidget {
  final List<ConversationData> conversations;

  const SavedConversationsScreen({
    super.key,
    required this.conversations,
  });

  @override
  _SavedConversationsScreenState createState() =>
      _SavedConversationsScreenState();
}

class _SavedConversationsScreenState extends State<SavedConversationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('저장된 대화'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: widget.conversations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.conversations.length,
              itemBuilder: (context, index) {
                return _buildConversationCard(
                    widget.conversations[index], index);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '저장된 대화가 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '메인 화면에서 대화를 저장해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(ConversationData conversation, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showConversationDetail(conversation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목과 날짜
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      conversation.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteConversation(index),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 발언 수와 참여자
              Text(
                '${conversation.subtitles.length}개 발언 • ${conversation.speakers.join(', ')}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 8),

              // 첫 번째 발언 미리보기
              if (conversation.subtitles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${conversation.subtitles.first.speaker}: ${conversation.subtitles.first.text}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConversationDetail(ConversationData conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ConversationDetailScreen(conversation: conversation),
      ),
    );
  }

  void _deleteConversation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대화 삭제'),
        content: const Text('이 대화를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.conversations.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('대화가 삭제되었습니다.')),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
