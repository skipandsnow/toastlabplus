import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../widgets/user_header.dart';
import 'admin_approval_screen.dart';
import 'member_selection_screen.dart';
import 'edit_club_info_screen.dart';

class ClubDetailManagementScreen extends StatelessWidget {
  final int clubId;
  final String clubName;

  const ClubDetailManagementScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  Future<void> _assignClubAdmin(BuildContext context) async {
    // Navigate to selection screen which handles the assignment internally
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MemberSelectionScreen(clubId: clubId, clubName: clubName),
      ),
    );

    if (success == true && context.mounted) {
      // Optional: Reload data or show another confirmation if needed.
      // The Selection Screen already showed a SnackBar.
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final member = authService.member;
    final role = member?['role'] ?? 'MEMBER';
    final isPlatformAdmin = role == 'PLATFORM_ADMIN';

    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: UserHeader(showBackButton: true),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.business, color: AppTheme.darkWood, size: 28),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      clubName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkWood,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.dustyBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Club Admin',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dustyBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (isPlatformAdmin)
                    _buildManagementOption(
                      context,
                      'Assign Club Admin',
                      Icons.supervisor_account,
                      AppTheme.sageGreen,
                      () => _assignClubAdmin(context),
                      description: 'Select a member to manage this club',
                    ),
                  if (isPlatformAdmin) const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  _buildManagementOption(
                    context,
                    'Edit Club Info',
                    Icons.edit_note,
                    AppTheme.dustyBlue,
                    () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditClubInfoScreen(
                            clubId: clubId,
                            clubName: clubName,
                          ),
                        ),
                      );
                      if (updated == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Club info updated. Please refresh list.',
                            ),
                          ),
                        );
                        // Ideally we should tell HomeScreen to refresh or refresh local state if this was Stateful
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildManagementOption(
                    context,
                    'Member Approval',
                    Icons.person_add,
                    AppTheme.sageGreen,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminApprovalScreen(
                            clubId: clubId,
                            clubName: clubName,
                          ),
                        ),
                      );
                    },
                    description: 'Review pending applications',
                  ),
                  const SizedBox(height: 16),
                  _buildManagementOption(
                    context,
                    'Make Agenda',
                    Icons.edit_calendar,
                    Colors.orange.shade400,
                    () {
                      // TODO: Implement Make Agenda
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Make Agenda is coming soon!'),
                        ),
                      );
                    },
                    description: 'Create new meeting program',
                  ),
                  const SizedBox(height: 16),
                  _buildManagementOption(
                    context,
                    'Meeting Settings',
                    Icons.settings_suggest,
                    AppTheme.softPeach,
                    () {
                      // TODO: Implement Meeting Settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Meeting Settings is coming soon!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? description,
  }) {
    return HandDrawnContainer(
      color: Colors.white,
      borderColor: color,
      borderRadius: 16,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkWood,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: AppTheme.lightWood),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.lightWood),
        ],
      ),
    );
  }
}
