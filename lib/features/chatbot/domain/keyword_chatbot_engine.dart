import '../data/faq_repository.dart';
import '../data/models/chat_message.dart';
import 'chatbot_engine.dart';
import 'intent_matcher.dart';
import 'text_normalizer.dart';

class KeywordChatbotEngine implements ChatbotEngine {
  final FaqRepository repository;
  final IntentMatcher matcher;

  static const List<String> defaultInitialChips = [
    'Cómo me registro',
    'Qué es un bosque',
    'Ascensos',
    'Cursos',
    'Notificaciones',
    'Ayuda',
  ];

  KeywordChatbotEngine({
    required this.repository,
    IntentMatcher? matcher,
  }) : matcher = matcher ?? IntentMatcher();

  @override
  Future<void> init() async {
    if (!repository.isLoaded) {
      await repository.load();
    }
  }

  @override
  Future<ChatbotReply> reply(String userText, {required String role}) async {
    final clean = userText.trim();
    if (clean.length < 2) {
      return const ChatbotReply(
        text: '¿Puedes darme un poco más de detalle sobre tu pregunta?',
        chips: defaultInitialChips,
        confidence: 1.0,
      );
    }

    final normalized = TextNormalizer.normalize(clean);
    final tokens = TextNormalizer.tokens(clean);

    // Pre-rule 1: Greetings
    if (_isGreeting(clean, normalized, tokens)) {
      final roleLabel = (role.toLowerCase() == 'coordinador')
          ? 'coordinador'
          : (role.toLowerCase() == 'admin' || role.toLowerCase() == 'superadmin')
              ? 'administrador'
              : 'campista';
      return ChatbotReply(
        text: '¡Hola, $roleLabel! 👋 Soy el asistente de Campamentos Juveniles. Pregúntame sobre inscripciones, tu bosque, ascensos, cursos o cómo usar CampJu.',
        chips: defaultInitialChips,
        confidence: 1.0,
      );
    }

    // Pre-rule 2: Thanks
    if (_isThanks(clean, normalized, tokens)) {
      return const ChatbotReply(
        text: '¡Con gusto! Aquí estaré si necesitas algo más 🌲',
        chips: ['Qué es un bosque', 'Cursos', 'Ayuda'],
        confidence: 1.0,
      );
    }

    // Pre-rule 3: Farewells
    if (_isFarewell(clean, normalized, tokens)) {
      return const ChatbotReply(
        text: '¡Hasta pronto! Buen campamento 🏕️',
        chips: defaultInitialChips,
        confidence: 1.0,
      );
    }

    // Knowledge matching
    await init();
    final faqs = repository.faqs;
    final decision = matcher.match(clean, faqs, role: role);

    if (decision.isDisambiguation) {
      final disambigChips = decision.disambiguationOptions.map((f) {
        if (f.frases.isNotEmpty) {
          final fr = f.frases.first;
          return fr.substring(0, 1).toUpperCase() + fr.substring(1);
        }
        return f.id.replaceAll('_', ' ');
      }).toList();

      return ChatbotReply(
        text: '¿Te refieres a alguno de estos temas?',
        chips: disambigChips,
        confidence: decision.confidence,
      );
    }

    if (decision.isFallback || decision.selectedFaq == null) {
      return const ChatbotReply(
        text: 'No estoy seguro de haber entendido 🤔. Prueba con otras palabras o elige un tema frecuente:',
        chips: defaultInitialChips,
        confidence: 0.0,
      );
    }

    final faq = decision.selectedFaq!;
    String responseText = faq.respuesta;

    if (faq.estado == 'planeado' && !responseText.toLowerCase().contains('desarrollo')) {
      responseText = 'Esta función está en desarrollo y estará disponible pronto.\n\n$responseText';
    }

    return ChatbotReply(
      text: responseText,
      chips: faq.chips.isNotEmpty ? faq.chips : defaultInitialChips.sublist(0, 3),
      action: faq.accion,
      confidence: decision.confidence,
      faqId: faq.id,
    );
  }

  bool _isGreeting(String clean, String normalized, List<String> tokens) {
    const greetingWords = {
      'hola', 'buenas', 'buenos dias', 'buenas tardes', 'buenas noches',
      'hey', 'saludos', 'que tal', 'hola bot', 'buen dia'
    };
    if (greetingWords.contains(clean.toLowerCase()) || greetingWords.contains(normalized)) {
      return true;
    }
    if (tokens.isEmpty && clean.toLowerCase().contains('hola')) {
      return true;
    }
    return false;
  }

  bool _isThanks(String clean, String normalized, List<String> tokens) {
    const thanksWords = {
      'gracias', 'muchas gracias', 'mil gracias', 'te agradezco',
      'vale gracias', 'muchas gracias bot'
    };
    if (thanksWords.contains(clean.toLowerCase()) || thanksWords.contains(normalized)) {
      return true;
    }
    return tokens.contains('gracia') || normalized.contains('gracias');
  }

  bool _isFarewell(String clean, String normalized, List<String> tokens) {
    const farewellWords = {
      'chao', 'adios', 'hasta luego', 'nos vemos', 'hasta pronto',
      'bye', 'chao chao'
    };
    if (farewellWords.contains(clean.toLowerCase()) || farewellWords.contains(normalized)) {
      return true;
    }
    return false;
  }
}
