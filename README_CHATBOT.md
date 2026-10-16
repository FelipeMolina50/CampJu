# README_CHATBOT.md — Módulo Chatbot CampJu

## Descripción

Asistente virtual offline-first integrado como **5.º pestaña** en la barra de navegación inferior de CampJu. Responde preguntas frecuentes sobre la app y el programa Campamentos Juveniles del Valle de Ubaté.

---

## Estructura de archivos

```
lib/features/chatbot/
├── chatbot.dart                          # Barrel export
├── data/
│   ├── faq_repository.dart               # Carga y cachea el JSON de FAQs
│   └── models/
│       ├── faq_entry.dart                # Modelo de una entrada FAQ
│       └── chat_message.dart             # ChatMessage + ChatbotReply
├── domain/
│   ├── chatbot_engine.dart               # Interfaz abstracta ChatbotEngine
│   ├── keyword_chatbot_engine.dart       # Motor V1 basado en palabras clave
│   ├── intent_matcher.dart               # Algoritmo de scoring + sinónimos
│   └── text_normalizer.dart              # Normalización, stemming, Levenshtein
└── presentation/
    ├── chatbot_screen.dart               # Pantalla principal
    ├── chatbot_controller.dart           # ChangeNotifier (lógica de UI)
    └── widgets/
        ├── chatbot_header.dart           # AppBar con logo + indicador online/offline
        ├── message_bubble.dart           # Burbujas user/bot + botón acción
        ├── quick_reply_chips.dart        # Chips de respuesta rápida
        ├── chat_input_bar.dart           # Barra de entrada con TextField
        └── typing_indicator.dart         # Animación "escribiendo…"

assets/chatbot/
└── faq.json                             # Base de conocimiento (25 FAQs semilla)

test/chatbot/
├── text_normalizer_test.dart
└── intent_matcher_test.dart             # 16 casos de prueba del plan
```

---

## Cómo agregar o editar FAQs

Edita el archivo [`assets/chatbot/faq.json`](assets/chatbot/faq.json). Cada entrada tiene este esquema:

```json
{
  "id": "identificador_unico",
  "categoria": "general | cuenta | bosque | ascensos | cursos | eventos | notificaciones | inicio | perfil | tecnico | soporte | privacidad",
  "keywords": ["palabra1", "palabra2", "frase corta"],
  "frases": ["pregunta ejemplo completa"],
  "respuesta": "Texto de respuesta (máx. ~60 palabras).",
  "roles": ["*"],
  "estado": "disponible | planeado",
  "chips": ["Texto chip 1", "Texto chip 2"],
  "accion": "ir_inicio | ir_bosque | ir_cursos | ir_perfil | null",
  "prioridad": 5
}
```

### Reglas importantes
- **`id`** debe ser único en todo el archivo.
- **`keywords`** mínimo 3. Se normalizan automáticamente (tildes, mayúsculas, plurales).
- **`roles`**: `["*"]` para todos, o cualquier combinación de `["campista", "coordinador", "admin"]`.
- **`estado: "planeado"`**: el bot antepondrá un aviso de "en desarrollo" antes de la respuesta.
- **`prioridad`**: entero para desempatar. Mayor número = primero en caso de empate.
- **`chips`**: textos cortos que el usuario puede tocar como respuesta rápida.
- **`accion`**: muestra un botón "Ir a X" en la burbuja del bot que navega a esa pestaña.

---

## Cómo funciona el algoritmo de puntaje

1. **Tokenización**: el texto del usuario se normaliza (minúsculas, sin tildes, sin puntuación) y se descompone en tokens eliminando stopwords en español y aplicando stemming ligero de plurales.
2. Para cada FAQ elegible (por rol del usuario):
   - **+3** por cada keyword con coincidencia exacta de token.
   - **+2** por keyword sinónimo (tabla de sinónimos en `intent_matcher.dart`).
   - **+2** por keyword con distancia de Levenshtein ≤ 1 (palabras ≥ 5 letras).
   - **+5** si el mensaje coincide ≥ 80% con alguna frase ejemplo (Jaccard de tokens).
   - **+1** si la FAQ es específica del rol actual (no `*`).
   - `+prioridad × 0.1` para desempate fino.
3. **Confianza** = `score / (3 × clamp(expectedTokens, 1, 4))`.
4. Si la confianza ≥ **0.45**: se devuelve la FAQ con mayor puntaje.
5. Si la diferencia entre los dos mejores es < **1.0**: se activa **desambiguación** con chips.
6. Si confianza < 0.45: **fallback** con mensaje amable + chips populares.

### Ajustar umbrales

En [`intent_matcher.dart`](lib/features/chatbot/domain/intent_matcher.dart):

```dart
static const double confidenceThreshold = 0.45;   // Umbral mínimo de respuesta
static const double disambiguationDelta = 1.0;     // Delta para desambiguar
```

---

## Cómo agregar sinónimos

En [`intent_matcher.dart`](lib/features/chatbot/domain/intent_matcher.dart), añade entradas al mapa `_defaultSynonyms`:

```dart
'mi_termino': ['sinonimo1', 'sinonimo2', 'sinonimo3'],
```

---

## Cómo conectar IA (Fase 5)

La arquitectura está preparada. Basta con crear una nueva clase que implemente `ChatbotEngine` y pasarla al `ChatbotController`:

```dart
class RemoteAiChatbotEngine implements ChatbotEngine {
  @override
  Future<void> init() async { /* ... */ }

  @override
  Future<ChatbotReply> reply(String userText, {required String role}) async {
    // Llamar a Cloud Function HTTPS autenticada con Firebase Auth token
    // ...
  }
}
```

**Importante:** La llave del proveedor de IA debe vivir SOLO como secreto de la Cloud Function. Nunca en el código de la app.

---

## Ejecución de pruebas

```bash
flutter test test/chatbot/
```

Los 23 tests (16 casos del plan + 7 del normalizer) deben pasar en verde.

---

## Privacidad y seguridad

- El historial de chat es **local y temporal** (en memoria, se pierde al cerrar la app).
- El motor NO envía ningún dato a servicios externos en V1.
- Las respuestas del bot **nunca** piden contraseñas, documentos ni datos de salud.
- En Fase 5, toda llamada a IA pasa por Cloud Function con autenticación Firebase Auth y sanitización de datos personales antes de enviar al LLM.
