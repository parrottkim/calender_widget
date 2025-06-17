import 'package:calender_widget/calendar.dart';
import 'package:flutter/material.dart';

class DateRangeDialog extends StatefulWidget {
  // StatefulWidget으로 변경
  final DateTime? start;
  final DateTime? end;

  const DateRangeDialog({super.key, required this.start, required this.end});

  @override
  State<DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<DateRangeDialog> {
  // State 클래스 생성
  // State 변수로 tempStart와 tempEnd를 선언합니다.
  DateTime? _tempStart; // ValueNotifier 대신 직접 DateTime? 변수 사용
  DateTime? _tempEnd; // ValueNotifier 대신 직접 DateTime? 변수 사용

  @override
  void initState() {
    super.initState();
    // 초기값 설정 (선택 사항: 기존에 선택된 날짜가 있다면 불러옵니다)
    _tempStart = widget.start;
    _tempEnd = widget.end;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceBright,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        constraints: const BoxConstraints(maxWidth: 400.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8.0),
            Calendar.range(
              initialStartDate: widget.start,
              initialEndDate: widget.end,
              onDateRangeSelected: (value) {
                setState(() {
                  _tempStart = value.start;
                  _tempEnd = value.end;
                });
              },
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed:
                      _tempStart != null && _tempEnd != null
                          ? () => Navigator.pop(context, [_tempStart, _tempEnd])
                          : null,
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
