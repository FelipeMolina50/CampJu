import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  bool get isConfigured {
    if (!dotenv.isInitialized) return false;
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    return apiKey != null &&
        apiKey.isNotEmpty &&
        apiKey != 'pega_aqui_tu_api_key_sin_espacios';
  }

  void initialize() {
    if (_isInitialized) return;

    if (!dotenv.isInitialized) {
      throw Exception('dotenv no ha sido inicializado. Llama a dotenv.load() en main().');
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'pega_aqui_tu_api_key_sin_espacios') {
      throw Exception('GEMINI_API_KEY no configurada en el archivo .env');
    }

    const systemInstruction = '''
Eres el asistente virtual oficial de CampJu, una aplicación móvil para gestionar campamentos juveniles en el Valle de Ubaté.
Conoces y estás integrado con el proyecto de la persona transhumana de la Universidad de Cundinamarca.

REGLAS DE SEGURIDAD Y PRIVACIDAD (LEY 1581):
1. PROHIBIDO solicitar, procesar o almacenar datos personales de los usuarios (nombres, documentos de identidad, EPS, teléfonos, direcciones, fotos). Muchos son menores de edad.
2. Si un usuario te da un dato personal por error, ignóralo completamente y responde a la pregunta general sin hacer mención al dato sensible.

LÍMITES DE CONVERSACIÓN ESTRICTOS:
3. TU ÚNICO TEMA DE CONVERSACIÓN es el programa Campamentos Juveniles, la logística de la app CampJu, la naturaleza, el liderazgo juvenil y la persona transhumana.
4. SI EL USUARIO PREGUNTA ALGO FUERA DE ESTOS TEMAS, DEBES NEGARTE A RESPONDER. Dile textualmente: "Lo siento, como asistente de CampJu solo puedo ayudarte con información sobre el programa de Campamentos Juveniles y el uso de la aplicación."

IDIOMA Y TONO:
5. Responde obligatoriamente en el mismo idioma en el que te hable el usuario (español o inglés).
6. Sé amable, directo y utiliza emojis relacionados con la naturaleza.
''';

    _model = GenerativeModel(
      model: 'gemini-3.8-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstruction),
    );

    _isInitialized = true;
  }

  /// Sanitiza cualquier dato sensible que el usuario pueda haber ingresado
  /// por error antes de enviarlo a la API externa (Ley 1581 de 2012).
  static String sanitizeInput(String input) {
    // 1. Censura correos electrónicos
    var sanitized = input.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '[CORREO_PROTEGIDO]',
    );
    // 2. Censura números telefónicos (móviles colombianos que inician en 3xx o con prefijo +57)
    sanitized = sanitized.replaceAll(
      RegExp(r'(\+?57[-.\s]?)?(\(?3\d{2}\)?[-.\s]?\d{3}[-.\s]?\d{4})'),
      '[TEL_PROTEGIDO]',
    );
    // 3. Censura números de identificación o cédulas restantes (6 a 12 dígitos)
    sanitized = sanitized.replaceAll(RegExp(r'\b\d{6,12}\b'), '[DATO_PROTEGIDO]');
    return sanitized;
  }

  Future<String> getBotReply(String userMessage) async {
    try {
      if (!_isInitialized) initialize();

      final sanitized = sanitizeInput(userMessage);
      final content = [Content.text(sanitized)];
      final response = await _model.generateContent(content);

      return response.text ??
          'Lo siento, no pude generar una respuesta en este momento. 🌲';
    } catch (e) {
      debugPrint('Error en GeminiService: $e');
      rethrow;
    }
  }
}
