import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:campju/features/chatbot/data/faq_repository.dart';
import 'package:campju/features/chatbot/domain/keyword_chatbot_engine.dart';
import 'package:campju/features/chatbot/domain/gemini_service.dart';
import 'package:campju/features/chatbot/presentation/chatbot_controller.dart';

class FakeGeminiService extends GeminiService {
  bool wasCalled = false;
  String? lastPrompt;
  String replyToReturn = 'Respuesta simulada de IA Gemini 🌲';
  bool shouldThrow = false;

  @override
  Future<String> getBotReply(String userMessage) async {
    wasCalled = true;
    lastPrompt = userMessage;
    if (shouldThrow) {
      throw Exception('Simulated Gemini API error');
    }
    return replyToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FaqRepository faqRepository;
  late KeywordChatbotEngine localEngine;
  late FakeGeminiService fakeAiService;

  setUpAll(() async {
    faqRepository = FaqRepository();
    await faqRepository.load();
    localEngine = KeywordChatbotEngine(repository: faqRepository);
  });

  setUp(() {
    fakeAiService = FakeGeminiService();
  });

  group('Triage & IA Architecture Tests (Plan_Detallado_IA_CampJu.md)', () {
    test('1. Pregunta Frecuente con confianza alta NO invoca a Gemini (Cero consumo API)', () async {
      final controller = ChatbotController(
        aiEngine: fakeAiService,
        localEngine: localEngine,
        currentRole: () => 'campista',
        isOnlineCheck: () async => true,
      );

      await controller.start();
      // "¿como me registro?" coincide directamente con faq de registro (confianza alta)
      await controller.sendMessage('como me registro');

      expect(controller.messages.length, greaterThanOrEqualTo(2));
      final lastMsg = controller.messages.last;
      expect(lastMsg.isBot, isTrue);
      expect(lastMsg.text.contains('Para registrarte abre la app'), isTrue);
      expect(fakeAiService.wasCalled, isFalse,
          reason: 'Gemini no debe invocarse cuando el motor local tiene alta confianza');
    });

    test('2. Saludos usan el motor local con confianza 1.0 sin consumir API', () async {
      final controller = ChatbotController(
        aiEngine: fakeAiService,
        localEngine: localEngine,
        currentRole: () => 'campista',
        isOnlineCheck: () async => true,
      );

      await controller.start();
      await controller.sendMessage('hola');

      expect(fakeAiService.wasCalled, isFalse);
      expect(controller.messages.last.text, contains('¡Hola, campista!'));
    });

    test('3. Pregunta compleja/desconocida (baja confianza) invoca a Gemini cuando hay internet', () async {
      final controller = ChatbotController(
        aiEngine: fakeAiService,
        localEngine: localEngine,
        currentRole: () => 'campista',
        isOnlineCheck: () async => true,
      );

      await controller.start();
      fakeAiService.replyToReturn = 'The transhuman person project is about nature and technology 🌲';

      // Pregunta en inglés sobre persona transhumana (no está en faq.json)
      await controller.sendMessage('Tell me about the transhuman person');

      expect(fakeAiService.wasCalled, isTrue,
          reason: 'Gemini debe invocarse cuando la pregunta no puede resolverse localmente');
      expect(controller.messages.last.text, contains('The transhuman person project'));
    });

    test('4. Modo sin conexión cuando no hay internet y la confianza local es baja', () async {
      final controller = ChatbotController(
        aiEngine: fakeAiService,
        localEngine: localEngine,
        currentRole: () => 'campista',
        isOnlineCheck: () async => false, // Modo avión / sin internet
      );

      await controller.start();
      await controller.sendMessage('Pregunta compleja sin internet');

      expect(fakeAiService.wasCalled, isFalse,
          reason: 'No debe llamar a Gemini si no hay internet');
      expect(controller.messages.last.text, contains('*(Modo sin conexión)*'));
    });

    test('5. Modo recuperación si Gemini arroja un error técnico', () async {
      final controller = ChatbotController(
        aiEngine: fakeAiService,
        localEngine: localEngine,
        currentRole: () => 'campista',
        isOnlineCheck: () async => true,
      );

      fakeAiService.shouldThrow = true;
      await controller.start();

      await controller.sendMessage('Pregunta compleja no tipificada en faqs');

      expect(fakeAiService.wasCalled, isTrue);
      expect(controller.messages.last.text, contains('Modo recuperación'));
    });
  });

  group('GeminiService - Seguridad y Privacidad (Ley 1581 de 2012)', () {
    test('sanitizeInput elimina cédulas, correos y teléfonos antes de salir a la IA', () {
      const input = 'Mi cédula es 1023456789, mi correo es juan@example.com y celular 3001234567';
      final sanitized = GeminiService.sanitizeInput(input);

      expect(sanitized, isNot(contains('1023456789')));
      expect(sanitized, isNot(contains('juan@example.com')));
      expect(sanitized, isNot(contains('3001234567')));
      expect(sanitized, contains('[DATO_PROTEGIDO]'));
      expect(sanitized, contains('[CORREO_PROTEGIDO]'));
      expect(sanitized, contains('[TEL_PROTEGIDO]'));
    });

    test('isConfigured detecta correctamente cuando la key es el placeholder por defecto', () {
      final service = GeminiService();
      dotenv.loadFromString(envString: 'GEMINI_API_KEY=pega_aqui_tu_api_key_sin_espacios');
      expect(service.isConfigured, isFalse);

      dotenv.loadFromString(envString: 'GEMINI_API_KEY=AIzaSyRealApiKey12345');
      expect(service.isConfigured, isTrue);
    });
  });
}
