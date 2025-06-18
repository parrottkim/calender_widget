import 'package:calender_widget/calendar.dart';
import 'package:flutter/material.dart';

class DateRangeDialog extends StatefulWidget {
  final DateTime? start;
  final DateTime? end;

  const DateRangeDialog({super.key, required this.start, required this.end});

  @override
  State<DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<DateRangeDialog> {
  DateTime? _tempStart;
  DateTime? _tempEnd;

  @override
  void initState() {
    super.initState();
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
            SizedBox(
              height: 350.0,
              child: Calendar.range(
                initialStartDate: widget.start,
                initialEndDate: widget.end,
                onDateRangeSelected: (value) {
                  setState(() {
                    _tempStart = value.start;
                    _tempEnd = value.end;
                  });
                },
              ),
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
