import 'package:chatbot_app_1/pages/chatbot/provider/chat_reponse.dart';
import 'package:flutter/material.dart';

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
  static const String _geminiKeyPath = 'config/gemini_api_key';
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  String? _geminiKey;

  final List<Map<String, dynamic>> _chat = [];
  final List<Message> _messages = [
    Message(
      text:
          "Hey! I'm PillowTalk 💜 Your safe space to talk about *anything* — stress, friendships, life stuff. What's on your mind?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];
  List<Message> get messages => _messages;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> make() async {
    await _loadGeminiKey();
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
    log("geminikey $_geminiKey");
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
    _messages.add(
      Message(
        text: prompt,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

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
        log(val);
        _messages.add(
          Message(
            text: val,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        notifyListeners();
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
}
