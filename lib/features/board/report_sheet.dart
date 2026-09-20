import 'package:flutter/material.dart';

import 'models.dart';

/// 신고 사유를 고르는 바텀시트. 취소하면 null.
Future<ReportReason?> showReportSheet(BuildContext context) {
  return showModalBottomSheet<ReportReason>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              '신고 사유를 선택해 주세요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final reason in ReportReason.values)
            ListTile(
              title: Text(reason.label),
              onTap: () => Navigator.of(context).pop(reason),
            ),
        ],
      ),
    ),
  );
}

/// 확인 다이얼로그. 확인하면 true.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
