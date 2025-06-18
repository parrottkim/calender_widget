import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Defines the selection mode for the calendar.
///
/// This enum is internal and not exposed publicly.
enum SelectionMode {
  /// Allows selection of a single date.
  day,

  /// Allows selection of a range of dates.
  range,
}

/// Defines the current view mode of the calendar.
enum CalendarViewMode {
  /// Day view, showing a grid of days for a specific month.
  day,

  /// Month view, showing 12 months for a specific year.
  month,

  /// Year view, showing a decade of years.
  year,
}

/// A customizable calendar widget for selecting single dates or date ranges.
///
/// Use [Calendar.day] for single date selection and [Calendar.range] for
/// date range selection.
class Calendar extends StatefulWidget {
  final SelectionMode _mode; // Internal selection mode
  final DateTime? initialSelectedDate;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final ValueChanged<DateTime>? onDateSelected;
  final ValueChanged<DateTimeRange>? onDateRangeSelected;

  /// Private constructor to prevent direct instantiation.
  const Calendar._({
    super.key,
    required SelectionMode mode,
    this.initialSelectedDate,
    this.initialStartDate,
    this.initialEndDate,
    this.onDateSelected,
    this.onDateRangeSelected,
  }) : _mode = mode;

  /// Creates a calendar widget for single date selection.
  ///
  /// [initialSelectedDate] is the initially selected date.
  /// [onDateSelected] is the callback when a date is selected.
  factory Calendar.day({
    Key? key,
    DateTime? initialSelectedDate,
    ValueChanged<DateTime>? onDateSelected,
  }) {
    return Calendar._(
      key: key,
      mode: SelectionMode.day,
      initialSelectedDate: initialSelectedDate,
      onDateSelected: onDateSelected,
    );
  }

  /// Creates a calendar widget for date range selection.
  ///
  /// [initialStartDate] is the initially selected start date of the range.
  /// [initialEndDate] is the initially selected end date of the range.
  /// [onDateRangeSelected] is the callback when a date range is selected.
  factory Calendar.range({
    Key? key,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    ValueChanged<DateTimeRange>? onDateRangeSelected,
  }) {
    return Calendar._(
      key: key,
      mode: SelectionMode.range,
      initialStartDate: initialStartDate,
      initialEndDate: initialEndDate,
      onDateRangeSelected: onDateRangeSelected,
    );
  }

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late CalendarViewMode _currentViewMode;

  // Page controllers for each view mode
  late PageController _dayPageController;
  late PageController _monthPageController;
  late PageController _yearPageController;

  // Min and max years for the calendar (adjust as needed)
  final int _minYear = 1900;
  final int _maxYear = 2100;

  @override
  void initState() {
    super.initState();
    _focusedDay =
        widget.initialSelectedDate ?? widget.initialStartDate ?? DateTime.now();
    _selectedDay = widget.initialSelectedDate;
    _rangeStart = widget.initialStartDate;
    _rangeEnd = widget.initialEndDate;
    _currentViewMode = CalendarViewMode.day;

    // PageController 초기화는 initState에서 이루어져야 합니다.
    _initializePageControllers();

    if (widget._mode == SelectionMode.range &&
        _rangeStart != null &&
        _rangeEnd != null &&
        _rangeStart!.isAfter(_rangeEnd!)) {
      final temp = _rangeStart;
      _rangeStart = _rangeEnd;
      _rangeEnd = temp;
    }
  }

  @override
  void didUpdateWidget(covariant Calendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool shouldUpdateFocusedDay = false;

    if (widget.initialSelectedDate != oldWidget.initialSelectedDate) {
      _selectedDay = widget.initialSelectedDate;
      if (widget.initialSelectedDate != null) {
        _focusedDay = widget.initialSelectedDate!;
        shouldUpdateFocusedDay = true;
      }
    }
    if (widget.initialStartDate != oldWidget.initialStartDate ||
        widget.initialEndDate != oldWidget.initialEndDate) {
      _rangeStart = widget.initialStartDate;
      _rangeEnd = widget.initialEndDate;
      if (widget.initialStartDate != null) {
        _focusedDay = widget.initialStartDate!;
        shouldUpdateFocusedDay = true;
      }
    }

    // 만약 _focusedDay가 변경되었다면, 다음 프레임에서 컨트롤러를 업데이트하도록 스케줄링합니다.
    if (shouldUpdateFocusedDay) {
      _schedulePageControllerUpdate();
    }
  }

  /// Initializes the PageControllers with their initial pages.
  void _initializePageControllers() {
    // PageController 초기화 시에는 .page에 접근하지 않으므로 안전합니다.
    _dayPageController = PageController(
      initialPage: (_focusedDay.year - _minYear) * 12 + _focusedDay.month - 1,
    );
    _monthPageController = PageController(
      initialPage: _focusedDay.year - _minYear,
    );
    _yearPageController = PageController(
      initialPage: (_focusedDay.year - _minYear) ~/ 10,
    );
  }

  /// Updates the PageControllers to animate to the correct page when `_focusedDay` changes.
  /// This should be called within setState or didUpdateWidget when _focusedDay is updated.
  /// Using addPostFrameCallback ensures the PageView has been built.
  void _schedulePageControllerUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void updateController(PageController controller, int targetPage) {
        if (controller.hasClients) {
          // Check if it's already on the target page to avoid unnecessary jumps/animations
          if (controller.page?.round() != targetPage) {
            controller.jumpToPage(
              targetPage,
            ); // Use jumpToPage for instant change
          }
        }
      }

      if (_currentViewMode == CalendarViewMode.day) {
        final int targetPage =
            (_focusedDay.year - _minYear) * 12 + _focusedDay.month - 1;
        updateController(_dayPageController, targetPage);
      } else if (_currentViewMode == CalendarViewMode.month) {
        final int targetPage = _focusedDay.year - _minYear;
        updateController(_monthPageController, targetPage);
      } else if (_currentViewMode == CalendarViewMode.year) {
        final int targetPage = (_focusedDay.year - _minYear) ~/ 10;
        updateController(_yearPageController, targetPage);
      }
    });
  }

  @override
  void dispose() {
    _dayPageController.dispose();
    _monthPageController.dispose();
    _yearPageController.dispose();
    super.dispose();
  }

  /// Helper to check if two dates are the same day (ignoring time).
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Helper to check if two dates are in the same month (ignoring day and time).
  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  /// Helper to check if two dates are in the same year (ignoring month, day and time).
  bool _isSameYear(DateTime a, DateTime b) {
    return a.year == b.year;
  }

  /// Builds the calendar header displaying the current month/year/decade
  /// and navigation buttons.
  Widget _buildHeader() {
    final currentLocale = Localizations.localeOf(context).languageCode;
    String headerText;
    VoidCallback? onHeaderTap;
    VoidCallback? onLeftArrowTap;
    VoidCallback? onRightArrowTap;

    switch (_currentViewMode) {
      case CalendarViewMode.day:
        headerText = DateFormat.yMMMM(currentLocale).format(_focusedDay);
        onHeaderTap = () {
          setState(() {
            _currentViewMode = CalendarViewMode.month;
            // 월 뷰로 갈 때는 년도만 유지하고 월은 1월로 설정 (월 뷰의 시작점을 명확히 하기 위함)
            _focusedDay = DateTime(_focusedDay.year, 1, 1);
            _schedulePageControllerUpdate(); // 다음 프레임에서 컨트롤러 업데이트 스케줄링
          });
        };
        onLeftArrowTap = () {
          if (_dayPageController.hasClients) {
            _dayPageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        };
        onRightArrowTap = () {
          if (_dayPageController.hasClients) {
            _dayPageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        };
        break;
      case CalendarViewMode.month:
        headerText = DateFormat.y(currentLocale).format(_focusedDay);
        onHeaderTap = () {
          setState(() {
            _currentViewMode = CalendarViewMode.year;
            // 년도 뷰로 갈 때는 10년 단위의 시작 년도로 설정
            _focusedDay = DateTime((_focusedDay.year ~/ 10) * 10, 1, 1);
            _schedulePageControllerUpdate(); // 다음 프레임에서 컨트롤러 업데이트 스케줄링
          });
        };
        onLeftArrowTap = () {
          if (_monthPageController.hasClients) {
            _monthPageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        };
        onRightArrowTap = () {
          if (_monthPageController.hasClients) {
            _monthPageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        };
        break;
      case CalendarViewMode.year:
        final startYear = (_focusedDay.year ~/ 10) * 10;
        final endYear = startYear + 9;
        headerText = '$startYear - $endYear';
        onHeaderTap = null; // No higher view to navigate to from year view
        onLeftArrowTap = () {
          if (_yearPageController.hasClients) {
            _yearPageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        };
        onRightArrowTap = () {
          if (_yearPageController.hasClients) {
            _yearPageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        };
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Symbols.chevron_left_rounded),
            onPressed: onLeftArrowTap,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          InkWell(
            onTap: onHeaderTap,
            borderRadius: BorderRadius.circular(4.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Text(
                headerText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Symbols.chevron_right_rounded),
            onPressed: onRightArrowTap,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  /// Builds the row of weekday names (Sun, Mon, Tue, etc.).
  Widget _buildWeekDays() {
    final currentLocale = Localizations.localeOf(context).languageCode;

    if (_currentViewMode != CalendarViewMode.day) {
      return const SizedBox.shrink(); // 일별 뷰가 아니면 숨김
    }
    final List<String> displayWeekDays = [];

    for (int i = 0; i < 7; i++) {
      DateTime date = DateTime(2024, 1, 7).add(Duration(days: i));
      displayWeekDays.add(DateFormat.E(currentLocale).format(date));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children:
          displayWeekDays.map((day) {
            return Expanded(
              child: Container(
                // buildDaysGrid와 동일한 간격 적용을 위해 Container 추가
                margin: const EdgeInsets.all(2.0), // buildDaysGrid의 셀과 동일한 마진
                alignment: Alignment.center,
                child: Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  /// Handles the selection of a date based on the current [SelectionMode].
  void _onDaySelected(DateTime day) {
    setState(() {
      final int targetPage = (day.year - _minYear) * 12 + day.month - 1;
      if (_dayPageController.hasClients) {
        _dayPageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      if (widget._mode == SelectionMode.day) {
        _selectedDay = day;
        widget.onDateSelected?.call(day);
      } else if (widget._mode == SelectionMode.range) {
        if (_rangeStart == null || _rangeEnd != null) {
          // Start a new range or reset if a range was already completed
          _rangeStart = day;
          _rangeEnd = null;
        } else {
          // If rangeStart exists, set rangeEnd
          if (day.isBefore(_rangeStart!)) {
            // If selected day is before start, swap them
            _rangeEnd = _rangeStart;
            _rangeStart = day;
          } else {
            _rangeEnd = day;
          }
          if (_rangeStart != null && _rangeEnd != null) {
            widget.onDateRangeSelected?.call(
              DateTimeRange(start: _rangeStart!, end: _rangeEnd!),
            );
          }
        }
      }
      // 선택된 날짜에 맞춰 _focusedDay 업데이트
      final newFocusedDay = DateTime(day.year, day.month, 1);
      if (!_isSameMonth(_focusedDay, newFocusedDay)) {
        // 월이 변경되었을 때만 업데이트
        _focusedDay = newFocusedDay;
      }
    });
  }

  /// Builds the grid of years for the [CalendarViewMode.year].
  Widget _buildYearsGrid() {
    final int totalDecades = (_maxYear - _minYear) ~/ 10 + 1;

    /// Helper to check if a year is within the selected range.
    bool isYearInRange(int year) {
      if (widget._mode != SelectionMode.range || _rangeStart == null) {
        return false;
      }

      final DateTime start = _rangeStart!;
      final DateTime end = _rangeEnd ?? start;

      final DateTime yearStart = DateTime(year, 1, 1);
      final DateTime yearEnd = DateTime(year, 12, 31);

      return (yearStart.isBefore(end) || _isSameDay(yearStart, end)) &&
          (yearEnd.isAfter(start) || _isSameDay(yearEnd, start));
    }

    /// Helper to check if a year is the start of the selected range.
    bool isYearRangeStart(int year) {
      if (widget._mode != SelectionMode.range || _rangeStart == null) {
        return false;
      }
      return year == _rangeStart!.year;
    }

    /// Helper to check if a year is the end of the selected range.
    bool isYearRangeEnd(int year) {
      if (widget._mode != SelectionMode.range || _rangeEnd == null) {
        return false;
      }
      return year == _rangeEnd!.year;
    }

    return PageView.builder(
      controller: _yearPageController,
      itemCount: totalDecades,
      onPageChanged: (pageIndex) {
        setState(() {
          final newStartYear = _minYear + pageIndex * 10;
          _focusedDay = DateTime(newStartYear, _focusedDay.month, 1);
        });
      },
      itemBuilder: (context, pageIndex) {
        final int startYearInDecade = _minYear + pageIndex * 10;
        final List<int> years = List.generate(10, (i) => startYearInDecade + i);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
          ),
          itemCount: years.length,
          itemBuilder: (context, idx) {
            final year = years[idx];

            final bool isTodayYear = year == DateTime.now().year;
            final bool isInRange = isYearInRange(year);
            final bool isRangeStart = isYearRangeStart(year);
            final bool isRangeEnd = isYearRangeEnd(year);

            BoxDecoration backgroundDecoration = const BoxDecoration();
            BoxDecoration foregroundDecoration = const BoxDecoration();
            BoxDecoration todayDecoration = const BoxDecoration();

            Color textColor = Theme.of(context).colorScheme.onSurface;

            if (isTodayYear) {
              todayDecoration = BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color:
                      isRangeStart || isRangeEnd
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary,
                ),
              );
              textColor = Theme.of(context).colorScheme.primary;
            }

            if (widget._mode == SelectionMode.range) {
              if (isRangeStart) {
                foregroundDecoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Theme.of(context).colorScheme.primary,
                );
                backgroundDecoration = BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(50.0),
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                );
                textColor = Theme.of(context).colorScheme.onPrimary;
              } else if (isRangeEnd) {
                foregroundDecoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Theme.of(context).colorScheme.primary,
                );
                backgroundDecoration = BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(50.0),
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                );
                textColor = Theme.of(context).colorScheme.onPrimary;
              } else if (isInRange) {
                backgroundDecoration = BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                );
                textColor = Theme.of(context).colorScheme.primary;
              }
            }

            EdgeInsets cellPadding;
            if (widget._mode == SelectionMode.range && isInRange) {
              if (isRangeStart && !isRangeEnd) {
                // Start of range but not a single day selection
                cellPadding = const EdgeInsets.only(
                  top: 8.0,
                  bottom: 8.0,
                  left: 8.0,
                  right: 0.0,
                );
              } else if (isRangeEnd && !isRangeStart) {
                // End of range but not a single day selection
                cellPadding = const EdgeInsets.only(
                  top: 8.0,
                  bottom: 8.0,
                  left: 0.0,
                  right: 8.0,
                );
              } else if (isRangeStart && isRangeEnd) {
                // Start and end of range (single day selected)
                cellPadding = const EdgeInsets.all(8.0); // Uniform padding
              } else {
                // Middle of range
                cellPadding = const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 0.0,
                );
              }
            } else {
              cellPadding = const EdgeInsets.all(8.0);
            }

            return InkWell(
              onTap: () {
                setState(() {
                  _focusedDay = DateTime(year, 1, 1);
                  _currentViewMode = CalendarViewMode.month;
                  _schedulePageControllerUpdate();
                });
              },
              borderRadius: BorderRadius.circular(8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: cellPadding,
                    decoration: backgroundDecoration,
                  ),
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: foregroundDecoration,
                  ),
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: todayDecoration,
                  ),
                  Text(
                    '$year',
                    style: TextStyle(
                      color: textColor,
                      fontWeight:
                          (isTodayYear || isRangeStart || isRangeEnd)
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the grid of months for the [CalendarViewMode.month].
  Widget _buildMonthsGrid() {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final int totalYears = _maxYear - _minYear + 1;

    /// Helper to check if a month is within the selected range.
    bool isMonthInRange(DateTime monthDate) {
      if (widget._mode != SelectionMode.range || _rangeStart == null) {
        return false;
      }

      final DateTime start = _rangeStart!;
      final DateTime end =
          _rangeEnd ??
          start; // If _rangeEnd is null, assume it's the same as start

      final DateTime monthStart = DateTime(monthDate.year, monthDate.month, 1);
      final DateTime monthEnd = DateTime(
        monthDate.year,
        monthDate.month + 1,
        0,
      ); // Last day of the month

      return (monthStart.isBefore(end) || _isSameDay(monthStart, end)) &&
          (monthEnd.isAfter(start) || _isSameDay(monthEnd, start));
    }

    /// Helper to check if a month is the start of the selected range.
    bool isMonthRangeStart(DateTime monthDate) {
      if (widget._mode != SelectionMode.range || _rangeStart == null) {
        return false;
      }
      return monthDate.year == _rangeStart!.year &&
          monthDate.month == _rangeStart!.month;
    }

    /// Helper to check if a month is the end of the selected range.
    bool isMonthRangeEnd(DateTime monthDate) {
      if (widget._mode != SelectionMode.range || _rangeEnd == null) {
        return false;
      }
      return monthDate.year == _rangeEnd!.year &&
          monthDate.month == _rangeEnd!.month;
    }

    return PageView.builder(
      controller: _monthPageController,
      itemCount: totalYears,
      onPageChanged: (pageIndex) {
        setState(() {
          final newYear = _minYear + pageIndex;
          _focusedDay = DateTime(newYear, _focusedDay.month, 1);
        });
      },
      itemBuilder: (context, pageIndex) {
        final int yearToShow = _minYear + pageIndex;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final monthDate = DateTime(yearToShow, index + 1, 1);

            // Calculate states
            final bool isTodayMonth =
                monthDate.year == DateTime.now().year &&
                monthDate.month == DateTime.now().month;

            final bool isInRange = isMonthInRange(monthDate);
            final bool isRangeStart = isMonthRangeStart(monthDate);
            final bool isRangeEnd = isMonthRangeEnd(monthDate);

            // Define decoration layers
            BoxDecoration backgroundDecoration = const BoxDecoration();
            BoxDecoration foregroundDecoration = const BoxDecoration();
            BoxDecoration todayDecoration = const BoxDecoration();

            Color textColor = Theme.of(context).colorScheme.onSurface;

            if (isTodayMonth) {
              todayDecoration = BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color:
                      isRangeStart || isRangeEnd
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary,
                ),
              );
              textColor = Theme.of(context).colorScheme.primary;
            }

            if (widget._mode == SelectionMode.range) {
              if (isRangeStart) {
                foregroundDecoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Theme.of(context).colorScheme.primary,
                );
                backgroundDecoration = BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(50.0),
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                );
                textColor = Theme.of(context).colorScheme.onPrimary;
              } else if (isRangeEnd) {
                foregroundDecoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Theme.of(context).colorScheme.primary,
                );
                backgroundDecoration = BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(50.0),
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                );
                textColor = Theme.of(context).colorScheme.onPrimary;
              } else if (isInRange) {
                backgroundDecoration = BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                );
                textColor = Theme.of(context).colorScheme.primary;
              }
            }

            EdgeInsets cellPadding;
            if (widget._mode == SelectionMode.range && isInRange) {
              if (isRangeStart && !isRangeEnd) {
                // Start of range but not a single day selection
                cellPadding = const EdgeInsets.only(
                  top: 8.0,
                  bottom: 8.0,
                  left: 8.0,
                  right: 0.0,
                );
              } else if (isRangeEnd && !isRangeStart) {
                // End of range but not a single day selection
                cellPadding = const EdgeInsets.only(
                  top: 8.0,
                  bottom: 8.0,
                  left: 0.0,
                  right: 8.0,
                );
              } else if (isRangeStart && isRangeEnd) {
                // Start and end of range (single day selected)
                cellPadding = const EdgeInsets.all(8.0); // Uniform padding
              } else {
                // Middle of range
                cellPadding = const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 0.0,
                );
              }
            } else {
              cellPadding = const EdgeInsets.all(8.0);
            }

            return InkWell(
              onTap: () {
                setState(() {
                  _focusedDay = monthDate;
                  _currentViewMode = CalendarViewMode.day;
                  _schedulePageControllerUpdate();
                });
              },
              borderRadius: BorderRadius.circular(8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background for range selection
                  Container(
                    margin: cellPadding,
                    decoration: backgroundDecoration,
                  ),
                  // Foreground for selected month
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: foregroundDecoration,
                  ),
                  // Border for today's month
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: todayDecoration,
                  ),
                  // Month text
                  Text(
                    DateFormat.MMM(currentLocale).format(monthDate),
                    style: TextStyle(
                      color: textColor,
                      fontWeight:
                          (isTodayMonth || isRangeStart || isRangeEnd)
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the grid of days for the [CalendarViewMode.day].
  Widget _buildDaysGrid() {
    final int totalMonths = (_maxYear - _minYear + 1) * 12;

    /// Helper to check if a day is within the selected range.
    bool isDayInRange(DateTime dayDate) {
      if (widget._mode != SelectionMode.range || _rangeStart == null) {
        return false;
      }

      final DateTime start = _rangeStart!;
      final DateTime end =
          _rangeEnd ??
          start; // If _rangeEnd is null, assume it's the same as start

      return (dayDate.isAfter(start) || _isSameDay(dayDate, start)) &&
          (dayDate.isBefore(end) || _isSameDay(dayDate, end));
    }

    /// Helper to check if a day is the start of the selected range.
    bool isDayRangeStart(DateTime dayDate) {
      if (widget._mode != SelectionMode.range || _rangeStart == null) {
        return false;
      }
      return _isSameDay(dayDate, _rangeStart!);
    }

    /// Helper to check if a day is the end of the selected range.
    bool isDayRangeEnd(DateTime dayDate) {
      if (widget._mode != SelectionMode.range || _rangeEnd == null) {
        return false;
      }
      return _isSameDay(dayDate, _rangeEnd!);
    }

    /// Helper to check if a day is selected in single day selection mode.
    bool isDaySelected(DateTime dayDate) {
      if (widget._mode != SelectionMode.day || _selectedDay == null) {
        return false;
      }
      return _isSameDay(dayDate, _selectedDay!);
    }

    return PageView.builder(
      controller: _dayPageController,
      itemCount: totalMonths,
      onPageChanged: (pageIndex) {
        setState(() {
          final int year = _minYear + (pageIndex ~/ 12);
          final int month = (pageIndex % 12) + 1;
          _focusedDay = DateTime(year, month, 1);
          // _updatePageControllers() is not needed here
        });
      },
      itemBuilder: (context, pageIndex) {
        final int year = _minYear + (pageIndex ~/ 12);
        final int month = (pageIndex % 12) + 1;
        final DateTime monthToDisplay = DateTime(year, month, 1);

        final DateTime firstDayOfMonth = DateTime(
          monthToDisplay.year,
          monthToDisplay.month,
          1,
        );
        // Adjust firstDayWeekday to make Sunday the first day (0-indexed)
        final int firstDayWeekday = firstDayOfMonth.weekday % 7;

        final DateTime startDay = firstDayOfMonth.subtract(
          Duration(days: firstDayWeekday),
        );

        final DateTime lastDayOfMonth = DateTime(
          monthToDisplay.year,
          monthToDisplay.month + 1,
          0,
        );

        final int totalDays = (lastDayOfMonth.difference(startDay).inDays + 1);
        final int numRows = (totalDays / 7).ceil();
        final int gridCellCount = numRows * 7;

        final List<DateTime> days = List.generate(gridCellCount, (index) {
          return startDay.add(Duration(days: index));
        });

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final bool isToday = _isSameDay(day, DateTime.now());
            final bool isCurrentMonth = day.month == monthToDisplay.month;

            // Use helper functions to determine selection/range states
            final bool isSelected = isDaySelected(day);
            final bool isInRange = isDayInRange(day);
            final bool isRangeStart = isDayRangeStart(day);
            final bool isRangeEnd = isDayRangeEnd(day);

            BoxDecoration todayDecoration = const BoxDecoration();
            BoxDecoration foregroundDecoration = const BoxDecoration();
            BoxDecoration backgroundDecoration = const BoxDecoration();

            Color textColor =
                isCurrentMonth
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4);

            if (isToday) {
              todayDecoration = BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color:
                      isRangeStart || isRangeEnd
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary,
                ),
              );
              textColor = Theme.of(context).colorScheme.primary;
            }

            if (widget._mode == SelectionMode.day && isSelected) {
              foregroundDecoration = BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: Theme.of(context).colorScheme.primary,
              );
              textColor = Theme.of(context).colorScheme.onPrimary;
            } else if (widget._mode == SelectionMode.range) {
              if (isRangeStart &&
                  isRangeEnd &&
                  _rangeStart != null &&
                  _rangeEnd != null &&
                  _isSameDay(_rangeStart!, _rangeEnd!)) {
                // If start and end are the same (single day range selection)
                foregroundDecoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Theme.of(context).colorScheme.primary,
                );
                textColor = Theme.of(context).colorScheme.onPrimary;
              } else if (isRangeStart) {
                foregroundDecoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Theme.of(context).colorScheme.primary,
                );
                if (_rangeStart != null && _rangeEnd != null) {
                  backgroundDecoration = BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(50.0),
                    ),
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                  );
                }
                textColor = Theme.of(context).colorScheme.onPrimary;
              } else if (isRangeEnd) {
                foregroundDecoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Theme.of(context).colorScheme.primary,
                );
                backgroundDecoration = BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(50.0),
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                );
                textColor = Theme.of(context).colorScheme.onPrimary;
              } else if (isInRange) {
                backgroundDecoration = BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                );
                textColor = Theme.of(context).colorScheme.primary;
              }
            }

            EdgeInsets cellPadding;
            if (widget._mode == SelectionMode.range && isInRange) {
              if (isRangeStart && !isRangeEnd) {
                // Start of range but not a single day selection
                cellPadding = const EdgeInsets.only(
                  top: 8.0,
                  bottom: 8.0,
                  left: 8.0,
                  right: 0.0,
                );
              } else if (isRangeEnd && !isRangeStart) {
                // End of range but not a single day selection
                cellPadding = const EdgeInsets.only(
                  top: 8.0,
                  bottom: 8.0,
                  left: 0.0,
                  right: 8.0,
                );
              } else if (isRangeStart && isRangeEnd) {
                // Start and end of range (single day selected)
                cellPadding = const EdgeInsets.all(8.0); // Uniform padding
              } else {
                // Middle of range
                cellPadding = const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 0.0,
                );
              }
            } else {
              cellPadding = const EdgeInsets.all(8.0);
            }

            return InkWell(
              onTap: () => _onDaySelected(day),
              customBorder: const CircleBorder(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: cellPadding,
                    decoration: backgroundDecoration,
                  ),
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: foregroundDecoration,
                  ),
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: todayDecoration,
                  ),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight:
                          (isToday || isSelected || isRangeStart || isRangeEnd)
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // _updatePageControllers() is now only called when _focusedDay or _currentViewMode changes via setState
    // This removes the redundant scheduling in every build cycle.
    return Column(
      children: [
        _buildHeader(), // Calendar header (month/year display and navigation buttons)
        _buildWeekDays(), // Weekday display (Sun, Mon, Tue, etc.)
        Expanded(
          child: AnimatedSwitcher(
            // Animation for view mode transitions (day, month, year)
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Builder(
              // Display the appropriate grid widget based on the current view mode
              key: ValueKey<CalendarViewMode>(_currentViewMode),
              builder: (context) {
                switch (_currentViewMode) {
                  case CalendarViewMode.day:
                    return _buildDaysGrid();
                  case CalendarViewMode.month:
                    return _buildMonthsGrid();
                  case CalendarViewMode.year:
                    return _buildYearsGrid();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
