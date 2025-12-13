/// Meeting model for ToastLabPlus
class Meeting {
  final int? id;
  final int? clubId;
  final String? theme;
  final DateTime? meetingDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Meeting({
    this.id,
    this.clubId,
    this.theme,
    this.meetingDate,
    this.startTime,
    this.endTime,
    this.location,
    this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] as int?,
      clubId: json['clubId'] as int?,
      theme: json['theme'] as String?,
      meetingDate: json['meetingDate'] != null
          ? DateTime.tryParse(json['meetingDate'] as String)
          : null,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
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
      if (clubId != null) 'clubId': clubId,
      if (theme != null) 'theme': theme,
      if (meetingDate != null)
        'meetingDate': meetingDate!.toIso8601String().split('T')[0],
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (location != null) 'location': location,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'DRAFT':
        return 'Draft';
      case 'PUBLISHED':
        return 'Open';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status ?? 'Unknown';
    }
  }
}
