import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../widgets/user_header.dart';
import '../models/meeting_schedule.dart';
import 'meeting_list_screen.dart';

class MeetingSettingsScreen extends StatefulWidget {
  final int clubId;
  final String clubName;

  const MeetingSettingsScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<MeetingSettingsScreen> createState() => _MeetingSettingsScreenState();
}

class _MeetingSettingsScreenState extends State<MeetingSettingsScreen> {
  List<MeetingSchedule> _schedules = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/meeting-schedules',
        ),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _schedules = data.map((e) => MeetingSchedule.fromJson(e)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load schedules';
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

  Future<void> _createSchedule() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ScheduleFormSheet(clubId: widget.clubId),
    );

    if (result == true) {
      _loadSchedules();
    }
  }

  Future<void> _generateMeetings(MeetingSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Generate Meetings'),
        content: Text(
          'Generate meetings for the next ${schedule.autoGenerateMonths} months based on this schedule?',
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
            child: const Text('Generate'),
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
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/meeting-schedules/${schedule.id}/generate',
        ),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Generated ${data['count']} meetings!'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to generate meetings'),
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
                          'Meeting Settings',
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'View Meetings',
                      Icons.list_alt,
                      AppTheme.dustyBlue,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MeetingListScreen(
                              clubId: widget.clubId,
                              clubName: widget.clubName,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      'New Schedule',
                      Icons.add_circle_outline,
                      AppTheme.sageGreen,
                      _createSchedule,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Meeting Schedules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkWood,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                            onPressed: _loadSchedules,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _schedules.isEmpty
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
                            'No schedules yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.lightWood,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a schedule to auto-generate meetings',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.lightWood,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSchedules,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _schedules.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final schedule = _schedules[index];
                          return _buildScheduleCard(schedule);
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

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    // Use darker version of color for better contrast
    final darkerColor = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness * 0.7).clamp(0.0, 1.0),
        )
        .toColor();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: HandDrawnContainer(
          color: color.withValues(alpha: 0.25),
          borderColor: darkerColor,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: darkerColor, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: darkerColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(MeetingSchedule schedule) {
    return HandDrawnContainer(
      color: Colors.white,
      borderColor: AppTheme.lightWood.withValues(alpha: 0.3),
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat, color: AppTheme.dustyBlue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.name ?? 'Regular Meeting',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkWood,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schedule.scheduleDescription,
                      style: TextStyle(fontSize: 14, color: AppTheme.lightWood),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                Icons.access_time,
                '${schedule.startTime} - ${schedule.endTime}',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.mic,
                '${schedule.defaultSpeakerCount} Speakers',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _generateMeetings(schedule),
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Text('Generate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.sageGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.sageGreen),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: AppTheme.sageGreen)),
        ],
      ),
    );
  }
}

// ==================== Schedule Form Sheet ====================

class _ScheduleFormSheet extends StatefulWidget {
  final int clubId;

  const _ScheduleFormSheet({required this.clubId});

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final String _frequency = 'MONTHLY';
  int _dayOfWeek = 3; // Wednesday
  final List<int> _weekOfMonth = [1, 3]; // 1st and 3rd
  TimeOfDay _startTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);
  int _speakerCount = 3;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // When losing focus, fill with default value if empty
    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus && _nameController.text.isEmpty) {
        setState(() {
          _nameController.text = 'Regular Meeting';
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final body = json.encode({
        'name': _nameController.text.isEmpty
            ? 'Regular Meeting'
            : _nameController.text,
        'frequency': _frequency,
        'dayOfWeek': _dayOfWeek,
        'weekOfMonth': _weekOfMonth,
        'startTime':
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        'endTime':
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        'defaultSpeakerCount': _speakerCount,
        'defaultLocation': _locationController.text.isEmpty
            ? null
            : _locationController.text,
        'autoGenerateMonths': 3,
      });

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/meeting-schedules',
        ),
        headers: {
          ...authService.authHeaders,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create schedule'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.ricePaper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Schedule',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkWood,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Schedule Name',
                      hintText: 'Regular Meeting',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Day of Week',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkWood,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1, 2, 3, 4, 5, 6, 7].map((d) {
                      final days = [
                        '',
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];
                      final isSelected = _dayOfWeek == d;
                      return ChoiceChip(
                        label: Text(days[d]),
                        selected: isSelected,
                        selectedColor: AppTheme.sageGreen.withValues(
                          alpha: 0.3,
                        ),
                        onSelected: (_) => setState(() => _dayOfWeek = d),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Week of Month',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkWood,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1, 2, 3, 4].map((w) {
                      final labels = ['', '1st', '2nd', '3rd', '4th'];
                      final isSelected = _weekOfMonth.contains(w);
                      return FilterChip(
                        label: Text(labels[w]),
                        selected: isSelected,
                        selectedColor: AppTheme.dustyBlue.withValues(
                          alpha: 0.3,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _weekOfMonth.add(w);
                            } else {
                              _weekOfMonth.remove(w);
                            }
                            _weekOfMonth.sort();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Start Time'),
                          subtitle: Text(_startTime.format(context)),
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (t != null) setState(() => _startTime = t);
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('End Time'),
                          subtitle: Text(_endTime.format(context)),
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                            );
                            if (t != null) setState(() => _endTime = t);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Default Speakers',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkWood,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.sageGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_speakerCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.sageGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _speakerCount.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (v) => setState(() => _speakerCount = v.round()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Default Location',
                      hintText: 'e.g., Zoom, Room 101',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sageGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
