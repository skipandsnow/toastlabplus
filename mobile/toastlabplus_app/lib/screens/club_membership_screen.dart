import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class ClubMembershipScreen extends StatefulWidget {
  const ClubMembershipScreen({super.key});

  @override
  State<ClubMembershipScreen> createState() => _ClubMembershipScreenState();
}

class _ClubMembershipScreenState extends State<ClubMembershipScreen> {
  List<dynamic> _clubs = [];
  List<dynamic> _myMemberships = [];
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

      // Load clubs list
      final clubsResponse = await http.get(
        Uri.parse('${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubsEndpoint}'),
        headers: authService.authHeaders,
      );

      // Load my memberships
      final membershipsResponse = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubMembershipsEndpoint}/my',
        ),
        headers: authService.authHeaders,
      );

      if (clubsResponse.statusCode == 200) {
        _clubs = json.decode(clubsResponse.body) as List<dynamic>;
      }

      if (membershipsResponse.statusCode == 200) {
        _myMemberships = json.decode(membershipsResponse.body) as List<dynamic>;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _applyToClub(int clubId, String clubName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.group_add, color: AppTheme.dustyBlue, size: 48),
            const SizedBox(height: 12),
            const Text('Join Club', textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          'Do you want to apply to join "$clubName"?\nYour application needs admin approval.',
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
              backgroundColor: AppTheme.dustyBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubMembershipsEndpoint}',
        ),
        headers: authService.authHeaders,
        body: json.encode({'clubId': clubId}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            alignment: Alignment.topCenter,
            insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              children: [
                Icon(Icons.check_circle, color: AppTheme.sageGreen, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Application Submitted',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: const Text(
              'Your application has been submitted!\nPlease wait for admin approval.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sageGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _loadData(); // Refresh
      } else {
        final data = json.decode(response.body);
        _showError(data['error'] ?? 'Application failed');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
            const SizedBox(height: 12),
            const Text('Error', textAlign: TextAlign.center),
          ],
        ),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String? _getMembershipStatus(int clubId) {
    for (var m in _myMemberships) {
      if (m['clubId'] == clubId) {
        return m['status'] as String?;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Join Club', style: TextStyle(color: AppTheme.darkWood)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkWood),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // My memberships section
                  if (_myMemberships.isNotEmpty) ...[
                    Text(
                      'My Applications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkWood,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._myMemberships.map((m) => _buildMembershipCard(m)),
                    const SizedBox(height: 24),
                  ],

                  // Available clubs section
                  Text(
                    'Available Clubs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkWood,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_clubs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.warmWhite,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'No clubs available',
                          style: TextStyle(color: AppTheme.lightWood),
                        ),
                      ),
                    )
                  else
                    ..._clubs.map((club) => _buildClubCard(club)),
                ],
              ),
            ),
    );
  }

  Widget _buildMembershipCard(dynamic membership) {
    final status = membership['status'] as String;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'APPROVED':
        statusColor = AppTheme.sageGreen;
        statusText = 'Approved';
        statusIcon = Icons.check_circle;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppTheme.lightWood;
        statusText = status;
        statusIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkWood.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membership['clubName'] ?? 'Club',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkWood,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Applied: ${membership['appliedAt'] ?? '-'}',
                  style: TextStyle(fontSize: 12, color: AppTheme.lightWood),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard(dynamic club) {
    final clubId = club['id'] as int;
    final clubName = club['name'] as String? ?? 'Unnamed Club';
    final status = _getMembershipStatus(clubId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkWood.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.dustyBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups, color: AppTheme.dustyBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clubName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkWood,
                  ),
                ),
                if (club['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    club['description'],
                    style: TextStyle(fontSize: 12, color: AppTheme.lightWood),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.lightWood.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status == 'PENDING'
                    ? 'Pending'
                    : (status == 'APPROVED' ? 'Joined' : 'Rejected'),
                style: TextStyle(color: AppTheme.lightWood, fontSize: 12),
              ),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dustyBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => _applyToClub(clubId, clubName),
              child: const Text('Apply'),
            ),
        ],
      ),
    );
  }
}
