import 'package:flutter/material.dart';
import 'calendar_view.dart';
import 'cycle_log_form.dart';
import 'educational_content_page.dart';
import 'self_care_toolkit_page.dart';

class CycleTrackerPage extends StatefulWidget {
  @override
  _CycleTrackerPageState createState() => _CycleTrackerPageState();
}

class _CycleTrackerPageState extends State<CycleTrackerPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Wellness Calendar',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Calendar'),
            Tab(text: 'Log'),
            Tab(text: 'Education'),
            Tab(text: 'Self-Care'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CalendarView(), // Calendar with highlights
          CycleLogForm(), // Logging form
          EducationalContentPage(), // Articles & videos
          SelfCareToolkitPage(), // Self-care suggestions
        ],
      ),
    );
  }
}
