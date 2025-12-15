/// Club Officer model for ToastLabPlus
class ClubOfficer {
  final int? officerId;
  final String position;
  final String positionDisplay;
  final bool isFilled;
  final int? memberId;
  final String? memberName;
  final String? memberEmail;
  final String? memberAvatarUrl;
  final DateTime? termStart;
  final DateTime? termEnd;

  ClubOfficer({
    this.officerId,
    required this.position,
    required this.positionDisplay,
    required this.isFilled,
    this.memberId,
    this.memberName,
    this.memberEmail,
    this.memberAvatarUrl,
    this.termStart,
    this.termEnd,
  });

  factory ClubOfficer.fromJson(Map<String, dynamic> json) {
    return ClubOfficer(
      officerId: json['officerId'] as int?,
      position: json['position'] as String? ?? '',
      positionDisplay: json['positionDisplay'] as String? ?? '',
      isFilled: json['isFilled'] as bool? ?? false,
      memberId: json['memberId'] as int?,
      memberName: json['memberName'] as String?,
      memberEmail: json['memberEmail'] as String?,
      memberAvatarUrl: json['memberAvatarUrl'] as String?,
      termStart: json['termStart'] != null
          ? DateTime.tryParse(json['termStart'] as String)
          : null,
      termEnd: json['termEnd'] != null
          ? DateTime.tryParse(json['termEnd'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (officerId != null) 'officerId': officerId,
      'position': position,
      'positionDisplay': positionDisplay,
      'isFilled': isFilled,
      if (memberId != null) 'memberId': memberId,
      if (memberName != null) 'memberName': memberName,
      if (memberEmail != null) 'memberEmail': memberEmail,
      if (memberAvatarUrl != null) 'memberAvatarUrl': memberAvatarUrl,
      if (termStart != null)
        'termStart': termStart!.toIso8601String().split('T')[0],
      if (termEnd != null) 'termEnd': termEnd!.toIso8601String().split('T')[0],
    };
  }

  /// Get icon for position
  String get positionIcon {
    switch (position) {
      case 'PRESIDENT':
        return '👑';
      case 'VPE':
        return '📚';
      case 'VPM':
        return '👥';
      case 'VPPR':
        return '📢';
      case 'SECRETARY':
        return '📝';
      case 'TREASURER':
        return '💰';
      case 'SAA':
        return '🎖️';
      default:
        return '👤';
    }
  }
}
