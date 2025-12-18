import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';

class EditClubInfoScreen extends StatefulWidget {
  final int clubId;
  final String clubName;

  const EditClubInfoScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<EditClubInfoScreen> createState() => _EditClubInfoScreenState();
}

class _EditClubInfoScreenState extends State<EditClubInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _meetingDayController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactPersonController = TextEditingController();

  TimeOfDay? _meetingTime;
  TimeOfDay? _meetingEndTime;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClubDetails();
  }

  Future<void> _loadClubDetails() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubsEndpoint}/${widget.clubId}',
        ),
        headers: authService.authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _nameController.text = data['name'] ?? '';
        _descController.text = data['description'] ?? '';
        _locationController.text = data['location'] ?? '';
        _meetingDayController.text = data['meetingDay'] ?? '';
        _emailController.text = data['contactEmail'] ?? '';
        _phoneController.text = data['contactPhone'] ?? '';

        if (data['meetingTime'] != null) {
          final timeParts = (data['meetingTime'] as String).split(':');
          if (timeParts.length >= 2) {
            _meetingTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          }
        }
        if (data['meetingEndTime'] != null) {
          final timeParts = (data['meetingEndTime'] as String).split(':');
          if (timeParts.length >= 2) {
            _meetingEndTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          }
        }
        _contactPersonController.text = data['contactPerson'] ?? '';

        setState(() => _isLoading = false);
      } else {
        setState(() {
          _error = 'Failed to load club details';
          _isLoading = false;
        });
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final Map<String, dynamic> clubData = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'meetingDay': _meetingDayController.text.trim(),
        'contactEmail': _emailController.text.trim(),
        'contactPhone': _phoneController.text.trim(),
        'contactPerson': _contactPersonController.text.trim(),
      };

      if (_meetingTime != null) {
        final hour = _meetingTime!.hour.toString().padLeft(2, '0');
        final minute = _meetingTime!.minute.toString().padLeft(2, '0');
        clubData['meetingTime'] = '$hour:$minute:00';
      }
      if (_meetingEndTime != null) {
        final hour = _meetingEndTime!.hour.toString().padLeft(2, '0');
        final minute = _meetingEndTime!.minute.toString().padLeft(2, '0');
        clubData['meetingEndTime'] = '$hour:$minute:00';
      }

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubsEndpoint}/${widget.clubId}',
        ),
        headers: {
          ...authService.authHeaders,
          'Content-Type': 'application/json',
        },
        body: json.encode(clubData),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club info updated successfully!')),
        );
        Navigator.pop(
          context,
          _nameController.text.trim(),
        ); // Return new club name
      } else {
        setState(() => _error = 'Failed to update: ${response.statusCode}');
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

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _meetingDayController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showPreview() {
    // Collect current values
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final location = _locationController.text.trim();
    final meetingDay = _meetingDayController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final contactPerson = _contactPersonController.text.trim();
    final startTimeStr = _meetingTime?.format(context) ?? 'TBD';
    final endTimeStr = _meetingEndTime?.format(context) ?? 'TBD';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppTheme.ricePaper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.lightWood.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, color: AppTheme.dustyBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkWood,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.lightWood),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Club Name' : name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkWood,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (description.isNotEmpty) ...[
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.lightWood,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildPreviewInfoRow(Icons.place, location),
                    const SizedBox(height: 12),
                    _buildPreviewInfoRow(
                      Icons.calendar_today,
                      '$meetingDay at $startTimeStr - $endTimeStr',
                    ),
                    const SizedBox(height: 12),
                    if (contactPerson.isNotEmpty)
                      _buildPreviewInfoRow(Icons.person, contactPerson),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildPreviewInfoRow(Icons.email, email),
                    ],
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildPreviewInfoRow(Icons.phone, phone),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.sageGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, color: AppTheme.darkWood),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _meetingTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _meetingTime) {
      setState(() {
        _meetingTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _meetingEndTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _meetingEndTime) {
      setState(() {
        _meetingEndTime = picked;
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.darkWood,
          ),
        ),
        const SizedBox(height: 8),
        HandDrawnContainer(
          color: Colors.white,
          borderColor: AppTheme.lightWood.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: const InputDecoration(border: InputBorder.none),
            validator: validator,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      appBar: AppBar(
        title: Text(
          'Edit Club Info',
          style: TextStyle(color: AppTheme.darkWood),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkWood),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.visibility_outlined, color: AppTheme.dustyBlue),
            tooltip: 'Preview',
            onPressed: _showPreview,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading && _nameController.text.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      _buildTextField(
                        label: 'Club Name',
                        controller: _nameController,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Description',
                        controller: _descController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Location',
                        controller: _locationController,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Meeting Day',
                        controller: _meetingDayController,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Time',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkWood,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                HandDrawnContainer(
                                  color: Colors.white,
                                  borderColor: AppTheme.lightWood,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  onTap: () => _selectTime(context),
                                  child: Center(
                                    child: Text(
                                      _meetingTime?.format(context) ?? 'Set',
                                      style: TextStyle(
                                        color: _meetingTime == null
                                            ? AppTheme.lightWood
                                            : AppTheme.darkWood,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
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
                                  'End Time',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkWood,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                HandDrawnContainer(
                                  color: Colors.white,
                                  borderColor: AppTheme.lightWood,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  onTap: () => _selectEndTime(context),
                                  child: Center(
                                    child: Text(
                                      _meetingEndTime?.format(context) ?? 'Set',
                                      style: TextStyle(
                                        color: _meetingEndTime == null
                                            ? AppTheme.lightWood
                                            : AppTheme.darkWood,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Contact Person',
                        controller: _contactPersonController,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Contact Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Contact Phone',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 32),

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        HandDrawnButton(
                          text: 'Save Changes',
                          onPressed: _submit,
                          color: AppTheme.dustyBlue,
                          textColor: Colors.white,
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
