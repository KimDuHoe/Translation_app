import 'package:flutter/material.dart';

// 이곳은 환경설정창 만드는 곳

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool soundEnabled = true;
  bool vibrationEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('환경설정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 사용자 프로필 섹션
            _buildUserProfileSection(),

            const SizedBox(height: 16),

            // 알림 설정 섹션
            _buildNotificationSection(),

            const SizedBox(height: 16),

            // 계정 관리 섹션
            _buildAccountSection(),

            const SizedBox(height: 16),

            // 고객 지원 섹션
            _buildSupportSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 프로필 이미지
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.purple[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '김',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 사용자 정보
          Text(
            '김두회',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'duhoe.kim@example.com',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 16),

          // 편집 버튼
          OutlinedButton(
            onPressed: () {
              _showProfileEditDialog();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              '프로필 편집',
              style: TextStyle(color: Colors.blue[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '알림 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          _buildSwitchItem(
            icon: Icons.notifications,
            title: '푸시 알림',
            subtitle: '새로운 기능 및 업데이트 알림',
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildSwitchItem(
            icon: Icons.volume_up,
            title: '소리 알림',
            subtitle: '자막 생성 시 알림음',
            value: soundEnabled,
            onChanged: (value) {
              setState(() {
                soundEnabled = value;
              });
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildSwitchItem(
            icon: Icons.vibration,
            title: '진동 알림',
            subtitle: '중요한 알림 시 진동',
            value: vibrationEnabled,
            onChanged: (value) {
              setState(() {
                vibrationEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '계정 관리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          _buildSettingsItem(
            icon: Icons.person,
            title: '내 계정',
            subtitle: '개인정보 및 계정 설정',
            onTap: () {
              _showAccountInfo();
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildSettingsItem(
            icon: Icons.credit_card,
            title: '플랜 및 결제',
            subtitle: '구독 플랜 관리 및 결제 정보',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PRO',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              _showPlanInfo();
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildSettingsItem(
            icon: Icons.security,
            title: '보안 설정',
            subtitle: '비밀번호 변경 및 보안 옵션',
            onTap: () {
              _showSecuritySettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '고객 지원',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: '도움말',
            subtitle: '사용법 및 자주 묻는 질문',
            onTap: () {
              _showHelpDialog();
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildSettingsItem(
            icon: Icons.chat_bubble_outline,
            title: '고객 지원',
            subtitle: '문의사항 및 기술 지원',
            onTap: () {
              _showSupportDialog();
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildSettingsItem(
            icon: Icons.star_outline,
            title: '앱 평가하기',
            subtitle: '스토어에서 마일스톤 평가하기',
            onTap: () {
              _showRatingDialog();
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: '앱 정보',
            subtitle: '버전 정보 및 라이선스',
            trailing: Text(
              'v1.0.0',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            onTap: () {
              _showAppInfo();
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildSettingsItem(
            icon: Icons.logout,
            title: '로그아웃',
            subtitle: '계정에서 로그아웃',
            titleColor: Colors.red[600],
            onTap: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.blue[600],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue[600],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: titleColor == null ? Colors.blue[50] : Colors.red[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: titleColor ?? Colors.blue[600],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: titleColor ?? Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
      onTap: onTap,
    );
  }

  // 다이얼로그 메서드들
  void _showProfileEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('프로필 편집'),
        content: const Text('프로필 편집 기능이 곧 업데이트될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(color: Colors.blue[600])),
          ),
        ],
      ),
    );
  }

  void _showAccountInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('내 계정'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이름: 김두회'),
            SizedBox(height: 8),
            Text('이메일: kim@example.com'),
            SizedBox(height: 8),
            Text('가입일: 2024.01.15'),
            SizedBox(height: 8),
            Text('계정 유형: PRO'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(color: Colors.blue[600])),
          ),
        ],
      ),
    );
  }

  void _showPlanInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('플랜 정보'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현재 플랜: PRO', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('• 무제한 실시간 자막'),
            Text('• 감정 분석 기능'),
            Text('• 화자 구분 기능'),
            Text('• 자막 저장 및 요약'),
            Text('• 우선 고객 지원'),
            SizedBox(height: 12),
            Text('다음 결제일: 2024.07.15'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(color: Colors.blue[600])),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('보안 설정'),
        content: const Text(
            '보안 설정 기능이 곧 업데이트될 예정입니다.\n\n• 비밀번호 변경\n• 2단계 인증\n• 로그인 기록'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(color: Colors.blue[600])),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('도움말'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('자주 묻는 질문:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Q: 음성 인식이 정확하지 않아요'),
              Text('A: 마이크에 가까이서 또렷하게 말씀해주세요.'),
              SizedBox(height: 8),
              Text('Q: 화자 구분이 안 돼요'),
              Text('A: 각 화자가 차례로 말할 때 가장 정확합니다.'),
              SizedBox(height: 8),
              Text('Q: 감정 분석이 틀려요'),
              Text('A: 음성의 억양과 톤을 기반으로 분석합니다.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(color: Colors.blue[600])),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('고객 지원'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('문의 방법:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('📧 이메일: support@milestone.kr'),
            Text('📞 전화: 1588-2222'),
            Text('💬 카카오톡: @마일스톤'),
            SizedBox(height: 12),
            Text('운영시간: 평일 09:00-18:00'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(color: Colors.blue[600])),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('앱 평가하기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('마일스톤이 도움이 되셨나요?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (index) =>
                      const Icon(Icons.star, color: Colors.amber, size: 30)),
            ),
            const SizedBox(height: 16),
            const Text('앱스토어로 이동하여 평가해주세요!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('나중에', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('평가하기', style: TextStyle(color: Colors.blue[600])),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('앱 정보'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('마일스톤 v1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('청각장애인을 위한 스마트 음성 보조 시스템'),
            SizedBox(height: 12),
            Text('개발: 마일스톤 팀'),
            Text('• 김주영 (202223518)'),
            Text('• 김서중 (202022058)'),
            Text('• 김두회 (201923275)'),
            Text('• 목경빈 (201923191)'),
            SizedBox(height: 12),
            Text('© 2024 마일스톤. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인', style: TextStyle(color: Colors.blue[600])),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('로그아웃'),
          content: const Text('정말로 로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text(
                '로그아웃',
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
          ],
        );
      },
    );
  }
}
