import 'package:flutter_test/flutter_test.dart';
import 'package:campju/features/chatbot/domain/text_normalizer.dart';

void main() {
  group('TextNormalizer', () {
    test('normalizes diacritics and casing', () {
      expect(TextNormalizer.normalize('¡Hola, CampJu! ¿Cómo estás?'), equals('hola campju como estas'));
      expect(TextNormalizer.normalize('CONTRASEÑA'), equals('contrasena'));
      expect(TextNormalizer.normalize('Árbol Cañón Güepsa'), equals('arbol canon guepsa'));
    });

    test('removes punctuation and extra spaces', () {
      expect(TextNormalizer.normalize('   ¿Qué    es... un   bosque???   '), equals('que es un bosque'));
    });

    test('filters stopwords and stems plurals', () {
      final tokens = TextNormalizer.tokens('los cursos y las lecciones del campamento');
      expect(tokens, contains('curso'));
      expect(tokens, contains('leccion'));
      expect(tokens, contains('campamento'));
      expect(tokens.contains('los'), isFalse);
      expect(tokens.contains('las'), isFalse);
      expect(tokens.contains('del'), isFalse);
    });

    test('stems plurals with s and es correctly', () {
      expect(TextNormalizer.stem('ascensos'), equals('ascenso'));
      expect(TextNormalizer.stem('bosques'), equals('bosque'));
      expect(TextNormalizer.stem('solicitudes'), equals('solicitud'));
    });

    test('calculates Levenshtein distance', () {
      expect(TextNormalizer.levenshtein('registro', 'rejistro'), equals(1));
      expect(TextNormalizer.levenshtein('clave', 'clave'), equals(0));
      expect(TextNormalizer.levenshtein('bosque', 'boskue'), equals(1));
    });

    test('calculates Jaccard similarity', () {
      final a = ['que', 'es', 'bosque'];
      final b = ['que', 'es', 'bosque'];
      expect(TextNormalizer.jaccard(a, b), equals(1.0));

      final c = ['como', 'me', 'registro'];
      expect(TextNormalizer.jaccard(a, c), equals(0.0));
    });
  });
}
