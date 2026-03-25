import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  final List<_TabItem> _tabs = const [
    _TabItem(icon: Icons.calendar_month_rounded, label: 'Calendar'),
    _TabItem(icon: Icons.edit_note_rounded, label: 'Log'),
    _TabItem(icon: Icons.school_rounded, label: 'Education'),
    _TabItem(icon: Icons.spa_rounded, label: 'Self-Care'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF472B6), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wellness Calendar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track, learn, and take care of yourself',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pill tab bar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: List.generate(_tabs.length, (index) {
                        final isSelected =
                            _tabController.index == index;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _tabController.animateTo(index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _tabs[index].icon,
                                    size: 18,
                                    color: isSelected
                                        ? const Color(0xFF8B5CF6)
                                        : Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _tabs[index].label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? const Color(0xFF8B5CF6)
                                          : Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            const CalendarView(),
            const CycleLogForm(),
            EducationalContentPage(),
            SelfCareToolkitPage(),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;

  const _TabItem({required this.icon, required this.label});
}
