import 'package:chatbot_app_1/pages/myth_fun_cards/myth_fun_cards_page.dart';
import 'package:flutter/material.dart';

// Import your pages here
import '../cycle_tracker/cycle_tracker_page.dart';
import '../home/home_page.dart';
import '../journaling/journaling_page.dart';
import '../myth_fun_cards/myth_fun_cards_page.dart';

class BottomNavigation extends StatefulWidget {
  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ChatbotHomeScreen(),
    JournalingPage(),
    CycleTrackerPage(),
    MythFunCardsPage(),
  ];

  final List<String> _titles = [
    'Chatbot Home',
    'Journaling',
    'Cycle Tracker',
    'Myths & Fun Facts',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue[600],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Journaling',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Cycle Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Myth Busting & Fun Facts',
          ),
        ],
      ),
    );
  }
}
