import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> _showFormatSelectionDialog() async {
    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Export Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose the file format for the agenda:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, 'excel'),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Excel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppTheme.sageGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, 'pdf'),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppTheme.dustyBlue),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (format != null) {
      await _generateAgenda(format);
    }
  }

  Future<void> _generateAgenda(String format) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Generating ${format.toUpperCase()}...'),
          ],
        ),
      ),
    );

    try {
      // Generate download URL with auth token and format
      final url = Uri.parse(
        '${ApiConfig.mcpServerBaseUrl}/api/meetings/${widget.meetingId}/agenda/generate?format=$format',
      );

      final response = await http.get(url, headers: authService.authHeaders);

      if (mounted) Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        // Download the file
        final bytes = response.bodyBytes;
        final extension = format == 'pdf' ? 'pdf' : 'xlsx';
        final filename =
            'Agenda_${widget.clubName}_${_meeting?['meetingDate'] ?? 'meeting'}.$extension';

        // For web, trigger download; for mobile, share
        await _downloadFile(bytes, filename);

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Agenda ${format.toUpperCase()} downloaded!'),
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

  Future<void> _downloadFile(List<int> bytes, String filename) async {
    if (kIsWeb) {
      // Web: create blob and download using universal_html
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // iOS/Android: save to temp directory and share
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);

      // Use share_plus to open share sheet
      // sharePositionOrigin is required on iPad
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Agenda',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : const Rect.fromLTWH(0, 0, 100, 100),
      );
    }
  }

  /// Check if current user is admin
  bool _isAdmin() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final member = authService.member;
    final role = member?['role'] ?? 'MEMBER';
    return role == 'PLATFORM_ADMIN' || role == 'CLUB_ADMIN';
  }

  /// Show dialog to edit meeting theme
  Future<void> _showEditThemeDialog() async {
    final controller = TextEditingController(text: _meeting?['theme'] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Meeting Theme'),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width * 0.8,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Theme',
              hintText:
                  'e.g. Leadership Journey\nDescribe the meeting theme...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            maxLines: 10,
            minLines: 5,
            maxLength: 200,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sageGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final response = await http.patch(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/meetings/${widget.meetingId}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.token}',
        },
        body: json.encode({'theme': result}),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Theme updated!'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
        _loadData();
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to update theme'),
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

  /// Show dialog to assign a member to a role (Admin only)
  Future<void> _showAssignMemberDialog(RoleSlot slot) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Load club members
    List<dynamic> members = [];
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/club-memberships/club/${widget.clubId}',
        ),
        headers: authService.authHeaders,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        members = data.where((m) => m['status'] == 'APPROVED').toList();
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error loading members: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    final selectedMember = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Assign ${slot.displayName}'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: members.isEmpty
              ? const Center(child: Text('No members found'))
              : ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (_, index) {
                    final m = members[index];
                    final member = m['member'] as Map<String, dynamic>?;
                    final name = member?['name'] ?? 'Unknown';
                    final email = member?['email'] ?? '';
                    final memberId = member?['id'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.sageGreen.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          name[0].toUpperCase(),
                          style: TextStyle(color: AppTheme.sageGreen),
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text(email),
                      onTap: () => Navigator.pop(ctx, {
                        'memberId': memberId,
                        'memberName': name,
                      }),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedMember == null) return;

    // Call assign API
    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/meetings/${widget.meetingId}/roles/${slot.id}/assign',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.token}',
        },
        body: json.encode({'memberId': selectedMember['memberId']}),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              '${selectedMember['memberName']} assigned to ${slot.displayName}!',
            ),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
        _loadData();
      } else {
        final error = json.decode(response.body)['error'] ?? 'Failed to assign';
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

  Future<void> _deleteMeeting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Meeting'),
        content: const Text(
          'Are you sure you want to delete this meeting? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Meeting deleted')),
        );
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
                                onTap: _showFormatSelectionDialog,
                                child: HandDrawnContainer(
                                  color: AppTheme.sageGreen.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderColor: AppTheme.sageGreen,
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
                                        color: AppTheme.sageGreen,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Generate Agenda',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.sageGreen,
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
                                        'Delete Meeting',
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
    final rawStartTime = _meeting!['startTime'] ?? '';
    final rawEndTime = _meeting!['endTime'] ?? '';
    final startTime = rawStartTime.length >= 5
        ? rawStartTime.substring(0, 5)
        : rawStartTime;
    final endTime = rawEndTime.length >= 5
        ? rawEndTime.substring(0, 5)
        : rawEndTime;
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
              // Edit theme button (Admin only)
              if (_isAdmin())
                IconButton(
                  onPressed: _showEditThemeDialog,
                  icon: Icon(Icons.edit, color: AppTheme.dustyBlue, size: 20),
                  tooltip: 'Edit Theme',
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
          // Cancel button: show for self OR for admin when someone is assigned
          if (isMe || (slot.isAssigned && _isAdmin()))
            TextButton(
              onPressed: () => _cancelSignUp(slot),
              style: TextButton.styleFrom(foregroundColor: AppTheme.lightWood),
              child: const Text('Cancel'),
            )
          else if (!slot.isAssigned) ...[
            ElevatedButton(
              onPressed: () => _signUpForRole(slot),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sageGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Sign Up'),
            ),
            // Admin assign button
            if (_isAdmin())
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconButton(
                  onPressed: () => _showAssignMemberDialog(slot),
                  icon: Icon(
                    Icons.person_add,
                    color: AppTheme.dustyBlue,
                    size: 20,
                  ),
                  tooltip: 'Assign Member',
                ),
              ),
          ],
        ],
      ),
    );
  }
}
