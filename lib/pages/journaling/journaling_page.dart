import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // CRUD Operations for Journal Entries
  Future<List<JournalEntry>> getAllEntries() async {
    try {
      if (_userId.isEmpty) {
        print('DEBUG: getAllEntries - User ID is empty');
        return [];
      }

      print('DEBUG: Fetching all journal entries for user: $_userId');
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('journal_entries')
          .orderBy('timestamp', descending: true)
          .get();

      print('DEBUG: Retrieved ${snapshot.docs.length} journal entries');
      return snapshot.docs
          .map((doc) => JournalEntry.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stackTrace) {
      print('ERROR: getAllEntries failed - $e');
      print('STACK TRACE: $stackTrace');
      return [];
    }
  }

  Future<List<JournalEntry>> getEntriesByType(JournalEntryType type) async {
    try {
      if (_userId.isEmpty) {
        print('DEBUG: getEntriesByType - User ID is empty');
        return [];
      }

      print(
          'DEBUG: Fetching entries of type: ${type.toString().split('.').last}');
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('journal_entries')
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('timestamp', descending: true)
          .get();

      print(
          'DEBUG: Retrieved ${snapshot.docs.length} entries of type ${type.toString().split('.').last}');
      return snapshot.docs
          .map((doc) => JournalEntry.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stackTrace) {
      print('ERROR: getEntriesByType failed - $e');
      print('STACK TRACE: $stackTrace');
      return [];
    }
  }

  Future<List<JournalEntry>> getPassiveEntries() async {
    try {
      if (_userId.isEmpty) {
        print('DEBUG: getPassiveEntries - User ID is empty');
        return [];
      }

      print('DEBUG: Fetching passive journal entries');
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('journal_entries')
          .where('isPassive', isEqualTo: true)
          // .orderBy('timestamp', descending: true)
          .get();

      print('DEBUG: Retrieved ${snapshot.docs.length} passive entries');
      return snapshot.docs
          .map((doc) => JournalEntry.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stackTrace) {
      print('ERROR: getPassiveEntries failed - $e');
      print('STACK TRACE: $stackTrace');
      return [];
    }
  }

  Future<List<JournalEntry>> getActiveEntries() async {
    try {
      if (_userId.isEmpty) {
        print('DEBUG: getActiveEntries - User ID is empty');
        return [];
      }

      print('DEBUG: Fetching active journal entries');
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('journal_entries')
          .where('isPassive', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();

      print('DEBUG: Retrieved ${snapshot.docs.length} active entries');
      return snapshot.docs
          .map((doc) => JournalEntry.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e, stackTrace) {
      print('ERROR: getActiveEntries failed - $e');
      print('STACK TRACE: $stackTrace');
      return [];
    }
  }

  Future<JournalEntry> createEntry(JournalEntry entry) async {
    try {
      if (_userId.isEmpty) {
        print('ERROR: createEntry - User not logged in');
        throw Exception('User not logged in');
      }

      print('DEBUG: Creating journal entry: ${entry.title}');
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('journal_entries')
          .add(entry.toJson());

      print('DEBUG: Journal entry created successfully with ID: ${docRef.id}');
      return JournalEntry(
        id: docRef.id,
        title: entry.title,
        content: entry.content,
        timestamp: entry.timestamp,
        tags: entry.tags,
        moods: entry.moods,
        type: entry.type,
        isPassive: entry.isPassive,
      );
    } catch (e, stackTrace) {
      print('ERROR: createEntry failed - $e');
      print('STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  Future<JournalEntry> updateEntry(JournalEntry entry) async {
    try {
      if (_userId.isEmpty) {
        print('ERROR: updateEntry - User not logged in');
        throw Exception('User not logged in');
      }

      print('DEBUG: Updating journal entry: ${entry.id}');
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('journal_entries')
          .doc(entry.id)
          .update(entry.toJson());

      print('DEBUG: Journal entry updated successfully');
      return entry;
    } catch (e, stackTrace) {
      print('ERROR: updateEntry failed - $e');
      print('STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      if (_userId.isEmpty) {
        print('ERROR: deleteEntry - User not logged in');
        throw Exception('User not logged in');
      }

      print('DEBUG: Deleting journal entry: $id');
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('journal_entries')
          .doc(id)
          .delete();

      print('DEBUG: Journal entry deleted successfully');
    } catch (e, stackTrace) {
      print('ERROR: deleteEntry failed - $e');
      print('STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  // Mood Management
  Future<void> updateCurrentMood(String mood, double intensity) async {
    try {
      if (_userId.isEmpty) {
        print('ERROR: updateCurrentMood - User not logged in');
        throw Exception('User not logged in');
      }

      print('DEBUG: Updating mood to: $mood with intensity: $intensity');
      final moodData = MoodData(
        mood: mood,
        emoji: _getMoodEmoji(mood),
        timestamp: DateTime.now(),
        intensity: intensity,
      );

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('moods')
          .add(moodData.toJson());

      // Also update current mood in user document
      await _firestore
          .collection('users')
          .doc(_userId)
          .set({'currentMood': mood}, SetOptions(merge: true));

      print('DEBUG: Mood updated successfully');
    } catch (e, stackTrace) {
      print('ERROR: updateCurrentMood failed - $e');
      print('STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  Future<List<MoodData>> getMoodHistory(int days) async {
    try {
      if (_userId.isEmpty) {
        print('DEBUG: getMoodHistory - User ID is empty');
        return [];
      }

      print('DEBUG: Fetching mood history for last $days days');
      DateTime cutoff = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('moods')
          .where('timestamp', isGreaterThan: cutoff.toIso8601String())
          // .orderBy('timestamp', descending: true)
          .get();

      print('DEBUG: Retrieved ${snapshot.docs.length} mood entries');
      return snapshot.docs.map((doc) => MoodData.fromJson(doc.data())).toList();
    } catch (e, stackTrace) {
      print('ERROR: getMoodHistory failed - $e');
      print('STACK TRACE: $stackTrace');
      return [];
    }
  }

  Future<String> getCurrentMood() async {
    try {
      if (_userId.isEmpty) {
        print('DEBUG: getCurrentMood - User ID is empty');
        return 'Happy';
      }

      print('DEBUG: Fetching current mood for user: $_userId');
      final doc = await _firestore.collection('users').doc(_userId).get();
      final mood = doc.data()?['currentMood'] ?? 'Happy';
      print('DEBUG: Current mood: $mood');
      return mood;
    } catch (e, stackTrace) {
      print('ERROR: getCurrentMood failed - $e');
      print('STACK TRACE: $stackTrace');
      return 'Happy';
    }
  }

  // Settings Management
  Future<JournalingSettings> getSettings() async {
    try {
      if (_userId.isEmpty) {
        print('DEBUG: getSettings - User ID is empty');
        return JournalingSettings();
      }

      print('DEBUG: Fetching journaling settings');
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('journaling')
          .get();

      if (doc.exists) {
        print('DEBUG: Settings loaded successfully');
        return JournalingSettings.fromJson(doc.data()!);
      }
      print('DEBUG: No settings found, using defaults');
      return JournalingSettings();
    } catch (e, stackTrace) {
      print('ERROR: getSettings failed - $e');
      print('STACK TRACE: $stackTrace');
      return JournalingSettings();
    }
  }

  Future<void> updateSettings(JournalingSettings settings) async {
    try {
      if (_userId.isEmpty) {
        print('ERROR: updateSettings - User not logged in');
        throw Exception('User not logged in');
      }

      print('DEBUG: Updating journaling settings');
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('journaling')
          .set(settings.toJson());

      print('DEBUG: Settings updated successfully');
    } catch (e, stackTrace) {
      print('ERROR: updateSettings failed - $e');
      print('STACK TRACE: $stackTrace');
      rethrow;
    }
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
    try {
      if (_userId.isEmpty) {
        print('DEBUG: generateWeeklyInsight - User ID is empty');
        return WeeklyInsight(
          weekStart: DateTime.now(),
          weekEnd: DateTime.now(),
          moodPercentages: {},
          topTopics: [],
          suggestions: [],
          affirmation: 'Keep going!',
          totalEntries: 0,
        );
      }

      print('DEBUG: Generating weekly insight');
      DateTime now = DateTime.now();
      DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
      DateTime weekEnd = weekStart.add(Duration(days: 6));

      // Get this week's moods
      final moodsSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('moods')
          .where('timestamp', isGreaterThan: weekStart.toIso8601String())
          .where('timestamp', isLessThan: weekEnd.toIso8601String())
          .get();

      // Calculate mood percentages
      Map<String, int> moodCounts = {};
      for (var doc in moodsSnapshot.docs) {
        String mood = doc.data()['mood'];
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }

      int totalMoods = moodsSnapshot.docs.length;
      Map<String, double> moodPercentages = {};
      if (totalMoods > 0) {
        moodCounts.forEach((mood, count) {
          moodPercentages[mood] = (count / totalMoods) * 100;
        });
      }

      // Get this week's entries
      final entriesSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('journal_entries')
          .where('timestamp', isGreaterThan: weekStart.toIso8601String())
          .where('timestamp', isLessThan: weekEnd.toIso8601String())
          .get();

      // Extract top topics from tags
      Map<String, int> tagCounts = {};
      for (var doc in entriesSnapshot.docs) {
        List<String> tags = List<String>.from(doc.data()['tags'] ?? []);
        for (var tag in tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      var sortedEntries = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      List<String> topics = sortedEntries.take(4).map((e) => e.key).toList();

      // Generate suggestions based on moods
      List<String> suggestions = _generateSuggestions(moodPercentages);

      // Generate affirmation
      String affirmation = _generateAffirmation();

      print('DEBUG: Weekly insight generated successfully');
      return WeeklyInsight(
        weekStart: weekStart,
        weekEnd: weekEnd,
        moodPercentages: moodPercentages,
        topTopics: topics.isEmpty ? ['No topics yet'] : topics,
        suggestions: suggestions,
        affirmation: affirmation,
        totalEntries: entriesSnapshot.docs.length,
      );
    } catch (e, stackTrace) {
      print('ERROR: generateWeeklyInsight failed - $e');
      print('STACK TRACE: $stackTrace');
      return WeeklyInsight(
        weekStart: DateTime.now(),
        weekEnd: DateTime.now(),
        moodPercentages: {},
        topTopics: ['Error loading topics'],
        suggestions: ['Keep journaling regularly'],
        affirmation: 'You are doing great!',
        totalEntries: 0,
      );
    }
  }

  List<String> _generateSuggestions(Map<String, double> moodPercentages) {
    List<String> suggestions = [];

    if ((moodPercentages['Anxious'] ?? 0) > 30) {
      suggestions.add('Consider meditation before stressful events');
      suggestions.add('Try deep breathing exercises');
    }
    if ((moodPercentages['Overwhelmed'] ?? 0) > 20) {
      suggestions.add('Break tasks into smaller, manageable steps');
      suggestions.add('Take regular breaks throughout the day');
    }
    if ((moodPercentages['Sad'] ?? 0) > 25) {
      suggestions.add('Reach out to friends or family');
      suggestions.add('Try activities that bring you joy');
    }

    if (suggestions.isEmpty) {
      suggestions = [
        'Keep journaling regularly to track your progress',
        'Maintain a healthy sleep schedule',
        'Stay connected with loved ones',
      ];
    }

    return suggestions.take(3).toList();
  }

  String _generateAffirmation() {
    List<String> affirmations = [
      'You are capable of handling whatever challenges come your way.',
      'Your feelings are valid and it\'s okay to not be okay sometimes.',
      'You are stronger than you think, braver than you believe.',
      'Every day is a new opportunity for growth and healing.',
      'You deserve kindness, especially from yourself.',
    ];
    return affirmations[Random().nextInt(affirmations.length)];
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
  State<JournalingPage> createState() => _JournalingPageState();
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

  String _currentMood = 'Happy';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      print('DEBUG: JournalingPage - Loading all journal data');
      final entries = await _service.getAllEntries();
      final passiveEntries = await _service.getPassiveEntries();
      final activeEntries = await _service.getActiveEntries();
      final settings = await _service.getSettings();
      final weeklyInsight = await _service.generateWeeklyInsight();
      final dailyPrompt = await _service.getDailyPrompt();
      final currentMood = await _service.getCurrentMood();

      setState(() {
        _allEntries = entries;
        _passiveEntries = passiveEntries;
        _activeEntries = activeEntries;
        _settings = settings;
        _weeklyInsight = weeklyInsight;
        _dailyPrompt = dailyPrompt;
        _currentMood = currentMood;
        _isLoading = false;
      });
      print('DEBUG: JournalingPage - All data loaded successfully');
    } catch (e, stackTrace) {
      print('ERROR: JournalingPage - Failed to load data: $e');
      print('STACK TRACE: $stackTrace');

      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showErrorSnackBar('Failed to load data: ${e.toString()}');
    }
  }

  Future<void> _updateMood(String mood) async {
    try {
      print('DEBUG: JournalingPage - Updating mood to: $mood');
      await _service.updateCurrentMood(mood, 7.0); // Default intensity
      setState(() {
        _currentMood = mood;
      });
      _showSuccessSnackBar('Mood updated to $mood');
      print('DEBUG: JournalingPage - Mood UI updated');
    } catch (e, stackTrace) {
      print('ERROR: JournalingPage - Failed to update mood: $e');
      print('STACK TRACE: $stackTrace');
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
      print('DEBUG: JournalingPage - Toggling setting: $setting to $value');
      await _service.updateSettings(newSettings);
      setState(() => _settings = newSettings);
      _showSuccessSnackBar('Settings updated');
      print('DEBUG: JournalingPage - Setting updated successfully');
    } catch (e, stackTrace) {
      print('ERROR: JournalingPage - Failed to update setting: $e');
      print('STACK TRACE: $stackTrace');
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
      print('DEBUG: JournalingPage - Saving journal entry: ${entry.title}');
      await _service.createEntry(entry);
      print('DEBUG: JournalingPage - Reloading data after save');
      await _loadData(); // Refresh data
      _showSuccessSnackBar('Entry saved successfully');
    } catch (e, stackTrace) {
      print('ERROR: JournalingPage - Failed to save entry: $e');
      print('STACK TRACE: $stackTrace');
      _showErrorSnackBar('Failed to save entry: ${e.toString()}');
    }
  }

  Future<void> _deleteEntry(String id) async {
    try {
      print('DEBUG: JournalingPage - Deleting entry: $id');
      await _service.deleteEntry(id);
      print('DEBUG: JournalingPage - Reloading data after delete');
      await _loadData(); // Refresh data
      _showSuccessSnackBar('Entry deleted');
    } catch (e, stackTrace) {
      print('ERROR: JournalingPage - Failed to delete entry: $e');
      print('STACK TRACE: $stackTrace');
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Journal',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.refresh, color: Colors.grey[700], size: 20),
            ),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.settings_outlined,
                  color: Colors.grey[700], size: 20),
            ),
            onPressed: () => _showSettingsDialog(),
          ),
          const SizedBox(width: 8),
        ],
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showCreateEntryDialog(
              JournalEntryType.free_write, 'New Entry', ''),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
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
              padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Mood Today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMoodIcon('😊', 'Happy', _currentMood == 'Happy'),
                      SizedBox(width: 16),
                      _buildMoodIcon(
                          '😰', 'Anxious', _currentMood == 'Anxious'),
                      SizedBox(width: 16),
                      _buildMoodIcon('😴', 'Tired', _currentMood == 'Tired'),
                      SizedBox(width: 16),
                      _buildMoodIcon(
                          '🤔', 'Thoughtful', _currentMood == 'Thoughtful'),
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
        padding: const EdgeInsets.all(16),
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
                const SizedBox(width: 12),
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

            const SizedBox(height: 16),

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
                const SizedBox(width: 12),
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

            const SizedBox(height: 24),

            // Recent Active Entries
            Text(
              'Your Entries',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

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
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly Digest Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF8B5CF6), const Color(0xFF6366F1)],
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
                  const SizedBox(height: 8),
                  Text(
                    '${_formatDate(_weeklyInsight!.weekStart)} - ${_formatDate(_weeklyInsight!.weekEnd)}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
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

            const SizedBox(height: 24),

            // Mood Patterns
            _buildInsightCard(
              'Mood Patterns',
              'You tend to feel more anxious on weekdays, especially Mondays and Wednesdays. Your mood improves significantly on weekends.',
              Icons.trending_up,
              const Color(0xFF6366F1),
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
              const Color(0xFF6366F1),
            ),

            // Suggestions
            _buildInsightCard(
              'Personalized Suggestions',
              _weeklyInsight!.suggestions.join('\n• '),
              Icons.lightbulb_outlined,
              const Color(0xFF6366F1),
            ),

            // Affirmations
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
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
