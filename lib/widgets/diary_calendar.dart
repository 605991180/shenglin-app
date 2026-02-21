import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DiaryCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Set<int> datesWithEntries;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const DiaryCalendar({
    super.key,
    required this.selectedDate,
    required this.datesWithEntries,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  State<DiaryCalendar> createState() => _DiaryCalendarState();
}

class _DiaryCalendarState extends State<DiaryCalendar> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth =
        DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  @override
  void didUpdateWidget(DiaryCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate.year != widget.selectedDate.year ||
        oldWidget.selectedDate.month != widget.selectedDate.month) {
      _displayMonth =
          DateTime(widget.selectedDate.year, widget.selectedDate.month);
    }
  }

  void _prevMonth() {
    setState(() {
      _displayMonth =
          DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
    widget.onMonthChanged(_displayMonth);
  }

  void _nextMonth() {
    setState(() {
      _displayMonth =
          DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
    widget.onMonthChanged(_displayMonth);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isExpanded) ...[
            _buildMonthHeader(),
            const SizedBox(height: 8),
            _buildWeekDayLabels(),
            const SizedBox(height: 4),
            _buildCalendarGrid(),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final title = DateFormat('yyyy年M月').format(_displayMonth);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _prevMonth,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child:
                  Icon(Icons.chevron_left, color: Color(0xFF666666), size: 24),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          GestureDetector(
            onTap: _nextMonth,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.chevron_right,
                  color: Color(0xFF666666), size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayLabels() {
    const labels = ['日', '一', '二', '三', '四', '五', '六'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: labels
            .map((l) => Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay =
        DateTime(_displayMonth.year, _displayMonth.month, 1);
    final lastDay =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sunday=0

    final totalDays = lastDay.day;
    final totalCells = startWeekday + totalDays;
    final rows = (totalCells / 7).ceil();

    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final index = row * 7 + col;
              final dayNum = index - startWeekday + 1;

              if (dayNum < 1 || dayNum > totalDays) {
                return const Expanded(child: SizedBox(height: 40));
              }

              final date = DateTime(
                  _displayMonth.year, _displayMonth.month, dayNum);
              final isSelected =
                  widget.selectedDate.year == date.year &&
                      widget.selectedDate.month == date.month &&
                      widget.selectedDate.day == date.day;
              final isToday = today.year == date.year &&
                  today.month == date.month &&
                  today.day == date.day;
              final hasEntry =
                  widget.datesWithEntries.contains(dayNum);

              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onDateSelected(date),
                  child: SizedBox(
                    height: 40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isToday && !isSelected
                                ? Border.all(
                                    color: const Color(0xFF4CAF50),
                                    width: 1)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF333333),
                              fontWeight: isToday || isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasEntry)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}
