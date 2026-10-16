enum MessageAuthor { user, bot }

class ChatMessage {
  final String id;
  final MessageAuthor author;
  final String text;
  final DateTime timestamp;
  final List<String> chips;
  final String? action;

  const ChatMessage({
    required this.id,
    required this.author,
    required this.text,
    required this.timestamp,
    this.chips = const [],
    this.action,
  });

  bool get isUser => author == MessageAuthor.user;
  bool get isBot => author == MessageAuthor.bot;
}

class ChatbotReply {
  final String text;
  final List<String> chips;
  final String? action;
  final double confidence;
  final String? faqId;

  const ChatbotReply({
    required this.text,
    this.chips = const [],
    this.action,
    this.confidence = 0.0,
    this.faqId,
  });
}
