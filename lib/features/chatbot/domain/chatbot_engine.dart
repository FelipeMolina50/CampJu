import '../data/models/chat_message.dart';

abstract class ChatbotEngine {
  Future<void> init();
  Future<ChatbotReply> reply(String userText, {required String role});
}
