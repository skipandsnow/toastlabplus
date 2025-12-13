import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';

class ClubPublicScreen extends StatefulWidget {
  final int clubId;
  final String clubName;

  const ClubPublicScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubPublicScreen> createState() => _ClubPublicScreenState();
}

class _ClubPublicScreenState extends State<ClubPublicScreen> {
  Map<String, dynamic>? _clubDetails;
  List<dynamic> _meetings = [];
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

      // 1. Fetch Club Details
      final clubResponse = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubsEndpoint}/${widget.clubId}',
        ),
        headers: authService.authHeaders,
      );

      if (clubResponse.statusCode == 200) {
        _clubDetails = json.decode(clubResponse.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load club details');
      }

      // 2. Fetch Incoming Events (Meetings)
      final meetingsResponse = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.meetingsEndpoint}/club/${widget.clubId}',
        ),
        headers: authService.authHeaders,
      );

      if (meetingsResponse.statusCode == 200) {
        _meetings = json.decode(meetingsResponse.body) as List<dynamic>;
      } else {
        // Allow meeting fetch to fail gracefully?
        // No, let's treat it as error if we can't show events.
        throw Exception('Failed to load events');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkWood),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.clubName,
          style: TextStyle(color: AppTheme.darkWood),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Club Header Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.lightWood.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.lightWood.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.sageGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.groups_3_rounded,
                            size: 48,
                            color: AppTheme.sageGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _clubDetails?['name'] ?? widget.clubName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkWood,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _clubDetails?['description'] ??
                              'No description available.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.lightWood,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Incoming Events Section
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: AppTheme.dustyBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Incoming Events',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkWood,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_meetings.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No upcoming events scheduled.',
                          style: TextStyle(color: AppTheme.lightWood),
                        ),
                      ),
                    )
                  else
                    ..._meetings.map((meeting) => _buildMeetingCard(meeting)),
                ],
              ),
            ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    final date = DateTime.parse(meeting['meetingDate']);

    // Determine time from data or use placeholder if missing?
    // Meeting entity in frontend doesn't show time field clearly in JSON, backend has LocalDate meetingDate.
    // Wait, backend `Meeting` entity uses `LocalDate meetingDate`. Not LocalDateTime?
    // Step 1563 check: `meetingDate` type changed to `LocalDate`.
    // So there is NO time. Just Date.

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: HandDrawnContainer(
        color: Colors.white,
        borderColor: AppTheme.dustyBlue,
        borderRadius: 16,
        onTap: () {
          // View Meeting Details (Agenda)
          // TODO: Implement Meeting Detail Screen
        },
        child: Row(
          children: [
            // Date Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.dustyBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dustyBlue,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dustyBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meeting['title'] ?? 'Meeting',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkWood,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.lightWood,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        meeting['location'] ?? 'TBD',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightWood,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
