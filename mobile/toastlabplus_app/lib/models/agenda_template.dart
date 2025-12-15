class AgendaTemplate {
  final int id;
  final String name;
  final String? description;
  final String? originalFilename;
  final int version;
  final bool isActive;
  final DateTime? createdAt;
  final bool hasParsedStructure;

  AgendaTemplate({
    required this.id,
    required this.name,
    this.description,
    this.originalFilename,
    this.version = 1,
    this.isActive = true,
    this.createdAt,
    this.hasParsedStructure = false,
  });

  factory AgendaTemplate.fromJson(Map<String, dynamic> json) {
    return AgendaTemplate(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      originalFilename: json['originalFilename'] as String?,
      version: json['version'] as int? ?? 1,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      hasParsedStructure: json['hasParsedStructure'] as bool? ?? false,
    );
  }
}
