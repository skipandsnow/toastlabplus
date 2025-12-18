import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../screens/notifications_screen.dart';
import '../theme/app_theme.dart';

class UserHeader extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onMembershipChanged;
  final VoidCallback? onBack;

  const UserHeader({
    super.key,
    this.showBackButton = false,
    this.onMembershipChanged,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final member = authService.member;
    final userName = member?['name']?.split(' ').first ?? 'User';

    return Row(
      children: [
        if (showBackButton) ...[
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.darkWood),
            onPressed: onBack ?? () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 24,
            splashRadius: 24,
          ),
          const SizedBox(width: 12),
        ],
        InkWell(
          onTap: () => _showImagePicker(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.sageGreen.withValues(alpha: 0.2),
            ),
            child: member?['avatarUrl'] != null
                ? ClipOval(
                    child: Image.network(
                      member!['avatarUrl'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Avatar load error: $error');
                        return Center(
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.sageGreen,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.sageGreen,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.sageGreen,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(fontSize: 14, color: AppTheme.lightWood),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkWood,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (!showBackButton) ...[
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.lightWood.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons
                    .notifications_none_rounded, // or notifications_active_rounded
                size: 20,
                color: AppTheme.darkWood,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showImagePicker(BuildContext context) {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('從相簿選擇'),
            onTap: () async {
              Navigator.pop(ctx);
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 512,
                maxHeight: 512,
                imageQuality: 85,
              );
              if (image != null && context.mounted) {
                _uploadAvatar(context, image);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('使用相機'),
            onTap: () async {
              Navigator.pop(ctx);
              final XFile? image = await picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 512,
                maxHeight: 512,
                imageQuality: 85,
              );
              if (image != null && context.mounted) {
                _uploadAvatar(context, image);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAvatar(BuildContext context, XFile file) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await authService.uploadAvatar(file);

    if (result['success'] == true) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('頭像已更新')));
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('更新失敗: ${result['error']}')),
      );
    }
  }
}
