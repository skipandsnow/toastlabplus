/// Club model for ToastLabPlus
class Club {
  final int? id;
  final String? name;
  final String? description;
  final String? location;
  final String? meetingDay;
  final String? meetingTime;
  final String? contactEmail;
  final String? contactPhone;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Club({
    this.id,
    this.name,
    this.description,
    this.location,
    this.meetingDay,
    this.meetingTime,
    this.contactEmail,
    this.contactPhone,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as int?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      meetingDay: json['meetingDay'] as String?,
      meetingTime: json['meetingTime'] as String?,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (meetingDay != null) 'meetingDay': meetingDay,
      if (meetingTime != null) 'meetingTime': meetingTime,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (isActive != null) 'isActive': isActive,
    };
  }
}
