import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../services/auth_service.dart';
import 'roles_screen.dart';
import 'admin_approval_screen.dart';
import 'admin_club_select_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onChatSelected;
  final VoidCallback onSettingsSelected;

  const HomeScreen({
    super.key,
    required this.onChatSelected,
    required this.onSettingsSelected,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final member = authService.member;
    final userName = member?['name']?.split(' ').first ?? 'User';
    final role = member?['role'] ?? 'MEMBER';
    final clubId = member?['clubId'] as int?;
    final clubName = member?['clubName'] as String? ?? 'My Club';
    final isAdmin = role == 'CLUB_ADMIN' || role == 'PLATFORM_ADMIN';

    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      body: CustomPaint(
        painter: CloudBackgroundPainter(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.sageGreen.withValues(
                        alpha: 0.2,
                      ),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.sageGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.lightWood,
                          ),
                        ),
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkWood,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppTheme.dustyBlue.withOpacity(0.2)
                            : AppTheme.sageGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        role == 'PLATFORM_ADMIN'
                            ? 'Platform Admin'
                            : role == 'CLUB_ADMIN'
                            ? 'Club Admin'
                            : 'Member',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAdmin
                              ? AppTheme.dustyBlue
                              : AppTheme.sageGreen,
                        ),
                      ),
                    ),
                  ],
                ),

                // Admin Approval Card (for all admins)
                if (isAdmin) ...[
                  const SizedBox(height: 20),
                  HandDrawnContainer(
                    color: AppTheme.dustyBlue.withOpacity(0.1),
                    borderColor: AppTheme.dustyBlue,
                    borderRadius: 16,
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      if (clubId != null) {
                        // Club Admin - go directly to approval screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminApprovalScreen(
                              clubId: clubId,
                              clubName: clubName,
                            ),
                          ),
                        );
                      } else {
                        // Platform Admin - select club first
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminClubSelectScreen(),
                          ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.dustyBlue.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_add,
                            color: AppTheme.dustyBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Member Approval',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkWood,
                                ),
                              ),
                              Text(
                                clubId != null
                                    ? 'Review pending member applications'
                                    : 'Select a club to approve',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.lightWood,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppTheme.lightWood,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Main "Make Agenda" Card - Refined
                HandDrawnContainer(
                  color: const Color(0xFFF1F8E9), // Very light green
                  borderColor: AppTheme.sageGreen,
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  onTap: () {},
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.sageGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Next Meeting',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Make Agenda',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkWood,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create new program',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.lightWood,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_calendar_rounded,
                        size: 48,
                        color: AppTheme.sageGreen.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Menu', // Keep English as design choice
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkWood,
                  ),
                ),
                const SizedBox(height: 16),

                // Tightly grouped buttons (Center aligned as per latest fix)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMenuButton(
                      context,
                      'Club Info',
                      Icons.storefront_rounded,
                      AppTheme.dustyBlue,
                      onTap: () {
                        // TODO: Navigate to club info
                      },
                    ),
                    const SizedBox(width: 16), // Tighter spacing
                    _buildMenuButton(
                      context,
                      'Roles',
                      Icons.groups_rounded,
                      AppTheme.sageGreen,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RolesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildMenuButton(
                      context,
                      'Voting',
                      Icons.how_to_vote_rounded,
                      AppTheme.softPeach,
                      onTap: () {
                        // TODO: Navigate to voting
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Upcoming Section (Production Feature)
                Text(
                  'Coming Up',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkWood,
                  ),
                ),
                const SizedBox(height: 16),
                HandDrawnContainer(
                  color: Colors.white,
                  borderColor: AppTheme.lightWood.withValues(alpha: 0.3),
                  borderRadius: 20,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.softYellow.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_note_rounded,
                          color: AppTheme.darkWood.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Speech Contest',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkWood,
                            ),
                          ),
                          Text(
                            'Dec 20 • 19:00',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.lightWood,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        HandDrawnContainer(
          color: color.withValues(alpha: 0.15),
          borderColor: color.withValues(alpha: 0.5), // Softer border
          borderRadius: 22, // Squircle
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: SizedBox(
            width: 80,
            height: 80,
            child: Center(child: Icon(icon, color: color, size: 32)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkWood,
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}
