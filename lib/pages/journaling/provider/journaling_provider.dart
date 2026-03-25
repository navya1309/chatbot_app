import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────
//  Data Models
// ─────────────────────────────────────────

enum JournalEntryType {
  daily_prompt,
  free_write,
  voice_note,
  doodle,
  gratitude,
  auto_reflection,
  conversation_summary,
}

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'tags': tags,
        'moods': moods,
        'type': type.toString().split('.').last,
        'isPassive': isPassive,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        tags: List<String>.from(json['tags'] as List),
        moods: List<String>.from(json['moods'] as List),
        type: JournalEntryType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
        ),
        isPassive: json['isPassive'] as bool? ?? false,
      );
}

class MoodData {
  final String mood;
  final String emoji;
  final DateTime timestamp;
  final double intensity;

  MoodData({
    required this.mood,
    required this.emoji,
    required this.timestamp,
    required this.intensity,
  });

  Map<String, dynamic> toJson() => {
        'mood': mood,
        'emoji': emoji,
        'timestamp': timestamp.toIso8601String(),
        'intensity': intensity,
      };

  factory MoodData.fromJson(Map<String, dynamic> json) => MoodData(
        mood: json['mood'] as String,
        emoji: json['emoji'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        intensity: (json['intensity'] as num).toDouble(),
      );
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

  Map<String, dynamic> toJson() => {
        'autoConversationSummary': autoConversationSummary,
        'moodAutoTagging': moodAutoTagging,
        'triggerBasedEntries': triggerBasedEntries,
        'weeklyDigest': weeklyDigest,
      };

  factory JournalingSettings.fromJson(Map<String, dynamic> json) =>
      JournalingSettings(
        autoConversationSummary:
            json['autoConversationSummary'] as bool? ?? true,
        moodAutoTagging: json['moodAutoTagging'] as bool? ?? true,
        triggerBasedEntries: json['triggerBasedEntries'] as bool? ?? false,
        weeklyDigest: json['weeklyDigest'] as bool? ?? true,
      );
}

// ─────────────────────────────────────────
//  Provider
// ─────────────────────────────────────────

class JournalingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // ── State ──
  List<JournalEntry> allEntries = [];
  List<JournalEntry> passiveEntries = [];
  List<JournalEntry> activeEntries = [];
  JournalingSettings settings = JournalingSettings();
  WeeklyInsight? weeklyInsight;
  String dailyPrompt = '';
  String currentMood = 'Happy';
  bool isLoading = false;
  String? error;

  // ─────────── Load ───────────

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _getAllEntries(),
        _getPassiveEntries(),
        _getActiveEntries(),
        _getSettings(),
        _generateWeeklyInsight(),
        _getDailyPrompt(),
        _getCurrentMood(),
      ]);

      allEntries = results[0] as List<JournalEntry>;
      passiveEntries = results[1] as List<JournalEntry>;
      activeEntries = results[2] as List<JournalEntry>;
      settings = results[3] as JournalingSettings;
      weeklyInsight = results[4] as WeeklyInsight;
      dailyPrompt = results[5] as String;
      currentMood = results[6] as String;
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  // ─────────── CRUD ───────────

  Future<void> createEntry(JournalEntry entry) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('journal_entries')
          .add(entry.toJson());

      final saved = JournalEntry(
        id: docRef.id,
        title: entry.title,
        content: entry.content,
        timestamp: entry.timestamp,
        tags: entry.tags,
        moods: entry.moods,
        type: entry.type,
        isPassive: entry.isPassive,
      );

      allEntries.insert(0, saved);
      if (saved.isPassive) {
        passiveEntries.insert(0, saved);
      } else {
        activeEntries.insert(0, saved);
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEntry(JournalEntry entry) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('journal_entries')
        .doc(entry.id)
        .update(entry.toJson());

    _replaceInList(allEntries, entry);
    _replaceInList(entry.isPassive ? passiveEntries : activeEntries, entry);
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('journal_entries')
        .doc(id)
        .delete();

    allEntries.removeWhere((e) => e.id == id);
    passiveEntries.removeWhere((e) => e.id == id);
    activeEntries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ─────────── Mood ───────────

  Future<void> updateMood(String mood) async {
    final moodData = MoodData(
      mood: mood,
      emoji: _moodEmoji(mood),
      timestamp: DateTime.now(),
      intensity: 7.0,
    );

    await Future.wait([
      _firestore
          .collection('users')
          .doc(_userId)
          .collection('moods')
          .add(moodData.toJson()),
      _firestore
          .collection('users')
          .doc(_userId)
          .set({'currentMood': mood}, SetOptions(merge: true)),
    ]);

    currentMood = mood;
    notifyListeners();
  }

  // ─────────── Settings ───────────

  Future<void> toggleSetting(String key, bool value) async {
    final updated = JournalingSettings(
      autoConversationSummary:
          key == 'autoConversationSummary' ? value : settings.autoConversationSummary,
      moodAutoTagging: key == 'moodAutoTagging' ? value : settings.moodAutoTagging,
      triggerBasedEntries:
          key == 'triggerBasedEntries' ? value : settings.triggerBasedEntries,
      weeklyDigest: key == 'weeklyDigest' ? value : settings.weeklyDigest,
    );

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('settings')
        .doc('journaling')
        .set(updated.toJson());

    settings = updated;
    notifyListeners();
  }

  // ─────────── Helpers (internal) ───────────

  Future<List<JournalEntry>> _getAllEntries() async {
    if (_userId.isEmpty) return [];
    final snap = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('journal_entries')
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs
        .map((d) => JournalEntry.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  Future<List<JournalEntry>> _getPassiveEntries() async {
    if (_userId.isEmpty) return [];
    final snap = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('journal_entries')
        .where('isPassive', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => JournalEntry.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  Future<List<JournalEntry>> _getActiveEntries() async {
    if (_userId.isEmpty) return [];
    final snap = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('journal_entries')
        .where('isPassive', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs
        .map((d) => JournalEntry.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  Future<JournalingSettings> _getSettings() async {
    if (_userId.isEmpty) return JournalingSettings();
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('settings')
        .doc('journaling')
        .get();
    return doc.exists
        ? JournalingSettings.fromJson(doc.data()!)
        : JournalingSettings();
  }

  Future<String> _getCurrentMood() async {
    if (_userId.isEmpty) return 'Happy';
    final doc = await _firestore.collection('users').doc(_userId).get();
    return doc.data()?['currentMood'] as String? ?? 'Happy';
  }

  Future<String> _getDailyPrompt() async {
    final prompts = [
      'What made you smile today?',
      "What's something you wish more people knew about you?",
      'Describe a moment when you felt proud of yourself.',
      'What are you grateful for right now?',
      "What's been on your mind lately?",
      'How did you grow today?',
      'What would you tell your younger self?',
      "What's something beautiful you noticed today?",
      'What emotion are you sitting with right now?',
      'If today had a color, what would it be and why?',
    ];
    return prompts[Random().nextInt(prompts.length)];
  }

  Future<WeeklyInsight> _generateWeeklyInsight() async {
    if (_userId.isEmpty) {
      return _emptyInsight();
    }

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final moodsSnap = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('moods')
          .where('timestamp', isGreaterThan: weekStart.toIso8601String())
          .where('timestamp', isLessThan: weekEnd.toIso8601String())
          .get();

      final moodCounts = <String, int>{};
      for (final doc in moodsSnap.docs) {
        final mood = doc.data()['mood'] as String;
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
      final total = moodsSnap.docs.length;
      final moodPct = <String, double>{};
      if (total > 0) {
        moodCounts.forEach(
            (k, v) => moodPct[k] = (v / total) * 100);
      }

      final entriesSnap = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('journal_entries')
          .where('timestamp', isGreaterThan: weekStart.toIso8601String())
          .where('timestamp', isLessThan: weekEnd.toIso8601String())
          .get();

      final tagCounts = <String, int>{};
      for (final doc in entriesSnap.docs) {
        for (final tag in List<String>.from(doc.data()['tags'] ?? [])) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      final topics = (tagCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(4)
          .map((e) => e.key)
          .toList();

      return WeeklyInsight(
        weekStart: weekStart,
        weekEnd: weekEnd,
        moodPercentages: moodPct,
        topTopics: topics.isEmpty ? ['No topics yet'] : topics,
        suggestions: _suggestions(moodPct),
        affirmation: _affirmation(),
        totalEntries: entriesSnap.docs.length,
      );
    } catch (_) {
      return _emptyInsight();
    }
  }

  WeeklyInsight _emptyInsight() => WeeklyInsight(
        weekStart: DateTime.now(),
        weekEnd: DateTime.now(),
        moodPercentages: {},
        topTopics: ['No topics yet'],
        suggestions: ['Keep journaling regularly'],
        affirmation: 'You are doing great!',
        totalEntries: 0,
      );

  List<String> _suggestions(Map<String, double> pct) {
    final s = <String>[];
    if ((pct['Anxious'] ?? 0) > 30) {
      s.addAll(['Try a 4-7-8 breathing exercise', 'Limit doomscrolling']);
    }
    if ((pct['Overwhelmed'] ?? 0) > 20) {
      s.addAll(['Break tasks into tiny steps', 'Take 10-min breaks']);
    }
    if ((pct['Sad'] ?? 0) > 25) {
      s.addAll(['Reach out to a friend', 'Go for a short walk']);
    }
    if (s.isEmpty) {
      s.addAll([
        'Journal daily to track your journey',
        'Celebrate small wins 🎉',
        'Stay hydrated & sleep well',
      ]);
    }
    return s.take(3).toList();
  }

  String _affirmation() {
    const list = [
      'You are capable of handling whatever comes your way. 💪',
      "Your feelings are valid — it's okay to not be okay sometimes.",
      'You are stronger than you think, braver than you believe. ✨',
      'Every day is a new opportunity for growth and healing.',
      'You deserve kindness, especially from yourself. 💜',
    ];
    return list[Random().nextInt(list.length)];
  }

  String _moodEmoji(String mood) {
    const map = {
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
    return map[mood] ?? '😐';
  }

  void _replaceInList(List<JournalEntry> list, JournalEntry entry) {
    final index = list.indexWhere((e) => e.id == entry.id);
    if (index != -1) list[index] = entry;
  }

  // Public getter convenience helpers
  String get moodEmoji => _moodEmoji(currentMood);

  String labelForType(JournalEntryType type) {
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
        return 'Gratitude';
      case JournalEntryType.auto_reflection:
        return 'Auto Reflection';
      case JournalEntryType.conversation_summary:
        return 'Chat Summary';
    }
  }
}
