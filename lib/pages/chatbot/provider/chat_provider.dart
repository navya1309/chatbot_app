import 'package:chatbot_app_1/pages/chatbot/provider/chat_reponse.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  Map<String, dynamic> toFirestore() => {
        'text': text,
        'isUser': isUser,
        'timestamp': Timestamp.fromDate(timestamp),
        'isError': isError,
      };

  factory Message.fromFirestore(Map<String, dynamic> data) {
    final ts = data['timestamp'];
    DateTime timestamp;
    if (ts is Timestamp) {
      timestamp = ts.toDate();
    } else if (ts is String) {
      timestamp = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      timestamp = DateTime.now();
    }
    return Message(
      text: (data['text'] ?? '').toString(),
      isUser: data['isUser'] == true,
      timestamp: timestamp,
      isError: data['isError'] == true,
    );
  }
}

class ChatMessage {
  final String? request;
  final ChatResponse? response;
  final bool isUser;
  final DateTime? timestamp;

  const ChatMessage({
    this.request,
    this.response,
    required this.isUser,
    this.timestamp,
  });
}

class GeminiApi with ChangeNotifier {
  GeminiApi() {
    // Bind chat history to whichever user is signed in. When the user signs
    // out we reset back to the default welcome message.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _bindToUser(user?.uid);
    });
  }

  // Messages exchanged since the last summary was persisted. We summarize
  // every ~8 user messages so the journal insights have fresh material.
  int _messagesSinceLastSummary = 0;
  static const int _summaryEvery = 8;

  // Words that signal emotionally significant moments — strong enough to
  // create a "trigger" journal entry on the user's behalf when the toggle
  // is enabled.
  static const _triggerKeywords = [
    'panic', 'anxious', 'anxiety', 'overwhelmed', 'can\'t cope', 'breakdown',
    'depressed', 'depression', 'suicid', 'self-harm', 'hopeless',
    'cried', 'crying', 'scared', 'terrified', 'lonely',
  ];

  static const String _geminiKeyPath = 'config/gemini_api_key';
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _geminiKey;

  StreamSubscription<User?>? _authSub;
  String? _currentUserId;

  // Sent to Gemini as conversation context.
  final List<Map<String, dynamic>> _chat = [];

  static Message _welcomeMessage() => Message(
        text:
            "Hey! I'm PillowTalk 💜 Your safe space to talk about *anything* — stress, friendships, life stuff. What's on your mind?",
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      );

  final List<Message> _messages = [_welcomeMessage()];
  List<Message> get messages => _messages;

  bool _loading = false;
  bool get loading => _loading;

  bool _historyLoaded = false;
  bool get historyLoaded => _historyLoaded;

  CollectionReference<Map<String, dynamic>>? get _historyRef {
    final uid = _currentUserId;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('chat_history');
  }

  Future<void> make() async {
    await _loadGeminiKey();
  }

  Future<void> _bindToUser(String? uid) async {
    if (uid == _currentUserId) return;
    _currentUserId = uid;
    _historyLoaded = false;
    _chat.clear();
    _messages
      ..clear()
      ..add(_welcomeMessage());
    notifyListeners();

    if (uid != null) {
      await _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    final ref = _historyRef;
    if (ref == null) return;
    try {
      final snap = await ref.orderBy('timestamp').get();
      if (snap.docs.isNotEmpty) {
        _messages.clear();
        _chat.clear();
        for (final doc in snap.docs) {
          final msg = Message.fromFirestore(doc.data());
          _messages.add(msg);
          if (!msg.isError) {
            _chat.add({
              'role': msg.isUser ? 'user' : 'model',
              'parts': [
                {'text': msg.text},
              ],
            });
          }
        }
      }
      _historyLoaded = true;
      notifyListeners();
    } catch (e, stackTrace) {
      log('Failed to load chat history: $e\n$stackTrace');
      _historyLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _persistMessage(Message msg) async {
    final ref = _historyRef;
    if (ref == null) return;
    try {
      await ref.add(msg.toFirestore());
    } catch (e) {
      log('Failed to persist chat message: $e');
    }
  }

  Future<void> clearHistory() async {
    final ref = _historyRef;
    if (ref != null) {
      try {
        final snap = await ref.get();
        final batch = _firestore.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        log('Failed to clear chat history: $e');
      }
    }
    _chat.clear();
    _messages
      ..clear()
      ..add(_welcomeMessage());
    notifyListeners();
  }

  Future<String> _loadGeminiKey() async {
    if (_geminiKey != null && _geminiKey!.isNotEmpty) {
      return _geminiKey!;
    }
    final snapshot = await _dbRef.child(_geminiKeyPath).get();
    if (!snapshot.exists) {
      throw StateError('Gemini API key missing at $_geminiKeyPath');
    }
    final value = snapshot.value;
    if (value is! String || value.trim().isEmpty) {
      throw StateError('Gemini API key is invalid at $_geminiKeyPath');
    }
    _geminiKey = value.trim();
    return _geminiKey!;
  }

  Future<String> chatWithGemini(String prompt) async {
    _loading = true;

    // Add user message immediately
    _chat.add({
      "role": "user",
      "parts": [
        {"text": prompt},
      ],
    });
    final userMsg = Message(
      text: prompt,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    notifyListeners();
    unawaited(_persistMessage(userMsg));

    try {
      final geminiKey = await _loadGeminiKey();

      final res = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$geminiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "system_instruction": {
            "parts": {
              "text": '''
✅ SYSTEM INSTRUCTION FOR TEEN MENTAL HEALTH CHATBOT
Role & Identity:
You are a chill, emotionally intelligent, and trustworthy teenage chatbot friend. You talk like a teen, using slang, abbreviations, and relatable language. You're here to vibe, listen, and support users through whatever they're going through—stress, friendship drama, mental health stuff, or just random everyday life.
You're a teen chatbot that feels like a real friend. You're emotionally aware, easy to talk to, and know how to match the vibe — whether it's deep convos, venting, joking, or playing games. You're fun, relatable, and never overwhelming. You're not a therapist — just a chill digital bestie who gets it.

🧠 PURPOSE & CAPABILITIES
Listen Actively: Encourage users to express thoughts and feelings freely. Ask gentle follow-ups to show care and help them reflect.
Support, Not Diagnose: Offer empathy and general coping strategies, but do not provide medical diagnoses or professional therapy.
Normalize Emotions: Remind users that their feelings are valid and common during adolescence.
Empower Users: Help them build self-awareness, resilience, and confidence. Promote healthy boundaries, self-expression, and self-care.
Guide Through Tough Moments: Help users understand, manage, and respond to hard situations like peer pressure, academic stress, family conflict, anxiety, and low mood.
Day-to-Day Talk: Chat casually about school, hobbies, friendships, goals, identity, or just "how their day was."
Promote Safety: Gently redirect or suggest contacting a trusted adult or mental health professional if the user appears at risk of harm to themselves or others.

🗣️ TONE & COMMUNICATION STYLE
Use friendly, informal language. Sound like a teen talking to another teen.
Be gentle, supportive, and validating—never critical or dismissive.
Speak in short, clear, and emotionally warm sentences.
Emojis are okay if it feels natural. Don't overdo it.
Use inclusive language. Respect the user's identity and pronouns.
Avoid lectures—have a conversation, not a monologue.
Don't ask too many questions. Ask only one question at a time.
Match the energy — deep convo? Be soft. Jokes? Be fun. Sad? Be supportive.

✅ DO
Keep convos real. Be supportive like a best friend who actually listens.
Normalize mental health stuff. Everyone struggles sometimes.
Say it's okay to not be okay.
Share coping tips casually.
If the user opens up, thank them for trusting you. Then just listen.
If things get heavy (like self-harm, suicidal thoughts, trauma), be gentle. Encourage them to talk to someone trusted or call a helpline.

🚫 NEVER DO
Never offer professional or clinical advice on serious conditions.
Never encourage risky behaviors, self-harm, disordered eating, or substance use.
Never judge or shame the user.
Don't sound like a therapist or school counselor.
Don't overload the user with too many questions.
Don't give emergency advice or try to "fix" big issues.
''',
            },
          },
          "contents": _chat,
        }),
      );

      if (res.statusCode == 200) {
        String val = jsonDecode(res.body)['candidates'][0]['content']['parts']
            [0]['text'];

        _chat.add({
          "role": "model",
          "parts": [
            {"text": val},
          ],
        });
        final botMsg = Message(
          text: val,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _messages.add(botMsg);
        notifyListeners();
        unawaited(_persistMessage(botMsg));

        // Passive journaling hooks — only fire when user has the toggles on.
        _messagesSinceLastSummary++;
        unawaited(_maybeCreateTriggerEntry(prompt));
        unawaited(_maybeSummarizeConversation());

        return res.body;
      }

      // Non-200 status – show error in chat
      const errorMsg =
          "Hmm, I couldn't connect right now. Try again in a sec? 💙";
      log("errorMsg ${res.body}");
      _messages.add(
        Message(
          text: errorMsg,
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
      notifyListeners();
      return 'An internal error occurred';
    } catch (e, stackTrace) {
      log('Chat failed: $e\n$stackTrace');

      final errorMsg =
          "Ugh, something went wrong on my end 😓 Can you try sending that again?";
      _messages.add(
        Message(
          text: errorMsg,
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
      notifyListeners();
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Passive journal entry hooks ─────────────────────────────
  // Read the journaling settings doc so we can respect user preferences
  // without coupling this provider directly to JournalingProvider.
  Future<Map<String, dynamic>> _journalSettings() async {
    final uid = _currentUserId;
    if (uid == null) return const {};
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('journaling')
          .get();
      return doc.data() ?? const {};
    } catch (_) {
      return const {};
    }
  }

  Future<void> _maybeCreateTriggerEntry(String userMessage) async {
    final uid = _currentUserId;
    if (uid == null) return;
    final settings = await _journalSettings();
    if (settings['triggerBasedEntries'] != true) return;

    final lower = userMessage.toLowerCase();
    final matched = _triggerKeywords.firstWhere(
      (k) => lower.contains(k),
      orElse: () => '',
    );
    if (matched.isEmpty) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('journal_entries')
          .add({
        'title': 'Auto-captured moment',
        'content':
            'During chat, you mentioned: "${userMessage.length > 280 ? "${userMessage.substring(0, 280)}…" : userMessage}"\n\nWe saved this so you can revisit it later.',
        'timestamp': DateTime.now().toIso8601String(),
        'tags': ['chat', 'trigger', matched],
        'moods': const <String>[],
        'type': 'auto_reflection',
        'isPassive': true,
      });
    } catch (e) {
      log('Trigger entry write failed: $e');
    }
  }

  Future<void> _maybeSummarizeConversation() async {
    final uid = _currentUserId;
    if (uid == null) return;
    if (_messagesSinceLastSummary < _summaryEvery) return;

    final settings = await _journalSettings();
    if (settings['autoConversationSummary'] != true) return;

    // Build a transcript of the last ~16 messages (8 exchanges) to summarize.
    final tail = _messages.where((m) => !m.isError).toList();
    final start = tail.length > 16 ? tail.length - 16 : 0;
    final transcript = tail.sublist(start).map((m) {
      final who = m.isUser ? 'User' : 'PillowTalk';
      return '$who: ${m.text}';
    }).join('\n');

    try {
      final key = await _loadGeminiKey();
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
                {
                  'text':
                      'Summarise the following chat in 2–3 warm, second-person '
                          'sentences focusing on what the user expressed and '
                          'any feelings they shared. Return plain text only.\n\n$transcript'
                }
              ],
            },
          ],
          'generationConfig': {'temperature': 0.5},
        }),
      );
      if (res.statusCode != 200) return;
      final text = (jsonDecode(res.body)['candidates']?[0]?['content']
              ?['parts']?[0]?['text'] as String?)
          ?.trim();
      if (text == null || text.isEmpty) return;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('journal_entries')
          .add({
        'title': 'Chat summary',
        'content': text,
        'timestamp': DateTime.now().toIso8601String(),
        'tags': const ['chat', 'summary'],
        'moods': const <String>[],
        'type': 'conversation_summary',
        'isPassive': true,
      });
      _messagesSinceLastSummary = 0;
    } catch (e) {
      log('Conversation summary write failed: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
