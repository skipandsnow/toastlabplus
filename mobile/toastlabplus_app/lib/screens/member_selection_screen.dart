import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';

class MemberSelectionScreen extends StatefulWidget {
  final int clubId;
  final String clubName;

  const MemberSelectionScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<MemberSelectionScreen> createState() => _MemberSelectionScreenState();
}

class _MemberSelectionScreenState extends State<MemberSelectionScreen> {
  List<dynamic> _members = [];
  Set<int> _currentAdminIds = {}; // Track current admins for this club
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Fetch members and current admins in parallel
      final membersResponse = await http.get(
        Uri.parse('${ApiConfig.mcpServerBaseUrl}/api/members'),
        headers: authService.authHeaders,
      );

      final adminsResponse = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/admins',
        ),
        headers: authService.authHeaders,
      );

      if (membersResponse.statusCode == 200) {
        if (mounted) {
          final allMembers = json.decode(membersResponse.body) as List<dynamic>;

          // Parse current admin IDs from admins response
          Set<int> adminIds = {};
          if (adminsResponse.statusCode == 200) {
            final admins = json.decode(adminsResponse.body) as List<dynamic>;
            adminIds = admins.map((a) => a['memberId'] as int).toSet();
          }

          setState(() {
            _members = allMembers
                .where((m) => m['role'] != 'PLATFORM_ADMIN')
                .toList();
            _currentAdminIds = adminIds;
          });
        }
      } else {
        throw Exception(
          'Failed to load members: ${membersResponse.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleMemberTap(Map<String, dynamic> member) async {
    final memberName = member['name'] ?? 'Unknown';
    final memberId = member['id'];

    // 1. Show Confirmation Dialog inside this screen
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Assignment'),
        content: Text(
          'Assign "$memberName" as Admin for "${widget.clubName}"?\n\nThey will be moved to this club and given Admin role.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Assign',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.sageGreen,
              ),
            ),
          ),
        ],
      ),
    );

    // If cancelled, do nothing (stay on screen)
    if (confirm != true || !mounted) return;

    // 2. Perform Assignment
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/members/$memberId/assign-club-admin',
        ),
        headers: {
          ...authService.authHeaders,
          'Content-Type': 'application/json',
        },
        body: json.encode({'clubId': widget.clubId}),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (response.statusCode == 200) {
          // Success Message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully assigned $memberName as Club Admin!'),
            ),
          );
          // 3. Refresh list instead of popping
          _loadMembers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to assign: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      appBar: AppBar(
        title: Text(
          'Select New Admin',
          style: TextStyle(color: AppTheme.darkWood),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkWood),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text('Error: $_error'))
            : _members.isEmpty
            ? const Center(child: Text('No members found.'))
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: _members.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final memberId = (member['id'] as int?) ?? 0;
                  final name = member['name'] ?? 'Unknown';
                  final email = member['email'] ?? '';
                  // Handle dynamic role types safely
                  final role = member['role']?.toString() ?? 'MEMBER';
                  final clubName = member['clubName']?.toString() ?? 'No Club';

                  // Check if this member is current admin via the fetched admin list
                  final isCurrentAdmin =
                      memberId > 0 && _currentAdminIds.contains(memberId);

                  return HandDrawnContainer(
                    color: isCurrentAdmin
                        ? AppTheme.sageGreen.withValues(alpha: 0.1)
                        : Colors.white,
                    borderColor: isCurrentAdmin
                        ? AppTheme.sageGreen
                        : AppTheme.lightWood,
                    onTap: () => isCurrentAdmin
                        ? _handleRemoveAdmin(member)
                        : _handleMemberTap(member),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCurrentAdmin
                                  ? AppTheme.sageGreen.withValues(alpha: 0.2)
                                  : AppTheme.softPeach.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCurrentAdmin ? Icons.star : Icons.person,
                              color: isCurrentAdmin
                                  ? AppTheme.sageGreen
                                  : AppTheme.darkWood,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkWood,
                                  ),
                                ),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.lightWood,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (isCurrentAdmin)
                                      _buildBadge(
                                        'CURRENT ADMIN',
                                        AppTheme.sageGreen,
                                      )
                                    else ...[
                                      _buildBadge(role, Colors.blueGrey),
                                      if (clubName != 'No Club')
                                        _buildBadge(
                                          clubName,
                                          AppTheme.sageGreen,
                                        ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isCurrentAdmin
                                ? Icons.remove_circle_outline
                                : Icons.touch_app,
                            color: isCurrentAdmin
                                ? Colors.red.shade400
                                : AppTheme.sageGreen,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _handleRemoveAdmin(Map<String, dynamic> member) async {
    final memberName = member['name'] ?? 'Unknown';
    final memberId = member['id'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Admin Role'),
        content: Text(
          'Are you sure you want to remove "$memberName" from Admin role for "${widget.clubName}"?\n\nThey will become a regular Member of this club.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade400,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/members/$memberId/remove-club-admin',
        ),
        headers: {
          ...authService.authHeaders,
          'Content-Type': 'application/json',
        },
        body: json.encode({'clubId': widget.clubId}),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed Admin role from "$memberName"')),
          );
          _loadMembers(); // Reload list to update UI
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
