import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/club_officer.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../widgets/user_header.dart';

class OfficerManagementScreen extends StatefulWidget {
  final int clubId;
  final String clubName;

  const OfficerManagementScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<OfficerManagementScreen> createState() =>
      _OfficerManagementScreenState();
}

class _OfficerManagementScreenState extends State<OfficerManagementScreen> {
  List<ClubOfficer> _officers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfficers();
  }

  Future<void> _loadOfficers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/officers',
        ),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        _officers = data
            .map((json) => ClubOfficer.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Failed to load officers: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _assignOfficer(ClubOfficer officer) async {
    // Collect member IDs that are already assigned to officer positions
    final assignedMemberIds = _officers
        .where((o) => o.isFilled && o.memberId != null)
        .map((o) => o.memberId!)
        .toSet();

    final selectedMember = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MemberSelectionSheet(
        clubId: widget.clubId,
        position: officer.position,
        positionDisplay: officer.positionDisplay,
        excludeMemberIds: assignedMemberIds,
      ),
    );

    if (selectedMember != null && mounted) {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Confirm Assignment'),
          content: Text(
            'Assign ${selectedMember['name']} as ${officer.positionDisplay}?',
          ),
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
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _performAssignment(officer.position, selectedMember);
      }
    }
  }

  Future<void> _performAssignment(
    String position,
    Map<String, dynamic> member,
  ) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/officers',
        ),
        headers: authService.authHeaders,
        body: json.encode({'position': position, 'memberId': member['id']}),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${member['name']} assigned successfully'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
        _loadOfficers();
      } else {
        final data = json.decode(response.body);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to assign officer'),
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

  Future<void> _removeOfficer(ClubOfficer officer) async {
    if (officer.officerId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Officer'),
        content: Text(
          'Remove ${officer.memberName} from ${officer.positionDisplay}?',
        ),
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/officers/${officer.officerId}',
        ),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Officer removed'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
        _loadOfficers();
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to remove officer'),
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
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: UserHeader(showBackButton: true),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Officers',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkWood,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.clubName,
                    style: TextStyle(fontSize: 14, color: AppTheme.lightWood),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOfficers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOfficers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _officers.length,
        itemBuilder: (context, index) {
          final officer = _officers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOfficerCard(officer),
          );
        },
      ),
    );
  }

  Widget _buildOfficerCard(ClubOfficer officer) {
    final isFilled = officer.isFilled;

    return HandDrawnContainer(
      color: isFilled ? Colors.white : AppTheme.ricePaper,
      borderColor: isFilled ? AppTheme.sageGreen : AppTheme.lightWood,
      borderRadius: 16,
      onTap: () => _assignOfficer(officer),
      child: Row(
        children: [
          // Position icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isFilled
                  ? AppTheme.sageGreen.withValues(alpha: 0.1)
                  : AppTheme.lightWood.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                officer.positionIcon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  officer.positionDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkWood,
                  ),
                ),
                const SizedBox(height: 4),
                if (isFilled)
                  Row(
                    children: [
                      _buildMemberAvatar(officer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              officer.memberName ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.darkWood,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (officer.memberEmail != null)
                              Text(
                                officer.memberEmail!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.lightWood,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Tap to assign',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.lightWood,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          // Action
          if (isFilled)
            IconButton(
              icon: Icon(Icons.close, color: Colors.red.shade300, size: 20),
              onPressed: () => _removeOfficer(officer),
              tooltip: 'Remove',
            )
          else
            Icon(Icons.add_circle_outline, color: AppTheme.dustyBlue, size: 24),
        ],
      ),
    );
  }

  Widget _buildMemberAvatar(ClubOfficer officer) {
    if (officer.memberAvatarUrl != null &&
        officer.memberAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(officer.memberAvatarUrl!),
      );
    }

    final initial = officer.memberName?.isNotEmpty == true
        ? officer.memberName![0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.dustyBlue.withValues(alpha: 0.2),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.dustyBlue,
        ),
      ),
    );
  }
}

// ==================== Member Selection Bottom Sheet ====================

class _MemberSelectionSheet extends StatefulWidget {
  final int clubId;
  final String position;
  final String positionDisplay;
  final Set<int> excludeMemberIds;

  const _MemberSelectionSheet({
    required this.clubId,
    required this.position,
    required this.positionDisplay,
    this.excludeMemberIds = const {},
  });

  @override
  State<_MemberSelectionSheet> createState() => _MemberSelectionSheetState();
}

class _MemberSelectionSheetState extends State<_MemberSelectionSheet> {
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/club-memberships/club/${widget.clubId}',
        ),
        headers: authService.authHeaders,
      );

      debugPrint('Members API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        // Filter only APPROVED members, exclude already assigned, and map to expected format
        _members = data
            .where((m) => m['status'] == 'APPROVED')
            .map((m) {
              final member = m['member'] as Map<String, dynamic>?;
              return <String, dynamic>{
                'memberId': member?['id'],
                'memberName': member?['name'] ?? 'Unknown',
                'memberEmail': member?['email'] ?? '',
                'memberAvatarUrl': member?['avatarUrl'],
              };
            })
            .where((m) {
              // Exclude members already assigned to other officer positions
              final memberId = m['memberId'] as int?;
              return memberId == null ||
                  !widget.excludeMemberIds.contains(memberId);
            })
            .toList();
        _filteredMembers = _members;
      }
    } catch (e) {
      debugPrint('Error loading members: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterMembers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMembers = _members;
      } else {
        _filteredMembers = _members.where((m) {
          final name = (m['memberName'] ?? '').toString().toLowerCase();
          final email = (m['memberEmail'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppTheme.ricePaper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightWood.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Assign ${widget.positionDisplay}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkWood,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: Icon(Icons.search, color: AppTheme.lightWood),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _filterMembers,
            ),
          ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No approved members'
                          : 'No members found',
                      style: TextStyle(color: AppTheme.lightWood),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = _filteredMembers[index];
                      return _buildMemberTile(member);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final name = member['memberName'] ?? 'Unknown';
    final email = member['memberEmail'] ?? '';
    final avatarUrl = member['memberAvatarUrl'] as String?;
    final memberId = member['memberId'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context, {
              'id': memberId,
              'name': name,
              'email': email,
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (avatarUrl != null && avatarUrl.isNotEmpty)
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(avatarUrl),
                  )
                else
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.dustyBlue.withValues(alpha: 0.2),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dustyBlue,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkWood,
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
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
        ),
      ),
    );
  }
}
