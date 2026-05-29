import 'package:flutter/material.dart';
import 'cycle_data_model.dart';
import 'cycle_service.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final CycleService _cycleService = CycleService();
  DateTime _currentMonth = DateTime.now();
  Map<String, List<DateTime>> _calendarDays = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final days = await _cycleService.getCalendarDays(_currentMonth);
      if (!mounted) return;
      setState(() {
        _calendarDays = days;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
    _loadCalendarData();
  }

  bool isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  Widget _buildDayCell(DateTime day) {
    bool isPeriod =
        _calendarDays['period']?.any((d) => isSameDay(d, day)) ?? false;
    bool isPredicted =
        _calendarDays['predicted']?.any((d) => isSameDay(d, day)) ?? false;
    bool isOvulation =
        _calendarDays['ovulation']?.any((d) => isSameDay(d, day)) ?? false;
    bool isPMS = _calendarDays['pms']?.any((d) => isSameDay(d, day)) ?? false;
    bool isToday = isSameDay(day, DateTime.now());

    Color? bgColor;
    Color? borderColor;
    Color textColor = Colors.black87;
    Widget? icon;

    if (isPeriod) {
      bgColor = const Color(0xFFEF4444).withOpacity(0.15);
      borderColor = const Color(0xFFEF4444);
      textColor = const Color(0xFFEF4444);
      icon = const Icon(Icons.circle, size: 6, color: Color(0xFFEF4444));
    } else if (isPredicted) {
      bgColor = const Color(0xFFEF4444).withOpacity(0.08);
      borderColor = const Color(0xFFEF4444).withOpacity(0.5);
      textColor = const Color(0xFFEF4444).withOpacity(0.7);
    } else if (isOvulation) {
      bgColor = const Color(0xFF10B981).withOpacity(0.15);
      borderColor = const Color(0xFF10B981);
      textColor = const Color(0xFF10B981);
      icon = const Icon(Icons.spa, size: 8, color: Color(0xFF10B981));
    } else if (isPMS) {
      bgColor = const Color(0xFFF59E0B).withOpacity(0.15);
      borderColor = const Color(0xFFF59E0B);
      textColor = const Color(0xFFF59E0B);
    }

    return GestureDetector(
      onTap: isPeriod ? () => _showDayDetails(day) : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor ??
              (isToday ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor ??
                (isToday ? const Color(0xFF6366F1) : Colors.grey[200]!),
            width: isToday ? 2 : 1,
          ),
          boxShadow: (isPeriod || isOvulation || isPMS || isToday)
              ? [
                  BoxShadow(
                    color:
                        (borderColor ?? const Color(0xFF6366F1)).withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isToday && borderColor == null
                    ? const Color(0xFF6366F1)
                    : textColor,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(height: 2),
              icon,
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDayDetails(DateTime day) async {
    final logs = await _cycleService.getLogsForDay(day);
    if (!mounted) return;
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged entry for this day.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Entries on ${day.day}/${day.month}/${day.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...logs.map((log) => _LogTile(
                    log: log,
                    onDelete: () async {
                      Navigator.pop(sheetCtx);
                      await _confirmAndDelete(log);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDelete(PeriodLog log) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete entry?'),
        content: const Text(
            'This will remove the period log entry. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _cycleService.deletePeriodLog(log.id);
      await _loadCalendarData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        '${months[_currentMonth.month - 1]} ${_currentMonth.year}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('S',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                      Text('M',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                      Text('T',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                      Text('W',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                      Text('T',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                      Text('F',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                      Text('S',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: daysInMonth,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final day = DateTime(
                      _currentMonth.year, _currentMonth.month, index + 1);
                  return _buildDayCell(day);
                },
              ),
            ),
            const SizedBox(height: 20),
            // Legend
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Legend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _legendColorBox(
                      const Color(0xFFEF4444), 'Confirmed Period Days'),
                  const SizedBox(height: 12),
                  _legendColorBox(const Color(0xFFEF4444).withOpacity(0.5),
                      'Predicted Period'),
                  const SizedBox(height: 12),
                  _legendColorBox(const Color(0xFF10B981), 'Ovulation Window'),
                  const SizedBox(height: 12),
                  _legendColorBox(const Color(0xFFF59E0B), 'PMS Week'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendColorBox(Color color, String label) => Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      );
}

class _LogTile extends StatelessWidget {
  final PeriodLog log;
  final VoidCallback onDelete;

  const _LogTile({required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final start = log.startDate;
    final end = log.endDate;
    final range = end == null
        ? '${start.day}/${start.month}/${start.year}'
        : '${start.day}/${start.month} → ${end.day}/${end.month}';
    final symptoms = log.symptoms.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Period: $range',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
                if (log.flow != null) ...[
                  const SizedBox(height: 4),
                  Text('Flow: ${log.flow}/5'),
                ],
                if (symptoms.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Symptoms: ${symptoms.join(", ")}'),
                ],
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.notes!,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete entry',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}
