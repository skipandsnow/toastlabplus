class MeetingSchedule {
  final int id;
  final String? name;
  final String frequency;
  final int? dayOfWeek;
  final List<int>? weekOfMonth;
  final String startTime;
  final String endTime;
  final int defaultSpeakerCount;
  final String? defaultLocation;
  final int autoGenerateMonths;

  MeetingSchedule({
    required this.id,
    this.name,
    required this.frequency,
    this.dayOfWeek,
    this.weekOfMonth,
    required this.startTime,
    required this.endTime,
    this.defaultSpeakerCount = 3,
    this.defaultLocation,
    this.autoGenerateMonths = 3,
  });

  factory MeetingSchedule.fromJson(Map<String, dynamic> json) {
    return MeetingSchedule(
      id: json['id'] as int,
      name: json['name'] as String?,
      frequency: json['frequency'] as String,
      dayOfWeek: json['dayOfWeek'] as int?,
      weekOfMonth: (json['weekOfMonth'] as List<dynamic>?)?.cast<int>(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      defaultSpeakerCount: json['defaultSpeakerCount'] as int? ?? 3,
      defaultLocation: json['defaultLocation'] as String?,
      autoGenerateMonths: json['autoGenerateMonths'] as int? ?? 3,
    );
  }

  String get frequencyDisplay {
    switch (frequency) {
      case 'WEEKLY':
        return 'Every Week';
      case 'BIWEEKLY':
        return 'Every 2 Weeks';
      case 'MONTHLY':
        return 'Monthly';
      default:
        return frequency;
    }
  }

  String get dayOfWeekDisplay {
    if (dayOfWeek == null) return '';
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayOfWeek!];
  }

  String get scheduleDescription {
    if (frequency == 'MONTHLY' &&
        weekOfMonth != null &&
        weekOfMonth!.isNotEmpty) {
      final weeks = weekOfMonth!.map((w) => _ordinal(w)).join(' & ');
      return '$weeks $dayOfWeekDisplay of each month';
    }
    return '$frequencyDisplay on $dayOfWeekDisplay';
  }

  String _ordinal(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }
}
