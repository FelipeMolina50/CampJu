import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../data/models/chat_message.dart';
import '../domain/gemini_service.dart';
import '../domain/keyword_chatbot_engine.dart';

class ChatbotController extends ChangeNotifier {
  final GeminiService aiEngine;
  final KeywordChatbotEngine localEngine;
  final String Function() currentRole;
  final Future<bool> Function() _isOnlineCheck;

  final List<ChatMessage> messages = [];
  bool isTyping = false;
  bool _isInitialized = false;

  ChatbotController({
    required this.aiEngine,
    required this.localEngine,
    required this.currentRole,
    Future<bool> Function()? isOnlineCheck,
  }) : _isOnlineCheck = isOnlineCheck ?? _defaultConnectivityCheck;

  static Future<bool> _defaultConnectivityCheck() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  bool get isInitialized => _isInitialized;

  Future<void> start() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await localEngine.init();
    final greeting = await localEngine.reply('hola', role: currentRole());
    _addBotReply(greeting);
  }

  Future<void> send(String text) async {
    await sendMessage(text);
  }

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _addUserMessage(clean);
    isTyping = true;
    notifyListeners();

    try {
      // 1. SIEMPRE evaluamos primero con el motor local (Filtro Primario)
      final localReply = await localEngine.reply(clean, role: currentRole());

      // 2. Evaluamos la confianza (>= 0.8 es alta certeza)
      // Ideal para preguntas frecuentes, saludos o clics en botones/chips rápidos.
      if (localReply.confidence >= 0.8) {
        // Pausa breve para una sensación de conversación natural
        await Future.delayed(const Duration(milliseconds: 300));
        // El motor local resolvió la duda. Cero consumo de API.
        _addBotReply(localReply);
      } else {
        // 3. El motor local falló o tiene baja certeza (pregunta compleja o en otro idioma).
        // Verificamos conexión para consultar a Gemini (IA).
        final bool isOnline = await _isOnlineCheck();

        if (isOnline) {
          // 3a. Hay internet: Pasamos la pregunta a la IA.
          try {
            final aiResponse = await aiEngine.getBotReply(clean);
            _addBotMessage(
              aiResponse,
              chips: localReply.chips.isNotEmpty
                  ? localReply.chips
                  : KeywordChatbotEngine.defaultInitialChips.sublist(0, 3),
            );
          } catch (e) {
            // Si Gemini falla (ej. error de cuota, API key inválida o red), salvavidas local
            _addBotMessage(
              '${localReply.text}\n\n*(Modo recuperación: no fue posible conectar con el asistente avanzado)*',
              chips: localReply.chips,
              action: localReply.action,
            );
          }
        } else {
          // 3b. No hay internet: Entregamos el fallback local del faq.json.
          _addBotMessage(
            '${localReply.text}\n\n*(Modo sin conexión)*',
            chips: localReply.chips,
            action: localReply.action,
          );
        }
      }
    } catch (e) {
      _addBotMessage(
        'Tuvimos un error procesando tu solicitud.\n\n*(Modo recuperación)*',
      );
    } finally {
      isTyping = false;
      notifyListeners();
    }
  }

  void _addUserMessage(String text) {
    messages.add(ChatMessage(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      author: MessageAuthor.user,
      text: text,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void _addBotMessage(
    String text, {
    List<String> chips = const [],
    String? action,
  }) {
    messages.add(ChatMessage(
      id: 'bot_${DateTime.now().microsecondsSinceEpoch}',
      author: MessageAuthor.bot,
      text: text,
      timestamp: DateTime.now(),
      chips: chips,
      action: action,
    ));
    notifyListeners();
  }

  void _addBotReply(ChatbotReply r) {
    _addBotMessage(
      r.text,
      chips: r.chips,
      action: r.action,
    );
  }

  void clear() {
    messages.clear();
    _isInitialized = false;
    notifyListeners();
    start();
  }
}
