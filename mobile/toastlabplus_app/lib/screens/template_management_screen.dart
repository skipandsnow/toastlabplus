import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hand_drawn_widgets.dart';
import '../widgets/user_header.dart';
import '../models/agenda_template.dart';

class TemplateManagementScreen extends StatefulWidget {
  final int clubId;
  final String clubName;

  const TemplateManagementScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<TemplateManagementScreen> createState() =>
      _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen> {
  List<AgendaTemplate> _templates = [];
  bool _isLoading = true;
  String? _error;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/templates',
        ),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _templates = data.map((e) => AgendaTemplate.fromJson(e)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load templates';
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

  Future<void> _uploadTemplate() async {
    // Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to read file'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show name dialog
    final nameController = TextEditingController(
      text: file.name.replaceAll('.xlsx', '').replaceAll('.xls', ''),
    );
    final descController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Upload Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Template Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
          ],
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
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUploading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/templates/upload',
        ),
      );

      request.headers.addAll(authService.authHeaders);
      request.fields['name'] = nameController.text;
      request.fields['description'] = descController.text;
      request.files.add(
        http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template uploaded successfully!'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
        _loadTemplates();
      } else if (mounted) {
        final error = json.decode(responseBody)['error'] ?? 'Upload failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteTemplate(AgendaTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/templates/${template.id}',
        ),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Template deleted'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadTemplates();
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to delete template'),
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

  Future<void> _parseTemplate(AgendaTemplate template) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Parsing with AI...'),
            const SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/templates/${template.id}/parse',
        ),
        headers: authService.authHeaders,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200 && mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Template parsed successfully!'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
        _loadTemplates();
      } else if (mounted) {
        String error = 'Parse failed';
        try {
          final data = json.decode(response.body);
          error = data['error'] ?? error;
        } catch (_) {}
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _viewParsedStructure(AgendaTemplate template) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.mcpServerBaseUrl}/api/clubs/${widget.clubId}/templates/${template.id}',
        ),
        headers: authService.authHeaders,
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final parsedStructureStr = data['parsedStructure'] as String?;

        // Try to parse the JSON structure
        Map<String, dynamic>? parsedJson;
        List<dynamic>? variableMappings;

        if (parsedStructureStr != null) {
          try {
            parsedJson = json.decode(parsedStructureStr);
            variableMappings =
                parsedJson?['variable_mappings'] as List<dynamic>?;
          } catch (_) {
            // If parsing fails, show raw string
          }
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Parsed Structure: ${template.name}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Variable Mappings Table
                    if (variableMappings != null &&
                        variableMappings.isNotEmpty) ...[
                      Text(
                        '📍 Variable Mappings (座標對照表)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkWood,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.lightWood.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DataTable(
                          columnSpacing: 16,
                          headingRowHeight: 36,
                          dataRowMinHeight: 32,
                          dataRowMaxHeight: 48,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Role',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Position',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: variableMappings.map<DataRow>((mapping) {
                            final role = mapping['role'] ?? 'N/A';
                            final valuePos = mapping['value_position'];
                            String posStr = 'N/A';
                            if (valuePos is Map) {
                              final row = valuePos['row'];
                              final col = valuePos['col'];
                              posStr = 'R$row, C$col';
                            }
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    role.toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    posStr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],
                    // Raw JSON (collapsed)
                    ExpansionTile(
                      title: const Text('Raw JSON'),
                      tilePadding: EdgeInsets.zero,
                      children: [
                        SelectableText(
                          parsedStructureStr ?? 'No parsed structure available',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
                  Icon(Icons.description, color: AppTheme.darkWood, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agenda Templates',
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
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _isUploading ? null : _uploadTemplate,
                  child: HandDrawnContainer(
                    color: AppTheme.sageGreen.withValues(alpha: 0.15),
                    borderColor: AppTheme.sageGreen,
                    borderRadius: 16,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isUploading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(Icons.upload_file, color: AppTheme.sageGreen),
                        const SizedBox(width: 12),
                        Text(
                          _isUploading
                              ? 'Uploading...'
                              : 'Upload Excel Template',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.sageGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                            onPressed: _loadTemplates,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _templates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: AppTheme.lightWood.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No templates yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.lightWood,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload an Excel template to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.lightWood,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTemplates,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _templates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final template = _templates[index];
                          return _buildTemplateCard(template);
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

  Widget _buildTemplateCard(AgendaTemplate template) {
    return HandDrawnContainer(
      color: Colors.white,
      borderColor: AppTheme.lightWood.withValues(alpha: 0.3),
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.dustyBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.description, color: AppTheme.dustyBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkWood,
                  ),
                ),
                if (template.originalFilename != null)
                  Text(
                    template.originalFilename!,
                    style: TextStyle(fontSize: 12, color: AppTheme.lightWood),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: template.hasParsedStructure
                            ? AppTheme.sageGreen.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        template.hasParsedStructure ? 'Parsed' : 'Not Parsed',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: template.hasParsedStructure
                              ? AppTheme.sageGreen
                              : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'v${template.version}',
                      style: TextStyle(fontSize: 12, color: AppTheme.lightWood),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteTemplate(template);
              } else if (value == 'parse') {
                _parseTemplate(template);
              } else if (value == 'view') {
                _viewParsedStructure(template);
              }
            },
            itemBuilder: (ctx) => [
              if (template.hasParsedStructure)
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: AppTheme.sageGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text('View Structure'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'parse',
                enabled: !template.hasParsedStructure,
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_fix_high,
                      color: AppTheme.dustyBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      template.hasParsedStructure
                          ? 'Already Parsed'
                          : 'Parse with AI',
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
