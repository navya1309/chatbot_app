import 'package:flutter/material.dart';

// This is a simple calendar widget with minimal customizations.
// You can use packages like table_calendar or syncfusion_flutter_calendar for full-featured calendar.

class CalendarView extends StatelessWidget {
  // Example data, in real app, this would come from backend or local DB.
  final List<DateTime> predictedPeriodDays = [
    DateTime.now().subtract(Duration(days: 1)),
    DateTime.now(),
    DateTime.now().add(Duration(days: 1)),
    DateTime.now().add(Duration(days: 2)),
    DateTime.now().add(Duration(days: 3)),
  ];

  final List<DateTime> ovulationWindow = [
    DateTime.now().add(Duration(days: 10)),
    DateTime.now().add(Duration(days: 11)),
    DateTime.now().add(Duration(days: 12)),
  ];

  final List<DateTime> pmsWeek = [
    DateTime.now().add(Duration(days: -4)),
    DateTime.now().add(Duration(days: -3)),
    DateTime.now().add(Duration(days: -2)),
    DateTime.now().add(Duration(days: -1)),
  ];

  bool isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  Widget _buildDayCell(DateTime day) {
    bool isPeriod = predictedPeriodDays.any((d) => isSameDay(d, day));
    bool isOvulation = ovulationWindow.any((d) => isSameDay(d, day));
    bool isPMS = pmsWeek.any((d) => isSameDay(d, day));

    Color bgColor = Colors.transparent;
    if (isPeriod)
      bgColor = Colors.red.withOpacity(0.3);
    else if (isOvulation)
      bgColor = Colors.green.withOpacity(0.3);
    else if (isPMS) bgColor = Colors.orange.withOpacity(0.3);

    return Container(
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text('${day.day}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              '${now.month}/${now.year}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: daysInMonth,
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemBuilder: (context, index) {
                final day = DateTime(now.year, now.month, index + 1);
                return _buildDayCell(day);
              },
            ),
            SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _legendColorBox(Colors.red.withOpacity(0.3), 'Period Days'),
                _legendColorBox(Colors.green.withOpacity(0.3), 'Ovulation'),
                _legendColorBox(Colors.orange.withOpacity(0.3), 'PMS Week'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendColorBox(Color color, String label) => Row(
        children: [
          Container(width: 20, height: 20, color: color),
          SizedBox(width: 8),
          Text(label),
        ],
      );
}
