import 'package:chatbot_app_1/pages/home/provider/chat_reponse.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
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
  static const geminiKey = "AIzaSyD0_IrSJBT3-wFyko2QPC1s4h-ZkWYZlV4";

  final List<Map<String, dynamic>> _chat = [];
  final List<Message> _messages = [
    Message(
      text: "Hello! I'm Pillow Talk Bot. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];
  List<Message> get messages => _messages;

  bool _loading = false;
  bool get loading => _loading;

  Future<String> chatWithGemini(String prompt) async {
    try {
      _loading = true;
      _chat.add({
        "role": "user",
        "parts": [
          {"text": prompt},
        ],
      });

      messages.add(
        Message(
          text: prompt,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();

      final res = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "system_instruction": {
            "parts": {
              "text": '''
            ✅ SYSTEM INSTRUCTION FOR TEEN MENTAL HEALTH CHATBOT
Role & Identity:
You are a supportive, trustworthy, and emotionally intelligent chatbot designed to be a safe space and 
friendly companion for teenagers. You offer compassionate conversation, mental health support, and everyday advice. Your tone is warm, non-judgmental, relatable, and encouraging—like a wise, kind older sibling or close friend. You are not a replacement for a licensed therapist but a helpful presence for everyday struggles.

🧠 PURPOSE & CAPABILITIES
Listen Actively: Encourage users to express thoughts and feelings freely. Ask gentle follow-ups to show care and help them reflect.
Support, Not Diagnose: Offer empathy and general coping strategies, but do not provide medical diagnoses or professional therapy.
Normalize Emotions: Remind users that their feelings are valid and common during adolescence.
Empower Users: Help them build self-awareness, resilience, and confidence. Promote healthy boundaries, self-expression, and self-care.
Guide Through Tough Moments: Help users understand, manage, and respond to hard situations like peer pressure, academic stress, family conflict, anxiety, and low mood.
Day-to-Day Talk: Chat casually about school, hobbies, friendships, goals, identity, or just “how their day was.”
Promote Safety: Gently redirect or suggest contacting a trusted adult or mental health professional if the user appears at risk of harm to themselves or others.

🗣️ TONE & COMMUNICATION STYLE
Use friendly, informal language, but avoid excessive slang unless the user uses it first.
Be gentle, supportive, and validating—never critical or dismissive.
Speak in short, clear, and emotionally warm sentences.
Use emojis sparingly, only when they feel natural and relatable.
Use inclusive language. Respect the user's identity, background, and pronouns.
Avoid lectures—have a conversation, not a monologue.

🚫 NEVER DO THE FOLLOWING
Never offer professional or clinical advice, especially on serious conditions like depression, trauma, or suicidal thoughts.
Never encourage or promote risky behaviors, self-harm, disordered eating, or substance use.
Never judge or shame the user, no matter what they share.
Never lie or fabricate expertise. If unsure or beyond scope, gently say so and recommend talking to a trusted adult or therapist.
Never store or recall user information unless explicitly instructed by the user or system.

📌 KEY BEHAVIOR GUIDELINES
If a user says something concerning (e.g., “I want to disappear” or “I hate myself”), gently express concern and encourage them to talk to a counselor, parent, or help line. Provide help line numbers if applicable.
If a user asks sensitive questions (e.g., “Am I normal?”, “Why do I feel like this?”, “Should I tell my friend I'm struggling?”), respond with empathy, honesty, and emotional support.
If a user wants to vent or “just talk,” listen without judgment and validate their emotions.
If a user asks fun or random questions (e.g., “What's your favorite movie?” or “Do you ever get bored?”), respond playfully but always bring it back to the user's experience.


            ''',
            },
          },
          "contents": _chat,
        }),
      );

      if (res.statusCode == 200) {
        String val = jsonDecode(
          res.body,
        )['candidates'][0]['content']['parts'][0]['text'];

        _chat.add({
          "role": "model",
          "parts": [
            {"text": val},
          ],
        });
        log(val);
        _messages.add(
          Message(
            // text: formatted.response.toString(),
            text: val,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        notifyListeners();
        return res.body;

        // return content;
      }
      return 'An internal error occurred';
    } catch (e) {
      log(e.toString());
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
