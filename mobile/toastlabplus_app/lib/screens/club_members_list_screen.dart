import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../widgets/user_header.dart';

class ClubMembersListScreen extends StatefulWidget {
  final int clubId;
  final String clubName;
  final bool readOnly;

  const ClubMembersListScreen({
    super.key,
    required this.clubId,
    required this.clubName,
    this.readOnly = false,
  });

  @override
  State<ClubMembersListScreen> createState() => _ClubMembersListScreenState();
}

class _ClubMembersListScreenState extends State<ClubMembersListScreen> {
  List<dynamic> _members = [];
  List<int> _clubAdminIds = [];
  Map<int, String> _memberOfficerPositions = {}; // memberId -> position display
  bool _isLoading = true;
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

      // Load club members via club-memberships API (accessible to all authenticated users)
      final membersResponse = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubMembershipsEndpoint}/club/${widget.clubId}',
        ),
        headers: authService.authHeaders,
      );

      // Load club admins
      final adminsResponse = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/admins',
        ),
        headers: authService.authHeaders,
      );

      // Load officers
      final officersResponse = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/officers',
        ),
        headers: authService.authHeaders,
      );

      if (membersResponse.statusCode == 200) {
        final memberships = json.decode(membersResponse.body) as List<dynamic>;
        // Filter only APPROVED memberships and extract member data
        final approvedMembers = memberships
            .where((m) => m['status'] == 'APPROVED')
            .map((m) => m['member'] as Map<String, dynamic>)
            .toList();

        List<int> adminIds = [];
        if (adminsResponse.statusCode == 200) {
          final admins = json.decode(adminsResponse.body) as List<dynamic>;
          adminIds = admins.map((a) => a['memberId'] as int).toList();
        }

        // Build officer positions map
        Map<int, String> officerPositions = {};
        if (officersResponse.statusCode == 200) {
          final officers = json.decode(officersResponse.body) as List<dynamic>;
          for (final officer in officers) {
            if (officer['isFilled'] == true && officer['memberId'] != null) {
              officerPositions[officer['memberId'] as int] =
                  officer['positionDisplay'] as String;
            }
          }
        }

        if (mounted) {
          setState(() {
            _members = approvedMembers;
            _clubAdminIds = adminIds;
            _memberOfficerPositions = officerPositions;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load members';
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

  String _getRoleLabel(String role) {
    switch (role) {
      case 'PLATFORM_ADMIN':
        return 'Platform Admin';
      case 'CLUB_ADMIN':
        return 'Club Admin';
      default:
        return 'Member';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'PLATFORM_ADMIN':
        return Colors.purple;
      case 'CLUB_ADMIN':
        return AppTheme.dustyBlue;
      default:
        return AppTheme.sageGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Icon(Icons.people, color: AppTheme.darkWood, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members List',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkWood,
                          ),
                        ),
                        Text(
                          widget.clubName,
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_members.length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.sageGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(color: AppTheme.lightWood),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMembers,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppTheme.lightWood.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No members yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.lightWood,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMembers,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _members.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final memberId = member['id'] as int;
                          final name = member['name'] ?? 'Unknown';
                          final email = member['email'] ?? '';
                          final platformRole = member['role'] ?? 'MEMBER';
                          final isClubAdmin = _clubAdminIds.contains(memberId);
                          final officerPosition =
                              _memberOfficerPositions[memberId];
                          final initial = name.isNotEmpty
                              ? name[0].toUpperCase()
                              : '?';

                          return HandDrawnContainer(
                            color: Colors.white,
                            borderColor: isClubAdmin
                                ? AppTheme.dustyBlue
                                : AppTheme.lightWood.withValues(alpha: 0.3),
                            borderRadius: 16,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.sageGreen.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: member['avatarUrl'] != null
                                      ? ClipOval(
                                          child: Image.network(
                                            member['avatarUrl'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => Center(
                                              child: Text(
                                                initial,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.sageGreen,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            initial,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.sageGreen,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.darkWood,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.lightWood,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          // Platform role badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(
                                                platformRole,
                                              ).withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _getRoleLabel(platformRole),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _getRoleColor(
                                                  platformRole,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Club Admin badge if applicable
                                          if (isClubAdmin)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.dustyBlue
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: AppTheme.dustyBlue
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    size: 10,
                                                    color: AppTheme.dustyBlue,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Club Admin',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppTheme.dustyBlue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          // Officer position badge if applicable
                                          if (officerPosition != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.purple
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.badge,
                                                    size: 10,
                                                    color: Colors.purple,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    officerPosition,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.purple,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
