import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../widgets/user_header.dart';
import '../models/role_slot.dart';

class MeetingDetailScreen extends StatefulWidget {
  final int meetingId;
  final int clubId;
  final String clubName;

  const MeetingDetailScreen({
    super.key,
    required this.meetingId,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  Map<String, dynamic>? _meeting;
  List<RoleSlot> _roleSlots = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Load meeting details
      final meetingResponse = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/meetings/${widget.meetingId}',
        ),
        headers: authService.authHeaders,
      );

      // Load role slots
      final rolesResponse = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/meetings/${widget.meetingId}/roles',
        ),
        headers: authService.authHeaders,
      );

      if (meetingResponse.statusCode == 200 &&
          rolesResponse.statusCode == 200) {
        final meetingData = json.decode(meetingResponse.body);
        final rolesData = json.decode(rolesResponse.body) as List<dynamic>;

        if (mounted) {
          setState(() {
            _meeting = meetingData;
            _roleSlots = rolesData.map((e) => RoleSlot.fromJson(e)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load meeting';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUpForRole(RoleSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Up for ${slot.displayName}'),
        content: const Text('Do you want to sign up for this role?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sageGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/meetings/${widget.meetingId}/roles/${slot.id}/signup',
        ),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Successfully signed up for ${slot.displayName}!'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
        _loadData();
      } else {
        final error =
            json.decode(response.body)['error'] ?? 'Failed to sign up';
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelSignUp(RoleSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Sign Up'),
        content: Text(
          'Are you sure you want to cancel your sign up for ${slot.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Sign Up'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/meetings/${widget.meetingId}/roles/${slot.id}/signup',
        ),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Sign up cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadData();
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel'),
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

  Future<void> _generateAgenda() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating Agenda...'),
          ],
        ),
      ),
    );

    try {
      // Generate download URL with auth token
      final url = Uri.parse(
        '${ApiConfig.mcpServerBaseUrl}/api/meetings/${widget.meetingId}/agenda/generate',
      );

      // For web, open in new tab with auth
      final response = await http.get(url, headers: authService.authHeaders);

      if (mounted) Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        // Download the file
        final bytes = response.bodyBytes;
        final filename =
            'Agenda_${widget.clubName}_${_meeting?['meetingDate'] ?? 'meeting'}.xlsx';

        // For web, trigger download
        _downloadFile(bytes, filename);

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Agenda downloaded!'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
      } else {
        String error = 'Failed to generate agenda';
        try {
          final data = json.decode(response.body);
          error = data['error'] ?? error;
        } catch (_) {}
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _downloadFile(List<int> bytes, String filename) {
    // For web: create blob and download using universal_html
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _deleteMeeting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除會議'),
        content: const Text('確定要刪除這個會議嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/meetings/${widget.meetingId}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.token}',
        },
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('會議已刪除')));
        navigator.pop(true); // Return true to indicate deletion
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to delete meeting');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.member?['id'] as int?;

    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: UserHeader(showBackButton: true),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMeetingHeader(),
                            const SizedBox(height: 16),
                            // Generate Agenda Button
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _generateAgenda,
                                child: HandDrawnContainer(
                                  color: AppTheme.dustyBlue.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderColor: AppTheme.dustyBlue,
                                  borderRadius: 12,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.article,
                                        color: AppTheme.dustyBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Generate Agenda',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.dustyBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Delete Meeting Button
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _deleteMeeting,
                                child: HandDrawnContainer(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderColor: Colors.red.shade300,
                                  borderRadius: 12,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.shade400,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '刪除會議',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Role Sign-Up',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkWood,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._buildRoleGroups(currentUserId),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingHeader() {
    if (_meeting == null) return const SizedBox.shrink();

    final meetingNumber = _meeting!['meetingNumber'];
    final theme = _meeting!['theme'] ?? '';
    final meetingDate = _meeting!['meetingDate'] ?? '';
    final startTime = _meeting!['startTime'] ?? '';
    final endTime = _meeting!['endTime'] ?? '';
    final location = _meeting!['location'] ?? '';
    final status = _meeting!['status'] ?? 'DRAFT';

    return HandDrawnContainer(
      color: Colors.white,
      borderColor: AppTheme.dustyBlue,
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: AppTheme.dustyBlue, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meetingNumber != null)
                      Text(
                        'Meeting #$meetingNumber',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkWood,
                        ),
                      ),
                    if (theme.isNotEmpty)
                      Text(
                        theme,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.lightWood,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.sageGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sageGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoItem(Icons.calendar_today, meetingDate),
              const SizedBox(width: 16),
              _buildInfoItem(Icons.access_time, '$startTime - $endTime'),
            ],
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoItem(Icons.location_on, location),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.lightWood),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 14, color: AppTheme.lightWood)),
      ],
    );
  }

  List<Widget> _buildRoleGroups(int? currentUserId) {
    // Group roles by category
    final staticRoles = _roleSlots
        .where((r) => !['SPEAKER', 'EVALUATOR'].contains(r.roleName))
        .toList();
    final speakers = _roleSlots.where((r) => r.roleName == 'SPEAKER').toList();
    final evaluators = _roleSlots
        .where((r) => r.roleName == 'EVALUATOR')
        .toList();

    return [
      _buildRoleSection('Meeting Roles', staticRoles, currentUserId),
      const SizedBox(height: 16),
      _buildRoleSection('Speakers', speakers, currentUserId),
      const SizedBox(height: 16),
      _buildRoleSection('Evaluators', evaluators, currentUserId),
    ];
  }

  Widget _buildRoleSection(
    String title,
    List<RoleSlot> slots,
    int? currentUserId,
  ) {
    if (slots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.lightWood,
          ),
        ),
        const SizedBox(height: 8),
        ...slots.map(
          (slot) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildRoleCard(slot, currentUserId),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(RoleSlot slot, int? currentUserId) {
    final isMe = slot.memberId == currentUserId;

    return HandDrawnContainer(
      color: slot.isAssigned
          ? (isMe
                ? AppTheme.sageGreen.withValues(alpha: 0.1)
                : Colors.grey.shade100)
          : Colors.white,
      borderColor: isMe
          ? AppTheme.sageGreen
          : AppTheme.lightWood.withValues(alpha: 0.3),
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (slot.isAssigned ? Colors.grey : AppTheme.sageGreen)
                  .withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: slot.isAssigned && slot.memberAvatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      slot.memberAvatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(slot.roleIcon, color: Colors.grey, size: 20),
                    ),
                  )
                : Icon(
                    slot.roleIcon,
                    color: slot.isAssigned ? Colors.grey : AppTheme.sageGreen,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkWood,
                  ),
                ),
                if (slot.isAssigned)
                  Text(
                    slot.memberName ?? 'Unknown',
                    style: TextStyle(fontSize: 12, color: AppTheme.lightWood),
                  )
                else
                  Text(
                    'Available',
                    style: TextStyle(fontSize: 12, color: AppTheme.sageGreen),
                  ),
              ],
            ),
          ),
          if (isMe)
            TextButton(
              onPressed: () => _cancelSignUp(slot),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel'),
            )
          else if (!slot.isAssigned)
            ElevatedButton(
              onPressed: () => _signUpForRole(slot),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sageGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Sign Up'),
            ),
        ],
      ),
    );
  }
}
