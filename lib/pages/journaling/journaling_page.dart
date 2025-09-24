import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journaling',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      home: JournalingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Data Models
class JournalEntry {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;
  final List<String> tags;
  final List<String> moods;
  final JournalEntryType type;
  final bool isPassive;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.tags,
    required this.moods,
    required this.type,
    this.isPassive = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'tags': tags,
      'moods': moods,
      'type': type.toString().split('.').last,
      'isPassive': isPassive,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      tags: List<String>.from(json['tags']),
      moods: List<String>.from(json['moods']),
      type: JournalEntryType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      isPassive: json['isPassive'] ?? false,
    );
  }
}

enum JournalEntryType {
  daily_prompt,
  free_write,
  voice_note,
  doodle,
  gratitude,
  auto_reflection,
  conversation_summary
}

class MoodData {
  final String mood;
  final String emoji;
  final DateTime timestamp;
  final double intensity; // 1-10 scale

  MoodData({
    required this.mood,
    required this.emoji,
    required this.timestamp,
    required this.intensity,
  });

  Map<String, dynamic> toJson() {
    return {
      'mood': mood,
      'emoji': emoji,
      'timestamp': timestamp.toIso8601String(),
      'intensity': intensity,
    };
  }

  factory MoodData.fromJson(Map<String, dynamic> json) {
    return MoodData(
      mood: json['mood'],
      emoji: json['emoji'],
      timestamp: DateTime.parse(json['timestamp']),
      intensity: json['intensity'].toDouble(),
    );
  }
}

class WeeklyInsight {
  final DateTime weekStart;
  final DateTime weekEnd;
  final Map<String, double> moodPercentages;
  final List<String> topTopics;
  final List<String> suggestions;
  final String affirmation;
  final int totalEntries;

  WeeklyInsight({
    required this.weekStart,
    required this.weekEnd,
    required this.moodPercentages,
    required this.topTopics,
    required this.suggestions,
    required this.affirmation,
    required this.totalEntries,
  });
}

class JournalingSettings {
  bool autoConversationSummary;
  bool moodAutoTagging;
  bool triggerBasedEntries;
  bool weeklyDigest;

  JournalingSettings({
    this.autoConversationSummary = true,
    this.moodAutoTagging = true,
    this.triggerBasedEntries = false,
    this.weeklyDigest = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'autoConversationSummary': autoConversationSummary,
      'moodAutoTagging': moodAutoTagging,
      'triggerBasedEntries': triggerBasedEntries,
      'weeklyDigest': weeklyDigest,
    };
  }

  factory JournalingSettings.fromJson(Map<String, dynamic> json) {
    return JournalingSettings(
      autoConversationSummary: json['autoConversationSummary'] ?? true,
      moodAutoTagging: json['moodAutoTagging'] ?? true,
      triggerBasedEntries: json['triggerBasedEntries'] ?? false,
      weeklyDigest: json['weeklyDigest'] ?? true,
    );
  }
}

// Backend Service
class JournalingService {
  static final JournalingService _instance = JournalingService._internal();
  factory JournalingService() => _instance;
  JournalingService._internal();

  // In-memory storage (replace with actual database/API calls)
  List<JournalEntry> _entries = [];
  List<MoodData> _moods = [];
  JournalingSettings _settings = JournalingSettings();
  String _currentMood = 'Happy';

  // Initialize with sample data
  void initializeSampleData() {
    if (_entries.isEmpty) {
      _entries = [
        JournalEntry(
          id: '1',
          title: 'Auto Generated',
          content:
              'Today you opened up about your fear of not being good enough academically. You showed vulnerability and honesty. Your stress seems linked to school deadlines.',
          timestamp: DateTime.now().subtract(Duration(hours: 2)),
          tags: ['academic', 'stress'],
          moods: ['😰', '🎓'],
          type: JournalEntryType.auto_reflection,
          isPassive: true,
        ),
        JournalEntry(
          id: '2',
          title: 'Morning Gratitude',
          content:
              'I\'m grateful for the peaceful morning I had today. The coffee tasted perfect and I had time to read a few chapters of my book before starting work.',
          timestamp: DateTime.now().subtract(Duration(days: 1)),
          tags: ['grateful', 'peaceful'],
          moods: ['😊', '☕'],
          type: JournalEntryType.gratitude,
          isPassive: false,
        ),
        JournalEntry(
          id: '3',
          title: 'Daily Reflection',
          content:
              'Feeling grateful for the small victories today. Had a good conversation with mom and finished my assignment early.',
          timestamp: DateTime.now().subtract(Duration(days: 1)),
          tags: ['family', 'achievement'],
          moods: ['😊', '❤️'],
          type: JournalEntryType.daily_prompt,
          isPassive: false,
        ),
      ];

      _moods = [
        MoodData(
            mood: 'Happy',
            emoji: '😊',
            timestamp: DateTime.now(),
            intensity: 7.5),
        MoodData(
            mood: 'Anxious',
            emoji: '😰',
            timestamp: DateTime.now().subtract(Duration(hours: 3)),
            intensity: 6.0),
        MoodData(
            mood: 'Grateful',
            emoji: '🙏',
            timestamp: DateTime.now().subtract(Duration(days: 1)),
            intensity: 8.0),
      ];
    }
  }

  // CRUD Operations for Journal Entries
  Future<List<JournalEntry>> getAllEntries() async {
    await Future.delayed(Duration(milliseconds: 300)); // Simulate API delay
    return List.from(_entries);
  }

  Future<List<JournalEntry>> getEntriesByType(JournalEntryType type) async {
    await Future.delayed(Duration(milliseconds: 200));
    return _entries.where((entry) => entry.type == type).toList();
  }

  Future<List<JournalEntry>> getPassiveEntries() async {
    await Future.delayed(Duration(milliseconds: 200));
    return _entries.where((entry) => entry.isPassive).toList();
  }

  Future<List<JournalEntry>> getActiveEntries() async {
    await Future.delayed(Duration(milliseconds: 200));
    return _entries.where((entry) => !entry.isPassive).toList();
  }

  Future<JournalEntry> createEntry(JournalEntry entry) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate API call
    _entries.insert(0, entry);
    return entry;
  }

  Future<JournalEntry> updateEntry(JournalEntry entry) async {
    await Future.delayed(Duration(milliseconds: 400));
    int index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
    }
    return entry;
  }

  Future<void> deleteEntry(String id) async {
    await Future.delayed(Duration(milliseconds: 300));
    _entries.removeWhere((entry) => entry.id == id);
  }

  // Mood Management
  Future<void> updateCurrentMood(String mood, double intensity) async {
    await Future.delayed(Duration(milliseconds: 200));
    _currentMood = mood;
    _moods.insert(
        0,
        MoodData(
          mood: mood,
          emoji: _getMoodEmoji(mood),
          timestamp: DateTime.now(),
          intensity: intensity,
        ));
  }

  Future<List<MoodData>> getMoodHistory(int days) async {
    await Future.delayed(Duration(milliseconds: 200));
    DateTime cutoff = DateTime.now().subtract(Duration(days: days));
    return _moods.where((mood) => mood.timestamp.isAfter(cutoff)).toList();
  }

  String getCurrentMood() => _currentMood;

  // Settings Management
  Future<JournalingSettings> getSettings() async {
    await Future.delayed(Duration(milliseconds: 100));
    return _settings;
  }

  Future<void> updateSettings(JournalingSettings settings) async {
    await Future.delayed(Duration(milliseconds: 200));
    _settings = settings;
  }

  // AI-Generated Content (Mock)
  Future<String> generateConversationSummary(String chatContent) async {
    await Future.delayed(Duration(seconds: 2)); // Simulate AI processing

    List<String> summaryTemplates = [
      "Today you expressed feelings about {topic}. Your emotional state seemed {mood}. Consider reflecting on {suggestion}.",
      "You opened up about {topic} today. This shows {quality}. Your {emotion} is understandable given the circumstances.",
      "During our conversation, you focused on {topic}. Your {mood} feelings are valid. Perhaps try {suggestion}.",
    ];

    String template =
        summaryTemplates[Random().nextInt(summaryTemplates.length)];
    return template
        .replaceAll('{topic}', 'your current challenges')
        .replaceAll('{mood}', 'thoughtful')
        .replaceAll('{quality}', 'self-awareness')
        .replaceAll('{emotion}', 'concern')
        .replaceAll('{suggestion}', 'breaking tasks into smaller steps');
  }

  Future<List<String>> generateMoodTags(String content) async {
    await Future.delayed(Duration(milliseconds: 800));

    // Mock sentiment analysis
    List<String> possibleMoods = [
      'Happy',
      'Sad',
      'Anxious',
      'Excited',
      'Grateful',
      'Overwhelmed',
      'Peaceful',
      'Frustrated'
    ];
    return possibleMoods.take(Random().nextInt(3) + 1).toList();
  }

  Future<WeeklyInsight> generateWeeklyInsight() async {
    await Future.delayed(Duration(seconds: 1));

    DateTime now = DateTime.now();
    DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));

    return WeeklyInsight(
      weekStart: weekStart,
      weekEnd: weekStart.add(Duration(days: 6)),
      moodPercentages: {
        'Happy': 45.0,
        'Anxious': 25.0,
        'Grateful': 20.0,
        'Overwhelmed': 10.0,
      },
      topTopics: [
        'Academic stress',
        'Family relationships',
        'Future career',
        'Social interactions'
      ],
      suggestions: [
        'Consider meditation before stressful events',
        'Try time-blocking your study sessions',
        'Schedule regular family check-ins',
      ],
      affirmation:
          'You are capable of handling whatever challenges come your way. Your academic struggles don\'t define your worth.',
      totalEntries: _entries.length,
    );
  }

  Future<String> getDailyPrompt() async {
    await Future.delayed(Duration(milliseconds: 300));

    List<String> prompts = [
      'What made you smile today?',
      'What\'s something you wish more people knew about you?',
      'Describe a moment when you felt proud of yourself.',
      'What are you grateful for right now?',
      'What\'s been on your mind lately?',
      'How did you grow today?',
      'What would you tell your younger self?',
      'What\'s something beautiful you noticed today?',
    ];

    return prompts[Random().nextInt(prompts.length)];
  }

  String _getMoodEmoji(String mood) {
    Map<String, String> moodEmojis = {
      'Happy': '😊',
      'Sad': '😢',
      'Anxious': '😰',
      'Excited': '🤩',
      'Grateful': '🙏',
      'Overwhelmed': '😵',
      'Peaceful': '😌',
      'Frustrated': '😤',
      'Tired': '😴',
      'Thoughtful': '🤔',
    };
    return moodEmojis[mood] ?? '😐';
  }
}

// Main Journaling Page
class JournalingPage extends StatefulWidget {
  @override
  _JournalingPageState createState() => _JournalingPageState();
}

class _JournalingPageState extends State<JournalingPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final JournalingService _service = JournalingService();

  List<JournalEntry> _allEntries = [];
  List<JournalEntry> _passiveEntries = [];
  List<JournalEntry> _activeEntries = [];
  JournalingSettings _settings = JournalingSettings();
  WeeklyInsight? _weeklyInsight;
  String _dailyPrompt = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service.initializeSampleData();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final entries = await _service.getAllEntries();
      final passiveEntries = await _service.getPassiveEntries();
      final activeEntries = await _service.getActiveEntries();
      final settings = await _service.getSettings();
      final weeklyInsight = await _service.generateWeeklyInsight();
      final dailyPrompt = await _service.getDailyPrompt();

      setState(() {
        _allEntries = entries;
        _passiveEntries = passiveEntries;
        _activeEntries = activeEntries;
        _settings = settings;
        _weeklyInsight = weeklyInsight;
        _dailyPrompt = dailyPrompt;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load data: ${e.toString()}');
    }
  }

  Future<void> _updateMood(String mood) async {
    try {
      await _service.updateCurrentMood(mood, 7.0); // Default intensity
      _showSuccessSnackBar('Mood updated to $mood');
    } catch (e) {
      _showErrorSnackBar('Failed to update mood: ${e.toString()}');
    }
  }

  Future<void> _toggleSetting(String setting, bool value) async {
    JournalingSettings newSettings = JournalingSettings(
      autoConversationSummary: setting == 'autoConversationSummary'
          ? value
          : _settings.autoConversationSummary,
      moodAutoTagging:
          setting == 'moodAutoTagging' ? value : _settings.moodAutoTagging,
      triggerBasedEntries: setting == 'triggerBasedEntries'
          ? value
          : _settings.triggerBasedEntries,
      weeklyDigest: setting == 'weeklyDigest' ? value : _settings.weeklyDigest,
    );

    try {
      await _service.updateSettings(newSettings);
      setState(() => _settings = newSettings);
      _showSuccessSnackBar('Settings updated');
    } catch (e) {
      _showErrorSnackBar('Failed to update settings: ${e.toString()}');
    }
  }

  Future<void> _createEntry(JournalEntryType type) async {
    String title = _getTitleForType(type);
    String content = '';

    if (type == JournalEntryType.daily_prompt) {
      content = _dailyPrompt;
    }

    _showCreateEntryDialog(type, title, content);
  }

  Future<void> _saveEntry(JournalEntry entry) async {
    try {
      await _service.createEntry(entry);
      await _loadData(); // Refresh data
      _showSuccessSnackBar('Entry saved successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to save entry: ${e.toString()}');
    }
  }

  Future<void> _deleteEntry(String id) async {
    try {
      await _service.deleteEntry(id);
      await _loadData(); // Refresh data
      _showSuccessSnackBar('Entry deleted');
    } catch (e) {
      _showErrorSnackBar('Failed to delete entry: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _getTitleForType(JournalEntryType type) {
    switch (type) {
      case JournalEntryType.daily_prompt:
        return 'Daily Reflection';
      case JournalEntryType.free_write:
        return 'Free Writing';
      case JournalEntryType.voice_note:
        return 'Voice Note';
      case JournalEntryType.doodle:
        return 'Doodle Entry';
      case JournalEntryType.gratitude:
        return 'Gratitude Journal';
      default:
        return 'Journal Entry';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Journal',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[600]),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.grey[600]),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue[600],
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: Colors.blue[600],
          tabs: [
            Tab(text: 'Timeline'),
            Tab(text: 'Auto Reflections'),
            Tab(text: 'Active Journal'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimelineTab(),
          _buildAutoReflectionsTab(),
          _buildActiveJournalTab(),
          _buildInsightsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEntryDialog(
            JournalEntryType.free_write, 'New Entry', ''),
        backgroundColor: Colors.blue[600],
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTimelineTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood Overview Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Mood Today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMoodIcon(
                          '😊', 'Happy', _service.getCurrentMood() == 'Happy'),
                      SizedBox(width: 16),
                      _buildMoodIcon('😰', 'Anxious',
                          _service.getCurrentMood() == 'Anxious'),
                      SizedBox(width: 16),
                      _buildMoodIcon(
                          '😴', 'Tired', _service.getCurrentMood() == 'Tired'),
                      SizedBox(width: 16),
                      _buildMoodIcon('🤔', 'Thoughtful',
                          _service.getCurrentMood() == 'Thoughtful'),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Timeline Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Entries',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('View All'),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Timeline Entries
            ..._allEntries
                .take(10)
                .map((entry) => _buildTimelineEntry(entry))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoReflectionsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-Reflection Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSettingToggle(
                      'Generate conversation summaries',
                      _settings.autoConversationSummary,
                      'autoConversationSummary'),
                  _buildSettingToggle('Mood auto-tagging',
                      _settings.moodAutoTagging, 'moodAutoTagging'),
                  _buildSettingToggle('Trigger-based entries',
                      _settings.triggerBasedEntries, 'triggerBasedEntries'),
                  _buildSettingToggle(
                      'Weekly digest', _settings.weeklyDigest, 'weeklyDigest'),
                ],
              ),
            ),

            SizedBox(height: 24),

            Text(
              'Reflections from Chat',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 16),

            // Auto-generated entries
            ..._passiveEntries
                .map((entry) => _buildAutoReflectionCard(entry))
                .toList(),

            if (_passiveEntries.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No auto-reflections yet.\nStart chatting to generate insights!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJournalTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Daily Prompt',
                    _dailyPrompt.isNotEmpty
                        ? _dailyPrompt
                        : 'Loading prompt...',
                    Icons.lightbulb_outline,
                    Colors.yellow[600]!,
                    JournalEntryType.daily_prompt,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'Free Write',
                    'Express your thoughts freely',
                    Icons.edit_outlined,
                    Colors.blue[600]!,
                    JournalEntryType.free_write,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Voice Note',
                    'Speak your mind',
                    Icons.mic_outlined,
                    Colors.green[600]!,
                    JournalEntryType.voice_note,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'Doodle',
                    'Draw your feelings',
                    Icons.brush_outlined,
                    Colors.purple[600]!,
                    JournalEntryType.doodle,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Recent Active Entries
            Text(
              'Your Entries',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 16),

            ..._activeEntries
                .map((entry) => _buildActiveEntryCard(entry))
                .toList(),

            if (_activeEntries.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No journal entries yet.\nTap the + button to create your first entry!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    if (_weeklyInsight == null) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly Digest Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.purple[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Digest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${_formatDate(_weeklyInsight!.weekStart)} - ${_formatDate(_weeklyInsight!.weekEnd)}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeeklyStat(
                          '${_weeklyInsight!.totalEntries}', 'Journal Entries'),
                      _buildWeeklyStat(
                          '${_weeklyInsight!.moodPercentages['Happy']?.round() ?? 0}%',
                          'Happy'),
                      _buildWeeklyStat(
                          '${_weeklyInsight!.moodPercentages['Anxious']?.round() ?? 0}%',
                          'Anxious'),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Mood Patterns
            _buildInsightCard(
              'Mood Patterns',
              'You tend to feel more anxious on weekdays, especially Mondays and Wednesdays. Your mood improves significantly on weekends.',
              Icons.trending_up,
              Colors.blue[600]!,
            ),

            // Top Topics
            _buildInsightCard(
              'Most Discussed Topics',
              _weeklyInsight!.topTopics
                  .asMap()
                  .entries
                  .map((entry) => '${entry.key + 1}. ${entry.value}')
                  .join('\n'),
              Icons.topic_outlined,
              Colors.green[600]!,
            ),

            // Suggestions
            _buildInsightCard(
              'Personalized Suggestions',
              _weeklyInsight!.suggestions.join('\n• '),
              Icons.lightbulb_outlined,
              Colors.orange[600]!,
            ),

            // Affirmations
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.pink[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.pink[600]),
                      SizedBox(width: 8),
                      Text(
                        'Daily Affirmation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.pink[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '"${_weeklyInsight!.affirmation}"',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.pink[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodIcon(String emoji, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _updateMood(label),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: 20)),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEntry(JournalEntry entry) {
    Color bgColor = entry.isPassive ? Colors.orange[100]! : Colors.green[100]!;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (entry.isPassive) ...[
                    SizedBox(width: 8),
                    Icon(Icons.auto_awesome, size: 16, color: Colors.blue[600]),
                  ],
                ],
              ),
              Text(
                _formatTimestamp(entry.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            entry.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: entry.moods
                    .map(
                      (mood) => Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(mood, style: TextStyle(fontSize: 16)),
                      ),
                    )
                    .toList(),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 16),
                    onPressed: () => _editEntry(entry),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 16),
                    onPressed: () => _confirmDeleteEntry(entry.id),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggle(String title, bool value, String settingKey) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14),
          ),
          Switch(
            value: value,
            onChanged: (newValue) => _toggleSetting(settingKey, newValue),
            activeColor: Colors.blue[600],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoReflectionCard(JournalEntry entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatTimestamp(entry.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            entry.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: entry.tags
                .map(
                  (tag) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 12),
          TextButton(
            onPressed: () => _bridgeToActiveJournal(entry),
            child: Text('Want to reflect more on this?'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon,
      Color color, JournalEntryType type) {
    return GestureDetector(
      onTap: () => _createEntry(type),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveEntryCard(JournalEntry entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIconForType(entry.type),
                  size: 16, color: Colors.blue[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatTimestamp(entry.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            entry.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                children: entry.tags
                    .map(
                      (tag) => Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 16),
                    onPressed: () => _editEntry(entry),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 16),
                    onPressed: () => _confirmDeleteEntry(entry.id),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
      String title, String content, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Dialog Methods
  void _showCreateEntryDialog(
      JournalEntryType type, String initialTitle, String initialContent) {
    final titleController = TextEditingController(text: initialTitle);
    final contentController = TextEditingController(text: initialContent);
    List<String> selectedTags = [];
    List<String> selectedMoods = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create Journal Entry'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                  ),
                  SizedBox(height: 16),
                  _buildTagSelector(selectedTags, setDialogState),
                  SizedBox(height: 16),
                  _buildMoodSelector(selectedMoods, setDialogState),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  JournalEntry newEntry = JournalEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    content: contentController.text,
                    timestamp: DateTime.now(),
                    tags: selectedTags,
                    moods: selectedMoods,
                    type: type,
                    isPassive: false,
                  );
                  Navigator.of(context).pop();
                  _saveEntry(newEntry);
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Journaling Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingToggle('Auto conversation summaries',
                _settings.autoConversationSummary, 'autoConversationSummary'),
            _buildSettingToggle('Mood auto-tagging', _settings.moodAutoTagging,
                'moodAutoTagging'),
            _buildSettingToggle('Trigger-based entries',
                _settings.triggerBasedEntries, 'triggerBasedEntries'),
            _buildSettingToggle(
                'Weekly digest', _settings.weeklyDigest, 'weeklyDigest'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSelector(List<String> selectedTags, Function setDialogState) {
    List<String> availableTags = [
      'academic',
      'stress',
      'family',
      'grateful',
      'peaceful',
      'work',
      'health',
      'social'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags:', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: availableTags
              .map((tag) => FilterChip(
                    label: Text(tag),
                    selected: selectedTags.contains(tag),
                    onSelected: (selected) {
                      setDialogState(() {
                        if (selected) {
                          selectedTags.add(tag);
                        } else {
                          selectedTags.remove(tag);
                        }
                      });
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMoodSelector(
      List<String> selectedMoods, Function setDialogState) {
    List<Map<String, String>> availableMoods = [
      {'emoji': '😊', 'name': 'Happy'},
      {'emoji': '😢', 'name': 'Sad'},
      {'emoji': '😰', 'name': 'Anxious'},
      {'emoji': '🤩', 'name': 'Excited'},
      {'emoji': '🙏', 'name': 'Grateful'},
      {'emoji': '😵', 'name': 'Overwhelmed'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Moods:', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: availableMoods
              .map((mood) => FilterChip(
                    label: Text('${mood['emoji']} ${mood['name']}'),
                    selected: selectedMoods.contains(mood['emoji']),
                    onSelected: (selected) {
                      setDialogState(() {
                        if (selected) {
                          selectedMoods.add(mood['emoji']!);
                        } else {
                          selectedMoods.remove(mood['emoji']);
                        }
                      });
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  // Helper Methods
  void _editEntry(JournalEntry entry) {
    _showCreateEntryDialog(entry.type, entry.title, entry.content);
  }

  void _confirmDeleteEntry(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Entry'),
        content: Text(
            'Are you sure you want to delete this entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEntry(id);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _bridgeToActiveJournal(JournalEntry passiveEntry) {
    _tabController.animateTo(2); // Switch to Active Journal tab
    Future.delayed(Duration(milliseconds: 300), () {
      _showCreateEntryDialog(
        JournalEntryType.free_write,
        'Reflecting on: ${passiveEntry.title}',
        'Based on the reflection: "${passiveEntry.content}"\n\nYour thoughts:\n',
      );
    });
  }

  IconData _getIconForType(JournalEntryType type) {
    switch (type) {
      case JournalEntryType.daily_prompt:
        return Icons.lightbulb_outline;
      case JournalEntryType.free_write:
        return Icons.edit_outlined;
      case JournalEntryType.voice_note:
        return Icons.mic_outlined;
      case JournalEntryType.doodle:
        return Icons.brush_outlined;
      case JournalEntryType.gratitude:
        return Icons.favorite_outline;
      default:
        return Icons.book_outlined;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    DateTime now = DateTime.now();
    Duration difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} mins ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatDate(DateTime date) {
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
