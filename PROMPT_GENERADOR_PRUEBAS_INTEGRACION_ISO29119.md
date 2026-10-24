# Generador de Documento de Pruebas de Integración (ISO/IEC/IEEE 29119)

Este archivo contiene la plantilla y el **Master Prompt** formal diseñado para solicitarle a un modelo de Inteligencia Artificial (ChatGPT, Claude, Gemini, etc.) la redacción completa, académica y técnica del **Documento de Pruebas de Integración** para una tesis o proyecto de grado en Ingeniería de Software.

El documento resultante cumple estrictamente con el estándar internacional **ISO/IEC/IEEE 29119** (específicamente las partes *29119-3: Test Documentation* y *29119-4: Test Techniques*), estructurado con fichas listas para que tú solo tengas que ejecutar el flujo, marcar si funcionó (**Aprobado / Fallido**) y adjuntar la captura o log.

---

## Cómo usar este Master Prompt

1. Copia todo el bloque encerrado en ```markdown bajo la sección **"MASTER PROMPT PARA COPIAR Y PEGAR"**.
2. Pégalo en tu IA de generación de texto preferida.
3. El prompt ya contiene todo el contexto de arquitectura, módulos y reglas de negocio de **CampJu**. Si deseas agregar o cambiar detalles de un módulo específico, edita la sección correspondiente dentro del prompt antes de enviarlo.
4. La IA generará el capítulo de pruebas de integración con su tabla de trazabilidad, entorno, casos detallados y hoja de firmas/resultados para tu tesis.

---

```markdown
# PROMPT: GENERACIÓN DE DOCUMENTO OFICIAL DE PRUEBAS DE INTEGRACIÓN (ISO/IEC/IEEE 29119-3)

## ROL Y PERFIL DEL SISTEMA
Actúa como un **Especialista Líder en Aseguramiento de Calidad de Software (QA Lead)** y **Jurado Académico Evaluador de Tesis de Ingeniería de Sistemas / Software**.
Tu misión es redactar el **Documento y Registro de Ejecución de Pruebas de Integración** para el proyecto de tesis de software denominado **CampJu**, siguiendo rigurosamente las pautas de la norma internacional **ISO/IEC/IEEE 29119**.

El documento debe tener nivel de publicación académica/profesional, sin textos genéricos o ambiguos. Cada caso de prueba debe estar completamente detallado a nivel de interfaces, datos de entrada reales y pasos exactos, diseñado de tal forma que el tester únicamente deba ejecutar los pasos, cotejar el resultado y marcar **APROBADO [ ] / FALLIDO [ ]** con su respectivo código de evidencia.

---

## CONTEXTO TÉCNICO Y ARQUITECTURA DEL SISTEMA (CAMPJU)

- **Tipo de Aplicación:** Móvil Multiplataforma (Cliente Flutter / Dart 3.5.4) conectada a servicios backend en la nube.
- **Servicios de Backend e Infraestructura:**
  - **Firebase Authentication:** Gestión de credenciales (correo/contraseña), sesiones y tokens JWT.
  - **Cloud Firestore (Base de Datos NoSQL):** Reglas de seguridad (`firestore.rules`), colecciones reactivas con `StreamBuilder` / `snapshots()`.
  - **Supabase Storage:** Almacenamiento seguro de documentos de identidad, autorizaciones de acudientes y fotos.
  - **Firebase Cloud Messaging (FCM):** Notificaciones push segmentadas por rol y evento.
  - **Motor de IA / Chatbot:** `chatbot_engine.dart` y `ChatbotController` integrados con API externa de IA generativa (Gemini) y base de conocimiento local para responder preguntas frecuentes y guiar campistas.
- **Roles y Permisos:**
  1. **Campista:** Registro, visualización de campamentos, solicitud de inscripción a eventos, interacción con chatbot, gestión de perfil y privacidad.
  2. **Coordinador:** Responsable de un "Bosque" (grupo/delegación local), revisión y observación/aprobación preliminar de inscritos de su grupo, seguimiento de acudientes.
  3. **Super Administrador:** Creación y parametrización de eventos y cupos, aprobación final de inscripciones, panel de métricas, exportación de reportes a Excel (`.xlsx`), configuración general.

---

## ALCANCE DE LAS PRUEBAS DE INTEGRACIÓN

El documento debe cubrir las interacciones entre componentes, capas y servicios externos:
1. **Capa UI (Flutter) $\leftrightarrow$ Capa de Negocio / Estado (Controllers / Streams)**
2. **Capa de Controladores $\leftrightarrow$ Servicios de Red / Firebase Auth / Cloud Firestore**
3. **Capa de Negocio $\leftrightarrow$ Supabase Storage (Subida, validación MIME/tamaño y descarga de documentos)**
4. **Capa de Notificaciones $\leftrightarrow$ Firebase Messaging (Recepción en Foreground/Background)**
5. **Capa Chatbot $\leftrightarrow$ Chatbot Engine $\leftrightarrow$ API Externa de IA Generativa**
6. **Capa Administrativa $\leftrightarrow$ Motor de Generación de Reportes (.xlsx)**

---

## ESPECIFICACIÓN DE LA ESTRUCTURA DEL DOCUMENTO REQUERIDO

Genera el documento completo en formato Markdown estructurado según las siguientes secciones oficiales:

### SECCIÓN 1: PLAN Y ALCANCE DE PRUEBAS DE INTEGRACIÓN (ISO/IEC/IEEE 29119-3)
1. **Propósito y Objetivos:** Justificación formal de las pruebas de integración en el marco del proyecto de grado.
2. **Estrategia y Enfoque de Integración:** Explicar el enfoque adoptado (combinación de *Bottom-Up* para capas de datos y *Thread-based / Functional Integration* para flujos de usuario completos).
3. **Criterios de Entrada y Criterios de Salida:**
   - Criterios para iniciar la fase de pruebas (ej. pruebas unitarias pasadas, backend desplegado, credenciales `.env` operativas).
   - Criterios de aceptación para aprobar el sistema (ej. 100% de casos críticos aprobados, 0 defectos bloqueantes).
4. **Ambiente de Pruebas (Test Environment):** Especificaciones de hardware (dispositivos físicos de prueba y emuladores), sistema operativo (Android/iOS), versión de SDK Flutter, canal de red y proyecto de Firebase/Supabase de staging/pruebas.

### SECCIÓN 2: MATRIZ DE TRAZABILIDAD (REQUISITOS FUNCIONALES VS. CASOS DE PRUEBA)
Construye una tabla completa que relacione cada Requisito Funcional (RF) con sus respectivos Casos de Prueba de Integración (ID formato `CP-INT-XX`), indicando módulos involucrados y nivel de prioridad (Alta/Media/Baja).

Módulos requeridos en la matriz:
- **MOD-01:** Autenticación, Sesión y Control de Acceso por Roles.
- **MOD-02:** Gestión de Perfiles, Bosques (Delegaciones) y Acudientes.
- **MOD-03:** Catálogo de Eventos, Solicitud y Validación de Cupos.
- **MOD-04:** Flujo de Inscripción, Subida de Documentos a Supabase Storage y Estados (Pendiente, Observada, Aprobada, Rechazada).
- **MOD-05:** Notificaciones Push por Cambio de Estado (FCM $\leftrightarrow$ UI).
- **MOD-06:** Asistente Virtual / Chatbot Inteligente (UI $\leftrightarrow$ Engine $\leftrightarrow$ Gemini API).
- **MOD-07:** Panel de Control del Administrador y Exportación Masiva a Excel (.xlsx).
- **MOD-08:** Privacidad, Términos Legales, Supresión de Datos y Bloqueo de App.

### SECCIÓN 3: ESPECIFICACIÓN DETALLADA DE CASOS DE PRUEBA DE INTEGRACIÓN
Para cada caso de prueba de integración de los 8 módulos, utiliza estrictamente la siguiente **Ficha Técnica Estándar**. Proporciona datos de prueba verosímiles y pasos inequívocos:

```text
+---------------------------------------------------------------------------------------------------+
| CASO DE PRUEBA DE INTEGRACIÓN: CP-INT-[NÚMERO]                                                    |
+---------------------------------------------------------------------------------------------------+
| TÍTULO: [Nombre descriptivo de la prueba de integración]                                          |
| MÓDULOS / CAPAS: [Ej. UI Flutter (InscripciónScreen) <-> Firestore (inscriptions) <-> Supabase]   |
| PRIORIDAD: [Crítica / Alta / Media]               | TIPO: [Positiva / Negativa / Límite]          |
+---------------------------------------------------------------------------------------------------+
| REQUISITO ASOCIADO: [RF-XX Nombre del Requisito]                                                  |
| OBJETIVO: [Qué flujo de comunicación e integridad de datos se valida]                             |
| PRECONDICIONES:                                                                                   |
|  1. [Estado inicial del sistema, autenticación requerida, existencia de registros previos]        |
|  2. [Estado de la red o servicios externos]                                                       |
+---------------------------------------------------------------------------------------------------+
| DATOS DE ENTRADA (TEST DATA):                                                                     |
|  - [Valores concretos utilizados para la prueba: correos, IDs, archivos PDF simulados, textos]    |
+---------------------------------------------------------------------------------------------------+
| PASOS DE EJECUCIÓN:                                                                               |
|  1. [Acción 1 en UI o llamada a controlador]                                                      |
|  2. [Acción 2 de verificación de tránsito de datos]                                               |
|  3. [Acción 3...]                                                                                 |
+---------------------------------------------------------------------------------------------------+
| RESULTADO ESPERADO (CRITERIO DE ACEPTACIÓN):                                                      |
|  - [Comportamiento visual en pantalla]                                                            |
|  - [Efecto en la Base de Datos / Storage / API externa: colección, campo modificado, código HTTP] |
|  - [Eventos reactivos esperados en streams / listeners]                                           |
+---------------------------------------------------------------------------------------------------+
| RESULTADO OBTENIDO:                                                                               |
|  [ ] Se comportó exactamente como se esperaba.                                                    |
|  [ ] Presentó discrepancia o falla. Detalle: ____________________________________________________  |
+---------------------------------------------------------------------------------------------------+
| ESTADO DE LA PRUEBA:                                                                              |
|  [ ] APROBADO (PASS)       [ ] FALLIDO (FAIL)       [ ] BLOQUEADO (BLOCKED)                       |
+---------------------------------------------------------------------------------------------------+
| REGISTRO DE EVIDENCIA:                                                                            |
|  Código de Captura / Log: [ CAP-INT-[NUM] ]  Ruta/Archivo: ______________________________________  |
|  Probado por: _____________________________  Fecha de Ejecución: ____/____/________               |
|  Observaciones / Incidencia detectada: _________________________________________________________   |
+---------------------------------------------------------------------------------------------------+
```

### SECCIÓN 4: RESUMEN DE EJECUCIÓN, DEFECTOS Y EVALUACIÓN FINAL
1. **Tabla Resumen de Resultados:** Total de casos planificados, ejecutados, aprobados, fallidos y bloqueados.
2. **Cálculo de Métricas Formales:**
   - **Tasa de Aprobación ($TR$):** $\frac{\text{Casos Aprobados}}{\text{Total Casos Ejecutados}} \times 100\%$
   - **Densidad de Defectos:** Defectos encontrados por módulo.
3. **Registro de Incidencias Críticas:** Formato de tabla para registrar bugs encontrados durante la integración, causa raíz (frontend, backend o configuración) y estado de solución.
4. **Dictamen de Certificación para Tesis:** Declaración formal firmable sobre si el software alcanza el nivel de madurez requerido para su sustentación y puesta en producción.

---

## REGLAS ESTRICTAS DE REDACCIÓN
1. **Cero ambigüedad:** No uses frases como "hacer clic y verificar que funcione". Usa "Pulsar el botón 'Enviar solicitud'; verificar que se invoque `InscriptionService.create()`, se cree un documento en `/inscriptions/` con estado 'pendiente' y la UI muestre el Snackbar de éxito en menos de 2 segundos".
2. **Casos felices y casos de excepción:** Incluye pruebas positivas (flujo exitoso) y pruebas negativas críticas (ej. pérdida de conexión en medio de una subida de archivo a Supabase, intento de inscripción sin cupos disponibles, envío de prompt al chatbot con API Key revocada).
3. **Consistencia técnica con Flutter y Firebase:** Usa los nombres reales de las colecciones, tipos de datos y componentes mencionados en la arquitectura.
```

---

## Casos de Prueba Clave que la IA generará para CampJu

Al ejecutar el prompt anterior, la IA generará la batería completa de casos de integración, entre los cuales destacan:

| ID Caso | Módulos Integrados | Escenario Clave de Prueba |
| :--- | :--- | :--- |
| **CP-INT-01** | UI Login $\leftrightarrow$ Firebase Auth $\leftrightarrow$ Firestore `users` | Autenticación válida, persistencia de token JWT y carga del rol correspondiente. |
| **CP-INT-02** | UI Registro $\leftrightarrow$ Firestore $\leftrightarrow$ Asignación de Bosque | Creación de cuenta de campista vinculado al ID de un bosque específico. |
| **CP-INT-03** | UI Inscripción $\leftrightarrow$ Supabase Storage $\leftrightarrow$ Firestore | Subida de autorización firmada en PDF (validación de URL en Firestore y archivo en bucket). |
| **CP-INT-04** | UI Inscripción $\leftrightarrow$ Contador de Cupos Firestore | Intento de inscripción cuando los cupos del evento están en el límite máximo ($N / N$). |
| **CP-INT-05** | Coordinador UI $\leftrightarrow$ Cambio de Estado $\leftrightarrow$ FCM Push | Aprobación/Observación de campista por coordinador y recepción de notificación push en el móvil del campista. |
| **CP-INT-06** | Chatbot UI $\leftrightarrow$ `ChatbotController` $\leftrightarrow$ Gemini API | Envío de duda sobre fechas de campamento, obtención de respuesta y renderizado en burbuja sin bloquear el hilo principal. |
| **CP-INT-07** | Admin Panel $\leftrightarrow$ Firestore Query $\leftrightarrow$ Excel Engine | Consulta de inscritos aprobados por municipio y generación del archivo `.xlsx` descargable. |
| **CP-INT-08** | UI Privacidad $\leftrightarrow$ Firestore Security Rules | Intento de un campista de leer o modificar documentos de otro usuario o bosque no autorizado. |

---

## Plantilla Lista para Llenar en tu Sustentación

Una vez que la IA te entregue el texto estructurado, puedes imprimirlo o pasarlo a tu informe de Word/LaTeX de la siguiente manera:

- **Si el caso funcionó:** Marcas `[X] APROBADO`, colocas la fecha, y anotas el nombre de la captura (ej: `Anexo_Pruebas/CAP-INT-03.png`).
- **Si el caso falló:** Marcas `[X] FALLIDO`, escribes brevemente el error (ej: *"El archivo subió a Supabase pero Firestore no guardó la URL"*), corriges el código y agregas una re-ejecución aprobada.
