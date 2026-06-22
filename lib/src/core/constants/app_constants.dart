import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Domain constants mirrored from the web app (`src/app/lib/constants.ts`).
abstract class AppConstants {
  /// Industry roles a creator can fill or hire for.
  static const List<String> roles = [
    'Actor',
    'Cinematographer',
    'Editor',
    'Music Composer',
    'Production Designer',
    'Assistant Director',
    'Producer',
  ];

  /// Full project status lifecycle, in pipeline order.
  static const List<String> projectStatuses = [
    'Script Under Review',
    'Script Approved',
    'Script Rejected',
    'Team Building Stage',
    'Team Completed',
    'Ready For Trailer Submission',
    'Trailer Submitted',
    'Under Screening',
    'Selected For Show',
    'Confirm Participation',
    'Payment Confirmed',
    'Show Confirmed',
  ];

  /// Application lifecycle states.
  static const List<String> applicationStatuses = [
    'Applied',
    'Shortlisted',
    'Selected',
    'Rejected',
  ];

  /// Current NDA version recorded on acceptance.
  static const String ndaVersion = '1.0';
}

/// Maps a project status to its accent colour (mirrors STATUS_COLORS on web).
Color projectStatusColor(String status) {
  switch (status) {
    case 'Script Under Review':
      return AppColors.statusReview;
    case 'Script Approved':
    case 'Team Completed':
      return AppColors.statusApproved;
    case 'Script Rejected':
      return AppColors.statusRejected;
    case 'Team Building Stage':
      return AppColors.statusInfo;
    case 'Ready For Trailer Submission':
      return const Color(0xFFEAB308);
    case 'Trailer Submitted':
      return AppColors.statusCyan;
    case 'Under Screening':
      return AppColors.statusPurple;
    case 'Selected For Show':
    case 'Confirm Participation':
    case 'Show Confirmed':
      return AppColors.gold;
    case 'Payment Confirmed':
      return AppColors.statusEmerald;
    default:
      return AppColors.textMuted;
  }
}

/// Maps an application status to its accent colour.
Color applicationStatusColor(String status) {
  switch (status) {
    case 'Applied':
      return AppColors.statusInfo;
    case 'Shortlisted':
      return AppColors.statusReview;
    case 'Selected':
      return AppColors.statusApproved;
    case 'Rejected':
      return AppColors.statusRejected;
    default:
      return AppColors.textMuted;
  }
}
