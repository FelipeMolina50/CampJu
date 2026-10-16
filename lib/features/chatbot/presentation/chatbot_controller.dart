import 'package:flutter/material.dart';
import '../data/models/chat_message.dart';
import '../domain/chatbot_engine.dart';

class ChatbotController extends ChangeNotifier {
  final ChatbotEngine engine;
  final String Function() currentRole;
  final List<ChatMessage> messages = [];
  bool isTyping = false;
  bool _isInitialized = false;

  ChatbotController({
    required this.engine,
    required this.currentRole,
  });

  bool get isInitialized => _isInitialized;

  Future<void> start() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await engine.init();
    final greeting = await engine.reply('hola', role: currentRole());
    _addBot(greeting);
  }

  Future<void> send(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _addUser(clean);
    isTyping = true;
    notifyListeners();

    // Natural response delay (450ms)
    await Future.delayed(const Duration(milliseconds: 450));

    final r = await engine.reply(clean, role: currentRole());
    isTyping = false;
    _addBot(r);
  }

  void _addUser(String text) {
    messages.add(ChatMessage(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      author: MessageAuthor.user,
      text: text,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void _addBot(ChatbotReply r) {
    messages.add(ChatMessage(
      id: 'bot_${DateTime.now().microsecondsSinceEpoch}',
      author: MessageAuthor.bot,
      text: r.text,
      timestamp: DateTime.now(),
      chips: r.chips,
      action: r.action,
    ));
    notifyListeners();
  }

  void clear() {
    messages.clear();
    _isInitialized = false;
    notifyListeners();
    start();
  }
}
