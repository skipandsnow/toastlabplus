import 'package:flutter/material.dart';

class RoleSlot {
  final int id;
  final String roleName;
  final String displayName;
  final int slotIndex;
  final bool isAssigned;
  final int? memberId;
  final String? memberName;
  final String? memberEmail;
  final String? memberAvatarUrl;
  final String? speechTitle;
  final String? projectName;

  RoleSlot({
    required this.id,
    required this.roleName,
    required this.displayName,
    required this.slotIndex,
    required this.isAssigned,
    this.memberId,
    this.memberName,
    this.memberEmail,
    this.memberAvatarUrl,
    this.speechTitle,
    this.projectName,
  });

  factory RoleSlot.fromJson(Map<String, dynamic> json) {
    return RoleSlot(
      id: json['id'] as int,
      roleName: json['roleName'] as String,
      displayName: json['displayName'] as String? ?? json['roleName'] as String,
      slotIndex: json['slotIndex'] as int? ?? 1,
      isAssigned: json['isAssigned'] as bool? ?? false,
      memberId: json['memberId'] as int?,
      memberName: json['memberName'] as String?,
      memberEmail: json['memberEmail'] as String?,
      memberAvatarUrl: json['memberAvatarUrl'] as String?,
      speechTitle: json['speechTitle'] as String?,
      projectName: json['projectName'] as String?,
    );
  }

  IconData get roleIcon {
    switch (roleName) {
      case 'TME':
        return Icons.mic;
      case 'TIMER':
        return Icons.timer;
      case 'AH_COUNTER':
        return Icons.record_voice_over;
      case 'GRAMMARIAN':
        return Icons.spellcheck;
      case 'GE':
        return Icons.rate_review;
      case 'LE':
        return Icons.language;
      case 'SPEAKER':
        return Icons.record_voice_over;
      case 'EVALUATOR':
        return Icons.comment;
      case 'TT_MASTER':
        return Icons.question_answer;
      case 'SESSION_MASTER':
        return Icons.event;
      case 'PHOTOGRAPHER':
        return Icons.camera_alt;
      default:
        return Icons.person;
    }
  }
}
