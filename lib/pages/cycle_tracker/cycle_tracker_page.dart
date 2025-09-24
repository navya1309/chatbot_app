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
      appBar: AppBar(
        title: Text('Wellness Calendar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
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
