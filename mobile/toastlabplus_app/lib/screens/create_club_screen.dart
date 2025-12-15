import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';

class CreateClubScreen extends StatefulWidget {
  const CreateClubScreen({super.key});

  @override
  State<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends State<CreateClubScreen> {
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

  bool _isLoading = false;
  String? _error;

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
        'isActive': true,
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

      final response = await http.post(
        Uri.parse('${ApiConfig.mcpServerBaseUrl}${ApiConfig.clubsEndpoint}'),
        headers: {
          ...authService.authHeaders,
          'Content-Type': 'application/json',
        },
        body: json.encode(clubData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Club created successfully!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to create club: ${response.statusCode}');
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
    _contactPersonController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      appBar: AppBar(
        title: Text('Create Club', style: TextStyle(color: AppTheme.darkWood)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkWood),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    text: 'Create Club',
                    onPressed: _submit,
                    color: AppTheme.sageGreen,
                    textColor: Colors.white,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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
}
