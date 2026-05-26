import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  // Remote URL for media-backed entries (audio for voice notes, PNG for
  // doodles). Stored alongside the entry; null for plain text entries.
  final String? mediaUrl;
  // Firebase Storage path so we can delete the underlying file on delete.
  final String? mediaPath;
  // Recording duration in milliseconds for voice notes.
  final int? mediaDurationMs;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.tags,
    required this.moods,
    required this.type,
    this.isPassive = false,
    this.mediaUrl,
    this.mediaPath,
    this.mediaDurationMs,
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
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (mediaPath != null) 'mediaPath': mediaPath,
        if (mediaDurationMs != null) 'mediaDurationMs': mediaDurationMs,
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
          orElse: () => JournalEntryType.free_write,
        ),
        isPassive: json['isPassive'] as bool? ?? false,
        mediaUrl: json['mediaUrl'] as String?,
        mediaPath: json['mediaPath'] as String?,
        mediaDurationMs: json['mediaDurationMs'] as int?,
      );

  JournalEntry copyWith({
    String? id,
    String? mediaUrl,
    String? mediaPath,
    int? mediaDurationMs,
  }) =>
      JournalEntry(
        id: id ?? this.id,
        title: title,
        content: content,
        timestamp: timestamp,
        tags: tags,
        moods: moods,
        type: type,
        isPassive: isPassive,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        mediaPath: mediaPath ?? this.mediaPath,
        mediaDurationMs: mediaDurationMs ?? this.mediaDurationMs,
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
  // AI-generated narrative reflection on the user's week.
  final String? aiReflection;
  // Bulleted guidance steps from the AI.
  final List<String> aiGuidance;
  // Short summary line for the mood distribution.
  final String? moodSummary;

  WeeklyInsight({
    required this.weekStart,
    required this.weekEnd,
    required this.moodPercentages,
    required this.topTopics,
    required this.suggestions,
    required this.affirmation,
    required this.totalEntries,
    this.aiReflection,
    this.aiGuidance = const [],
    this.moodSummary,
  });

  WeeklyInsight copyWith({
    String? aiReflection,
    List<String>? aiGuidance,
    String? moodSummary,
  }) =>
      WeeklyInsight(
        weekStart: weekStart,
        weekEnd: weekEnd,
        moodPercentages: moodPercentages,
        topTopics: topTopics,
        suggestions: suggestions,
        affirmation: affirmation,
        totalEntries: totalEntries,
        aiReflection: aiReflection ?? this.aiReflection,
        aiGuidance: aiGuidance ?? this.aiGuidance,
        moodSummary: moodSummary ?? this.moodSummary,
      );
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
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // ── Media uploads ──────────────────────────────────────────
  // Voice notes are saved under users/<uid>/voice_notes/<entryId>.m4a
  // Doodles are saved under users/<uid>/doodles/<entryId>.png
  Future<({String url, String path})> uploadVoiceNote({
    required String entryId,
    required File file,
  }) async {
    if (_userId.isEmpty) {
      throw StateError('Cannot upload voice note: no signed-in user.');
    }
    final path = 'users/$_userId/voice_notes/$entryId.m4a';
    final ref = _storage.ref().child(path);
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'audio/m4a'),
    );
    final url = await ref.getDownloadURL();
    return (url: url, path: path);
  }

  Future<({String url, String path})> uploadDoodle({
    required String entryId,
    required Uint8List bytes,
  }) async {
    if (_userId.isEmpty) {
      throw StateError('Cannot upload doodle: no signed-in user.');
    }
    final path = 'users/$_userId/doodles/$entryId.png';
    final ref = _storage.ref().child(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/png'),
    );
    final url = await ref.getDownloadURL();
    return (url: url, path: path);
  }

  // ── Gemini-powered AI reflection ──────────────────────────
  static const String _geminiKeyPath = 'config/gemini_api_key';
  String? _cachedGeminiKey;
  bool _refreshingAi = false;
  bool get refreshingAi => _refreshingAi;

  Future<String> _loadGeminiKey() async {
    if (_cachedGeminiKey != null && _cachedGeminiKey!.isNotEmpty) {
      return _cachedGeminiKey!;
    }
    final snap =
        await FirebaseDatabase.instance.ref().child(_geminiKeyPath).get();
    if (!snap.exists) {
      throw StateError('Gemini API key missing at $_geminiKeyPath');
    }
    final value = snap.value;
    if (value is! String || value.trim().isEmpty) {
      throw StateError('Gemini API key invalid at $_geminiKeyPath');
    }
    _cachedGeminiKey = value.trim();
    return _cachedGeminiKey!;
  }

  // Builds a compact prompt from this week's moods, top topics, and a few
  // recent journal excerpts, then asks Gemini to produce a JSON object with:
  //   { "summary": "...", "reflection": "...", "guidance": ["...", "..."] }
  // Falls back gracefully if anything throws or the response isn't valid JSON.
  Future<WeeklyInsight> _enrichWithAi(WeeklyInsight base) async {
    if (_userId.isEmpty) return base;
    try {
      final key = await _loadGeminiKey();

      final moodLines = base.moodPercentages.entries
          .map((e) => '${e.key}: ${e.value.toStringAsFixed(0)}%')
          .join(', ');
      // Pull up to 5 recent journal excerpts for context — keep each short
      // to bound token usage.
      final recent = activeEntries
          .where((e) => e.content.trim().isNotEmpty)
          .take(5)
          .map((e) {
        final excerpt = e.content.length > 240
            ? '${e.content.substring(0, 240)}…'
            : e.content;
        return '- (${e.type.toString().split('.').last}) $excerpt';
      }).join('\n');

      final prompt = '''
You are a warm, non-judgmental teen wellness companion helping a user reflect
on their week from their journal data.

Mood distribution this week: ${moodLines.isEmpty ? 'no mood entries' : moodLines}
Top topics: ${base.topTopics.join(', ')}
Total journal entries: ${base.totalEntries}
Current mood right now: $currentMood

Recent journal excerpts:
${recent.isEmpty ? '(no entries yet)' : recent}

Respond with **valid JSON only** (no markdown fences, no commentary) using
this exact shape:

{
  "summary": "One short sentence summarising the emotional shape of the week.",
  "reflection": "2–4 sentences gently reflecting back what stands out. Use 'you'. Be specific to the data above. Validating, never clinical.",
  "guidance": [
    "Concrete, kind step the user could try this week.",
    "Another small actionable step.",
    "Optional third step."
  ]
}
''';

      final res = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$key',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'temperature': 0.7,
          },
        }),
      );

      if (res.statusCode != 200) {
        log('Gemini insight call failed: ${res.statusCode} ${res.body}');
        return base;
      }

      final body = jsonDecode(res.body);
      final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text is! String || text.trim().isEmpty) return base;

      Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(text) as Map<String, dynamic>;
      } catch (_) {
        // Fallback: try to pull JSON out of the response if the model wrapped it.
        final start = text.indexOf('{');
        final end = text.lastIndexOf('}');
        if (start < 0 || end <= start) return base;
        parsed = jsonDecode(text.substring(start, end + 1))
            as Map<String, dynamic>;
      }

      final guidance = (parsed['guidance'] as List?)
              ?.map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          const <String>[];

      return base.copyWith(
        aiReflection: (parsed['reflection'] as String?)?.trim(),
        aiGuidance: guidance,
        moodSummary: (parsed['summary'] as String?)?.trim(),
      );
    } catch (e, stack) {
      log('AI insight enrichment failed: $e\n$stack');
      return base;
    }
  }

  // Force a fresh AI reflection (used by the "regenerate" button in UI).
  Future<void> refreshAiInsight() async {
    if (weeklyInsight == null) return;
    _refreshingAi = true;
    notifyListeners();
    final enriched = await _enrichWithAi(weeklyInsight!);
    weeklyInsight = enriched;
    _refreshingAi = false;
    notifyListeners();
  }

  Future<void> _deleteStorageFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      await _storage.ref().child(path).delete();
    } catch (_) {
      // Swallow — file may already be gone.
    }
  }

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

  Future<JournalEntry> createEntry(JournalEntry entry) async {
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
      mediaUrl: entry.mediaUrl,
      mediaPath: entry.mediaPath,
      mediaDurationMs: entry.mediaDurationMs,
    );

    allEntries.insert(0, saved);
    if (saved.isPassive) {
      passiveEntries.insert(0, saved);
    } else {
      activeEntries.insert(0, saved);
    }
    notifyListeners();
    return saved;
  }

  // Attach uploaded media to an entry that already exists.
  Future<void> attachMedia(
    String entryId, {
    required String mediaUrl,
    required String mediaPath,
    int? mediaDurationMs,
  }) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('journal_entries')
        .doc(entryId)
        .update({
      'mediaUrl': mediaUrl,
      'mediaPath': mediaPath,
      if (mediaDurationMs != null) 'mediaDurationMs': mediaDurationMs,
    });

    void replace(List<JournalEntry> list) {
      final idx = list.indexWhere((e) => e.id == entryId);
      if (idx == -1) return;
      list[idx] = list[idx].copyWith(
        mediaUrl: mediaUrl,
        mediaPath: mediaPath,
        mediaDurationMs: mediaDurationMs,
      );
    }

    replace(allEntries);
    replace(activeEntries);
    replace(passiveEntries);
    notifyListeners();
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
    // Look up any media path so we can clean up Firebase Storage too.
    String? mediaPath;
    final existing = allEntries.firstWhere(
      (e) => e.id == id,
      orElse: () => JournalEntry(
        id: '',
        title: '',
        content: '',
        timestamp: DateTime.now(),
        tags: const [],
        moods: const [],
        type: JournalEntryType.free_write,
      ),
    );
    if (existing.id.isNotEmpty) mediaPath = existing.mediaPath;

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('journal_entries')
        .doc(id)
        .delete();

    await _deleteStorageFile(mediaPath);

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

      final base = WeeklyInsight(
        weekStart: weekStart,
        weekEnd: weekEnd,
        moodPercentages: moodPct,
        topTopics: topics.isEmpty ? ['No topics yet'] : topics,
        suggestions: _suggestions(moodPct),
        affirmation: _affirmation(),
        totalEntries: entriesSnap.docs.length,
      );
      // Layer in AI reflection / guidance on top of the deterministic stats.
      return await _enrichWithAi(base);
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
