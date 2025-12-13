import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class AdminApprovalScreen extends StatefulWidget {
  final int clubId;
  final String clubName;

  const AdminApprovalScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  List<dynamic> _pendingMembers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingMembers();
  }

  Future<void> _loadPendingMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubMembershipsEndpoint}/club/${widget.clubId}/pending',
        ),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        _pendingMembers = json.decode(response.body) as List<dynamic>;
      } else {
        _error = 'Failed to load pending members';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveMember(int membershipId, String memberName) async {
    final confirmed = await _showConfirmDialog(
      title: 'Approve Application',
      message: 'Are you sure you want to approve "$memberName"?',
      confirmText: 'Approve',
      confirmColor: AppTheme.sageGreen,
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.patch(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubMembershipsEndpoint}/$membershipId/approve',
        ),
        headers: authService.authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccessDialog('Approved "$memberName"');
        _loadPendingMembers();
      } else {
        _showErrorDialog('Operation failed');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _rejectMember(int membershipId, String memberName) async {
    final reason = await _showRejectDialog(memberName);
    if (reason == null) return; // User cancelled
    if (!mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.patch(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubMembershipsEndpoint}/$membershipId/reject',
        ),
        headers: authService.authHeaders,
        body: json.encode({'reason': reason}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccessDialog('Rejected "$memberName"');
        _loadPendingMembers();
      } else {
        _showErrorDialog('Operation failed');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRejectDialog(String memberName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Application', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to reject "$memberName"?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.check_circle, color: AppTheme.sageGreen, size: 48),
            const SizedBox(height: 12),
            const Text('Success', textAlign: TextAlign.center),
          ],
        ),
        content: Text(message, textAlign: TextAlign.center),
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
  }

  void _showErrorDialog(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Member Approval',
              style: TextStyle(color: AppTheme.darkWood, fontSize: 18),
            ),
            Text(
              widget.clubName,
              style: TextStyle(color: AppTheme.lightWood, fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkWood),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.lightWood,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load',
                    style: TextStyle(color: AppTheme.darkWood),
                  ),
                  TextButton(
                    onPressed: _loadPendingMembers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPendingMembers,
              child: _pendingMembers.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: AppTheme.lightWood.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pending applications',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.lightWood,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingMembers.length,
                      itemBuilder: (context, index) {
                        final member = _pendingMembers[index];
                        return _buildMemberCard(member);
                      },
                    ),
            ),
    );
  }

  Widget _buildMemberCard(dynamic member) {
    final membershipId = member['membershipId'] as int;
    final memberName = member['memberName'] as String? ?? 'Unknown';
    final memberEmail = member['memberEmail'] as String? ?? '';
    final appliedAt = member['appliedAt'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkWood.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.dustyBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dustyBlue,
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
                      memberName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkWood,
                      ),
                    ),
                    Text(
                      memberEmail,
                      style: TextStyle(fontSize: 12, color: AppTheme.lightWood),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Applied: $appliedAt',
            style: TextStyle(fontSize: 11, color: AppTheme.lightWood),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _rejectMember(membershipId, memberName),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sageGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _approveMember(membershipId, memberName),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
