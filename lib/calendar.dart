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
    Key? key,
    required SelectionMode mode,
    this.initialSelectedDate,
    this.initialStartDate,
    this.initialEndDate,
    this.onDateSelected,
    this.onDateRangeSelected,
  }) : _mode = mode,
       super(key: key);

  /// Creates a calendar widget for single date selection.
  ///
  /// [initialSelectedDate] is the initially selected date.
  /// [onDateSelected] is the callback triggered when a date is selected.
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
  /// [initialStartDate] is the initial start date of the range.
  /// [initialEndDate] is the initial end date of the range.
  /// [onDateRangeSelected] is the callback triggered when a date range is selected.
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
  /// The currently focused month, year, or decade, determining the view.
  late DateTime _focusedDay;

  /// The single selected day in [SelectionMode.day].
  DateTime? _selectedDay;

  /// The start date of the selected range in [SelectionMode.range].
  DateTime? _rangeStart;

  /// The end date of the selected range in [SelectionMode.range].
  DateTime? _rangeEnd;

  /// The current active view mode of the calendar.
  late CalendarViewMode _currentViewMode;

  // Defines the min and max years for PageController calculations to avoid infinite scroll.
  final int _minYear = 1900;
  final int _maxYear = 2100;

  /// PageController for the day view (months).
  late PageController _dayPageController;

  /// PageController for the month view (years).
  late PageController _monthPageController;

  /// PageController for the year view (decades).
  late PageController _yearPageController;

  @override
  void initState() {
    super.initState();
    // Initialize focusedDay based on initial selection or current date
    _focusedDay =
        widget.initialSelectedDate ?? widget.initialStartDate ?? DateTime.now();
    _selectedDay = widget.initialSelectedDate;
    _rangeStart = widget.initialStartDate;
    _rangeEnd = widget.initialEndDate;
    _currentViewMode = CalendarViewMode.day;

    // Initialize all PageControllers
    _initializePageControllers();

    // If an initial range is provided and start date is after end date, swap them.
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
    // Update internal state if initial selection properties change from parent
    bool shouldUpdatePageControllers = false;

    if (widget.initialSelectedDate != oldWidget.initialSelectedDate) {
      _selectedDay = widget.initialSelectedDate;
      if (widget.initialSelectedDate != null) {
        _focusedDay = widget.initialSelectedDate!;
        shouldUpdatePageControllers = true;
      }
    }
    if (widget.initialStartDate != oldWidget.initialStartDate ||
        widget.initialEndDate != oldWidget.initialEndDate) {
      _rangeStart = widget.initialStartDate;
      _rangeEnd = widget.initialEndDate;
      if (widget.initialStartDate != null) {
        _focusedDay = widget.initialStartDate!;
        shouldUpdatePageControllers = true;
      }
    }

    if (shouldUpdatePageControllers) {
      // Only call setState if actual state changes happened
      setState(() {
        _updatePageControllers();
      });
    }
  }

  /// Initializes the PageControllers with their initial pages.
  void _initializePageControllers() {
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
  void _updatePageControllers({bool jumped = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void animateToPageIfNecessary(PageController controller, int targetPage) {
        if (controller.hasClients && controller.page?.round() != targetPage) {
          if (!jumped) {
            controller.animateToPage(
              targetPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          } else {
            controller.jumpToPage(targetPage);
          }
        }
      }

      if (_currentViewMode == CalendarViewMode.day) {
        final int targetPage =
            (_focusedDay.year - _minYear) * 12 + _focusedDay.month - 1;
        animateToPageIfNecessary(_dayPageController, targetPage);
      } else if (_currentViewMode == CalendarViewMode.month) {
        final int targetPage = _focusedDay.year - _minYear;
        animateToPageIfNecessary(_monthPageController, targetPage);
      } else if (_currentViewMode == CalendarViewMode.year) {
        final int targetPage = (_focusedDay.year - _minYear) ~/ 10;
        animateToPageIfNecessary(_yearPageController, targetPage);
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
            _updatePageControllers(
              jumped: true,
            ); // View mode changed, update page controller
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
            _updatePageControllers(
              jumped: true,
            ); // View mode changed, update page controller
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
            highlightColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
            splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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

  /// Builds the row displaying the days of the week (Sun, Mon, Tue, etc.).
  Widget _buildWeekDays() {
    if (_currentViewMode != CalendarViewMode.day) {
      return const SizedBox.shrink(); // Hide if not in day view
    }
    final List<String> displayWeekDays = [];

    for (int i = 0; i < 7; i++) {
      // Use an arbitrary date to get localized weekday names.
      // January 7, 2024, is a Sunday (as a reference point).
      DateTime date = DateTime(2024, 1, 7).add(Duration(days: i));
      displayWeekDays.add(DateFormat.E(Intl.getCurrentLocale()).format(date));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children:
          displayWeekDays.map((day) {
            return Expanded(
              child: Container(
                // Apply same margin as day cells for alignment
                margin: const EdgeInsets.all(2.0),
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

  /// Checks if two [DateTime] objects represent the same day, ignoring time.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Handles the selection of a date based on the current [SelectionMode].
  void _onDaySelected(DateTime day) {
    setState(() {
      // Animate the PageController to the selected month first, if it's a different month
      final int targetPage = (_focusedDay.year - _minYear) * 12 + day.month - 1;
      if (_dayPageController.hasClients &&
          _dayPageController.page?.round() != targetPage) {
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
          // Starting a new range or previous range selection is complete
          _rangeStart = day;
          _rangeEnd = null; // Reset end date
        } else {
          // Selecting the end date after start date is chosen
          if (day.isBefore(_rangeStart!)) {
            // If selected day is before start day, swap them
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
      // After selection, update _focusedDay to the month of the selected day
      // to keep the header in sync, ONLY if it's a different month.
      final newFocusedDay = DateTime(day.year, day.month, 1);
      if (!_isSameDay(_focusedDay, newFocusedDay)) {
        _focusedDay = newFocusedDay;
        // No need to call _updatePageControllers() here, as animateToPage is already called above
        // and _focusedDay change itself will trigger a rebuild, and didUpdateWidget will handle it.
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                );
                textColor = Theme.of(context).colorScheme.onPrimary;
              } else if (isInRange) {
                backgroundDecoration = BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                  _updatePageControllers(
                    jumped: true,
                  ); // View mode changed, update page controller
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                );
                textColor = Theme.of(context).colorScheme.onPrimary;
              } else if (isInRange) {
                backgroundDecoration = BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                  _updatePageControllers(
                    jumped: true,
                  ); // View mode changed, update page controller
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
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4);

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
                    ).colorScheme.primary.withOpacity(0.1),
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                );
                textColor = Theme.of(context).colorScheme.onPrimary;
              } else if (isInRange) {
                backgroundDecoration = BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
    return AspectRatio(
      aspectRatio: 1.0,
      child: Column(
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
      ),
    );
  }
}
