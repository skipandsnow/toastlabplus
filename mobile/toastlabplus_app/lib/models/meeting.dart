/// Meeting model for ToastLabPlus
class Meeting {
  final int id;
  final int? clubId;
  final int? meetingNumber;
  final String? theme;
  final DateTime meetingDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String status;
  final int? speakerCount;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Meeting({
    required this.id,
    this.clubId,
    this.meetingNumber,
    this.theme,
    required this.meetingDate,
    this.startTime,
    this.endTime,
    this.location,
    required this.status,
    this.speakerCount,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] as int,
      clubId: json['clubId'] as int?,
      meetingNumber: json['meetingNumber'] as int?,
      theme: json['theme'] as String?,
      meetingDate: json['meetingDate'] != null
          ? DateTime.parse(json['meetingDate'] as String)
          : DateTime.now(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      speakerCount: json['speakerCount'] as int?,
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
      'id': id,
      if (clubId != null) 'clubId': clubId,
      if (meetingNumber != null) 'meetingNumber': meetingNumber,
      if (theme != null) 'theme': theme,
      'meetingDate': meetingDate.toIso8601String().split('T')[0],
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (location != null) 'location': location,
      'status': status,
      if (speakerCount != null) 'speakerCount': speakerCount,
      if (notes != null) 'notes': notes,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'DRAFT':
        return 'Draft';
      case 'OPEN':
        return 'Open for Sign-up';
      case 'CLOSED':
        return 'Closed';
      case 'FINALIZED':
        return 'Finalized';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
