import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../widgets/user_header.dart';
import '../models/meeting.dart';
import 'meeting_detail_screen.dart';

class MeetingListScreen extends StatefulWidget {
  final int clubId;
  final String clubName;

  const MeetingListScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  List<Meeting> _meetings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/meetings/club/${widget.clubId}',
        ),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _meetings = data.map((e) => Meeting.fromJson(e)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load meetings';
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT':
        return Colors.grey;
      case 'OPEN':
        return AppTheme.sageGreen;
      case 'CLOSED':
        return Colors.orange;
      case 'FINALIZED':
        return AppTheme.dustyBlue;
      case 'COMPLETED':
        return Colors.purple;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
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
                  Icon(Icons.event, color: AppTheme.darkWood, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meetings',
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
                      '${_meetings.length}',
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
                          Text(_error!),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadMeetings,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _meetings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: AppTheme.lightWood.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No meetings yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.lightWood,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generate meetings from schedule settings',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.lightWood,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMeetings,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _meetings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final meeting = _meetings[index];
                          return _buildMeetingCard(meeting);
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

  Widget _buildMeetingCard(Meeting meeting) {
    final statusColor = _getStatusColor(meeting.status);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MeetingDetailScreen(
                meetingId: meeting.id,
                clubId: widget.clubId,
                clubName: widget.clubName,
              ),
            ),
          ).then((_) => _loadMeetings());
        },
        child: HandDrawnContainer(
          color: Colors.white,
          borderColor: statusColor.withValues(alpha: 0.5),
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      meeting.meetingDate.day.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      _getMonthAbbr(meeting.meetingDate.month),
                      style: TextStyle(fontSize: 12, color: statusColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (meeting.meetingNumber != null)
                          Text(
                            '#${meeting.meetingNumber}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkWood,
                            ),
                          ),
                        if (meeting.theme != null &&
                            meeting.theme!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meeting.theme!,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.lightWood,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(meeting.startTime ?? '').length >= 5 ? meeting.startTime!.substring(0, 5) : meeting.startTime ?? ''} - ${(meeting.endTime ?? '').length >= 5 ? meeting.endTime!.substring(0, 5) : meeting.endTime ?? ''}',
                      style: TextStyle(fontSize: 12, color: AppTheme.lightWood),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        meeting.statusDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.lightWood),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}
