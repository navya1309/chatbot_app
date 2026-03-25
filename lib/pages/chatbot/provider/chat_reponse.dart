import 'dart:convert';

class ChatResponse {
  final String? response;

  ChatResponse({this.response});

  Map<String, dynamic> toMap() {
    return {
      'response': response,
    };
  }

  factory ChatResponse.fromMap(Map<String, dynamic> map) {
    return ChatResponse(
      response: map['response'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatResponse.fromJson(String source) =>
      ChatResponse.fromMap(json.decode(source));
}
