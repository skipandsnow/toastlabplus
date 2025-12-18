import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';

import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../widgets/user_header.dart';
import 'admin_approval_screen.dart';
import 'member_selection_screen.dart';
import 'edit_club_info_screen.dart';
import 'club_members_list_screen.dart';
import 'officer_management_screen.dart';
import 'meeting_settings_screen.dart';
import 'template_management_screen.dart';

class ClubDetailManagementScreen extends StatefulWidget {
  final int clubId;
  final String clubName;

  const ClubDetailManagementScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubDetailManagementScreen> createState() =>
      _ClubDetailManagementScreenState();
}

class _ClubDetailManagementScreenState
    extends State<ClubDetailManagementScreen> {
  late String _clubName;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _clubName = widget.clubName;
  }

  Future<void> _assignClubAdmin(BuildContext context) async {
    // Navigate to selection screen which handles the assignment internally
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MemberSelectionScreen(clubId: widget.clubId, clubName: _clubName),
      ),
    );

    if (success == true && context.mounted) {
      // Optional: Reload data or show another confirmation if needed.
    }
  }

  Future<void> _showDeleteClubDialog(BuildContext context) async {
    // Capture context-dependent objects before async gaps
    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Delete Club', textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This action cannot be undone. All club data, memberships, and admin assignments will be permanently deleted.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            Text(
              'To confirm deletion, please type the exact club name:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '"$_clubName"',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: 'Enter club name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (confirmController.text == _clubName) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Club name does not match'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    confirmController.dispose();
    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubsEndpoint}/${widget.clubId}',
        ),
        headers: {
          ...authService.authHeaders,
          'Content-Type': 'application/json',
        },
        body: json.encode({'confirmName': _clubName}),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Club "$_clubName" deleted successfully'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
        // Pop back to Home
        navigator.pop(true);
      } else {
        final data = json.decode(response.body);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to delete club'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: UserHeader(
                showBackButton: true,
                onBack: () {
                  debugPrint(
                    'ClubDetailManagementScreen: onBack called, _hasChanges=$_hasChanges',
                  );
                  Navigator.of(context).pop(_hasChanges);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.business, color: AppTheme.darkWood, size: 28),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _clubName,
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
                      final newClubName = await Navigator.push<String?>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditClubInfoScreen(
                            clubId: widget.clubId,
                            clubName: _clubName,
                          ),
                        ),
                      );
                      if (newClubName != null && context.mounted) {
                        setState(() {
                          _clubName = newClubName;
                          _hasChanges = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Club info updated!')),
                        );
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
                            clubId: widget.clubId,
                            clubName: _clubName,
                          ),
                        ),
                      );
                    },
                    description: 'Review pending applications',
                  ),
                  const SizedBox(height: 16),
                  _buildManagementOption(
                    context,
                    'Members List',
                    Icons.people,
                    AppTheme.dustyBlue,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClubMembersListScreen(
                            clubId: widget.clubId,
                            clubName: _clubName,
                          ),
                        ),
                      );
                    },
                    description: 'View all club members',
                  ),
                  const SizedBox(height: 16),
                  _buildManagementOption(
                    context,
                    'Officers',
                    Icons.badge,
                    Colors.purple.shade400,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OfficerManagementScreen(
                            clubId: widget.clubId,
                            clubName: _clubName,
                          ),
                        ),
                      );
                    },
                    description: 'Manage club officer positions',
                  ),
                  const SizedBox(height: 16),
                  _buildManagementOption(
                    context,
                    'Agenda Templates',
                    Icons.description,
                    Colors.orange.shade400,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TemplateManagementScreen(
                            clubId: widget.clubId,
                            clubName: _clubName,
                          ),
                        ),
                      );
                    },
                    description: 'Manage agenda templates',
                  ),
                  const SizedBox(height: 16),
                  _buildManagementOption(
                    context,
                    'Meeting Settings',
                    Icons.settings_suggest,
                    AppTheme.softPeach,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MeetingSettingsScreen(
                            clubId: widget.clubId,
                            clubName: _clubName,
                          ),
                        ),
                      );
                    },
                  ),
                  // Delete Club (Platform Admin only)
                  if (isPlatformAdmin) ...[
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildManagementOption(
                      context,
                      'Delete Club',
                      Icons.delete_forever,
                      Colors.red,
                      () => _showDeleteClubDialog(context),
                      description: 'Permanently delete this club',
                    ),
                  ],
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
