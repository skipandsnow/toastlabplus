import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_version.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final member = authService.member;
    final name = member?['name'] ?? 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      body: CustomPaint(
        painter: CloudBackgroundPainter(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
          child: Column(
            children: [
              // Profile Header Card
              HandDrawnContainer(
                color: Colors.white,
                borderColor: AppTheme.lightWood.withValues(alpha: 0.2),
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.sageGreen.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.sageGreen.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: member?['avatarUrl'] != null
                          ? ClipOval(
                              child: Image.network(
                                member!['avatarUrl'],
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.sageGreen,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.sageGreen,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkWood,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Stats
              Row(
                children: [
                  _buildStatCard('Meetings', '0', AppTheme.sageGreen),
                  const SizedBox(width: 16),
                  _buildStatCard('Speeches', '0', AppTheme.dustyBlue),
                  const SizedBox(width: 16),
                  _buildStatCard('Badges', '0', AppTheme.softPeach),
                ],
              ),
              const SizedBox(height: 32),

              // Menu Options
              _buildMenuOption(Icons.history_rounded, 'History', () {}),
              const SizedBox(height: 16),
              _buildMenuOption(
                Icons.lock_outline_rounded,
                'Change Password',
                () {
                  _showChangePasswordDialog(context, authService);
                },
              ),
              const SizedBox(height: 16),
              _buildMenuOption(Icons.settings_rounded, 'Settings', () {}),
              const SizedBox(height: 16),
              _buildMenuOption(
                Icons.help_outline_rounded,
                'Help & Support',
                () {},
              ),
              const SizedBox(height: 16),
              _buildMenuOption(
                Icons.info_outline_rounded,
                'About & Release Notes',
                () => _showAboutDialog(context),
              ),
              const SizedBox(height: 32),

              // Logout Button
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      alignment: Alignment.topCenter,
                      insetPadding: const EdgeInsets.only(
                        top: 80,
                        left: 24,
                        right: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Confirm logout?',
                        textAlign: TextAlign.center,
                      ),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await authService.logout();
                    // Consumer in main.dart will automatically rebuild
                  }
                },
                icon: Icon(Icons.logout, color: Colors.red.shade400, size: 20),
                label: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    AuthService authService,
  ) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: AppTheme.sageGreen),
              const SizedBox(width: 8),
              const Text('Change Password'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sageGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() => isLoading = true);

                      try {
                        await authService.changePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Password changed successfully',
                              ),
                              backgroundColor: AppTheme.sageGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.sageGreen),
            const SizedBox(width: 8),
            const Text('About ToastLab+'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.sageGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.new_releases_outlined,
                      color: AppTheme.sageGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppVersion.displayFull,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkWood,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Release Notes Title
              Text(
                'Release Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkWood,
                ),
              ),
              const Divider(),

              // v0.1.4
              _buildReleaseNote('v0.1.4', '2025-12-19', [
                '✨ 新增版本資訊與 Release Notes 頁面',
                '✨ 登入頁面顯示版本與版權',
                '🐛 修正未正確顯示當前 Club Admin',
                '🐛 修正 Club 更新後 UI 未刷新問題',
                '🐛 修正 Snackbar 重複顯示問題',
                '🐛 修正 Remove Club Admin API 錯誤',
              ]),

              // v0.1.3
              _buildReleaseNote('v0.1.3', '2025-12-18', [
                '✨ iOS App Store 部署',
                '✨ GitHub Actions 自動化部署',
                '✨ Web favicon 更新',
              ]),

              // v0.1.2
              _buildReleaseNote('v0.1.2', '2025-12-18', [
                '✨ Meeting Schedule 編輯功能',
                '✨ Agenda 動態 Speaker 行優化',
                '✨ 時間格式統一與 UI 翻譯',
              ]),

              // v0.1.1
              _buildReleaseNote('v0.1.1', '2025-12-17', [
                '🚀 Cloud Run 雙環境部署',
                '✨ Staging/Production 資料庫隔離',
                '✨ 前端轉場效能優化',
              ]),

              // v0.1.0
              _buildReleaseNote('v0.1.0', '2025-12-16', [
                '🎉 會議管理與 Agenda 產生功能',
                '✨ AI 模板解析與角色報名',
                '✨ 全新 UI 風格設計',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseNote(String version, String date, List<String> changes) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                version,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dustyBlue,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(fontSize: 12, color: AppTheme.lightWood),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...changes.map(
            (change) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                change,
                style: TextStyle(fontSize: 13, color: AppTheme.darkWood),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: HandDrawnContainer(
        color: Colors.white,
        borderColor: color.withValues(alpha: 0.3),
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppTheme.lightWood),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap) {
    return HandDrawnContainer(
      color: Colors.white,
      borderColor: AppTheme.lightWood.withValues(alpha: 0.2),
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.sageGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.sageGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkWood,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppTheme.lightWood,
            size: 16,
          ),
        ],
      ),
    );
  }
}
