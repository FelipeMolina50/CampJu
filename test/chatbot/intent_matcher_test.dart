import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:campju/features/chatbot/data/faq_repository.dart';
import 'package:campju/features/chatbot/domain/intent_matcher.dart';
import 'package:campju/features/chatbot/domain/keyword_chatbot_engine.dart';

void main() {
  late FaqRepository repository;
  late IntentMatcher matcher;
  late KeywordChatbotEngine engine;

  setUpAll(() {
    // Read raw json file from filesystem directly for unit test environment
    final file = File('assets/chatbot/faq.json');
    final jsonContent = file.readAsStringSync();

    repository = FaqRepository();
    repository.parseFaqs(jsonContent);

    matcher = IntentMatcher();
    engine = KeywordChatbotEngine(repository: repository, matcher: matcher);
  });

  group('IntentMatcher & KeywordChatbotEngine - 16 Test Cases', () {
    test('1. "como me registro?" (campista) -> registro', () async {
      final reply = await engine.reply('como me registro?', role: 'campista');
      expect(reply.faqId, equals('registro'));
    });

    test('2. "COMO ME REGISTRO" (mayúsculas, campista) -> registro', () async {
      final reply = await engine.reply('COMO ME REGISTRO', role: 'campista');
      expect(reply.faqId, equals('registro'));
    });

    test('3. "como me rejistro" (error de tipeo, campista) -> registro', () async {
      final reply = await engine.reply('como me rejistro', role: 'campista');
      expect(reply.faqId, equals('registro'));
    });

    test('4. "olvide mi clave" (sinónimo, campista) -> recuperar_contrasena', () async {
      final reply = await engine.reply('olvide mi clave', role: 'campista');
      expect(reply.faqId, equals('recuperar_contrasena'));
    });

    test('5. "que es un bosque" (campista) -> que_es_bosque', () async {
      final reply = await engine.reply('que es un bosque', role: 'campista');
      expect(reply.faqId, equals('que_es_bosque'));
    });

    test('6. "quiero unirme a mi delegacion" (campista) -> unirse_bosque', () async {
      final reply = await engine.reply('quiero unirme a mi delegacion', role: 'campista');
      expect(reply.faqId, equals('unirse_bosque'));
    });

    test('7. "como subo de nivel" (campista) -> ascensos o como_ascender', () async {
      final reply = await engine.reply('como subo de nivel', role: 'campista');
      expect(reply.faqId, anyOf(equals('ascensos'), equals('como_ascender')));
    });

    test('8. "como asciendo a un campista" (coordinador) -> gestionar_ascensos', () async {
      final reply = await engine.reply('como asciendo a un campista', role: 'coordinador');
      expect(reply.faqId, equals('gestionar_ascensos'));
    });

    test('9. "como asciendo a un campista" (campista) -> no debe devolver gestionar_ascensos', () async {
      final reply = await engine.reply('como asciendo a un campista', role: 'campista');
      expect(reply.faqId, isNot(equals('gestionar_ascensos')));
    });

    test('10. "no me llegan las alertas" (campista) -> notificaciones', () async {
      final reply = await engine.reply('no me llegan las alertas', role: 'campista');
      expect(reply.faqId, equals('notificaciones'));
    });

    test('11. "puedo subir fotos?" (campista) -> fotos_feed', () async {
      final reply = await engine.reply('puedo subir fotos?', role: 'campista');
      expect(reply.faqId, equals('fotos_feed'));
    });

    test('12. "funciona sin senal" (campista) -> offline', () async {
      final reply = await engine.reply('funciona sin senal', role: 'campista');
      expect(reply.faqId, equals('offline'));
    });

    test('13. "hola" -> saludo + chips', () async {
      final reply = await engine.reply('hola', role: 'campista');
      expect(reply.text, contains('¡Hola'));
      expect(reply.chips, isNotEmpty);
    });

    test('14. "asdfgh" -> fallback', () async {
      final reply = await engine.reply('asdfgh', role: 'campista');
      expect(reply.text, contains('No estoy seguro de haber entendido'));
      expect(reply.chips, isNotEmpty);
    });

    test('15. "me quiero inscribir al encuentro" (campista) -> inscripcion_eventos', () async {
      final reply = await engine.reply('me quiero inscribir al encuentro', role: 'campista');
      expect(reply.faqId, equals('inscripcion_eventos'));
    });

    test('16. "gracias" -> cierre amable', () async {
      final reply = await engine.reply('gracias', role: 'campista');
      expect(reply.text, contains('Con gusto'));
    });
  });

  group('FaqRepository integrity', () {
    test('all FAQs have unique IDs, at least 3 keywords and non-empty answer', () {
      final faqs = repository.faqs;
      expect(faqs, isNotEmpty);

      final ids = <String>{};
      for (final f in faqs) {
        expect(ids.contains(f.id), isFalse, reason: 'Duplicate FAQ id: ${f.id}');
        ids.add(f.id);
        expect(f.keywords.length, greaterThanOrEqualTo(3), reason: 'FAQ ${f.id} should have >= 3 keywords');
        expect(f.respuesta.trim().isNotEmpty, isTrue, reason: 'FAQ ${f.id} has empty response');
      }
    });
  });
}
