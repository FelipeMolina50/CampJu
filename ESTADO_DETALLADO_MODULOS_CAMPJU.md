# Auditoría Integral y Estado del Sistema: CampJu Móvil

Este documento presenta una radiografía exhaustiva y técnica de la aplicación **CampJu**, analizando cada módulo de la arquitectura Flutter, servicios de Firebase y Supabase Storage. Se detalla literalmente lo que está programado, qué funciones operan correctamente, qué partes tienen limitaciones o código simulado (mock) y qué falta para completar el sistema al 100%.

---

## 1. Resumen Ejecutivo del Estado Global

| Módulo / Dominio | Estado General | Madurez Estimada | Observación Principal |
| :--- | :---: | :---: | :--- |
| **Autenticación y Registro** |  Operativo | 90% | Flujo completo con verificación de correo y perfil en 3 pasos. |
| **Inicio y Feed Social** |  Operativo | 95% | Publicaciones multimedia, visor de video/fotos, likes y comentarios en tiempo real. |
| **Bosques (Comunidades)** |  Operativo | 85% | Chat con multimedia, perfiles, solicitudes de ingreso y cambio de fotos. |
| **Eventos e Inscripciones (Bloque A)** |  Operativo | 85% | Detalle, subida de documentos a Supabase privado y revisión por coordinador. |
| **Panel de Administración** | ⚠️ Parcial | 70% | Métricas, gestión de bosques y usuarios funcionan; reporte de inscritos usa CSV en vez de Excel nativo. |
| **Notificaciones** |  Operativo | 80% | Campana y base de datos en tiempo real funcional; FCM Push depende de tokens reales. |
| **Cursos y Formación** | ❌ Incompleto (Mock) | 20% | La pantalla usa datos estáticos en memoria; el detalle es un placeholder vacío. |
| **Privacidad y Seguridad (Bloque C)** | ❌ Incompleto | 15% | Los 6 botones de la pantalla están desconectados (`() {}`). |
| **Configuración y Mantenimiento** | ⚠️ Parcial | 60% | Reset de fábrica completo y funcional; cambio de contraseña y correo sin implementar. |

---

## 2. Radiografía Detallada Módulo por Módulo

---

### Módulo 1: Autenticación, Registro y Perfil Inicial

**Archivos involucrados:**
- `lib/screens/auth/auth_wrapper.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/register_screen.dart`
- `lib/screens/auth/verificar_correo_screen.dart`
- `lib/screens/auth/complete_profile_screen.dart`
- `lib/screens/auth/forgot_password_screen.dart`
- `lib/services/auth_service.dart`
- `lib/services/auth_provider.dart`

####  Lo que SÍ funciona:
1. **Inicio de sesión:** Inicio con correo y contraseña, y autenticación con Google (`GoogleSignIn`).
2. **Registro de usuarios:** Creación de cuenta en Firebase Auth con validaciones de contraseña segura.
3. **Verificación de correo electrónico:** `VerificarCorreoScreen` bloquea el acceso a usuarios no verificados, con temporizador de recarga automática (`reload()`) y botón para reenviar el enlace.
4. **Recuperación de contraseña:** Envío de correo de restablecimiento vía Firebase Auth.
5. **Completar Perfil en 3 Pasos (`CompleteProfileScreen`):**
   - Paso 1: Información personal (Nombre, apellidos, tipo y número de documento, fecha de nacimiento, sexo, teléfono, municipio).
   - Paso 2: Información demográfica y sensible (género, orientación sexual, discapacidad, etnia/grupo poblacional, condición de víctima del conflicto, zona urbana/rural, ocupación, nivel educativo).
   - Paso 3: Contactos de emergencia y salud (nombre y teléfono de acudiente obligatorio si es menor de 18 años, EPS).
6. **Guardado en Firestore:** Se genera el documento en `users/{uid}` con `perfilCompleto: true`.
7. **Control de Acceso (`AuthWrapper`):** Redirige fluidamente entre Login -> Verificar Correo -> Completar Perfil -> Pantalla Principal según el estado real del usuario.

#### ⚠️ Limitaciones / Cosas a tener en cuenta:
- Si el usuario se registra con Google por primera vez, debe completar el perfil obligatorio igual que los de correo y contraseña.
- No hay re-autenticación obligatoria para cambios críticos desde este módulo.

#### ❌ Lo que FALTA por completar:
- Registro explícito de la versión de Términos y Condiciones aceptada durante el registro (`consentimiento: { terminosVersion, politicaVersion, aceptadoAt }`) según el Bloque C1.
- Flujo de re-consentimiento si se actualizan los términos legales.

---

### Módulo 2: Pantalla Principal (Dashboard) y Feed de Publicaciones

**Archivos involucrados:**
- `lib/screens/home/dashboard_screen.dart`
- `lib/screens/home/home_screen.dart`
- `lib/screens/bosque/widgets/bosque_feed_widget.dart`
- `lib/screens/bosque/widgets/post_card.dart`
- `lib/screens/bosque/widgets/post_creator.dart`
- `lib/screens/bosque/widgets/comentarios_modal.dart`
- `lib/services/publicacion_service.dart`

####  Lo que SÍ funciona:
1. **Header colapsable inteligente:** Al desplazarse hacia abajo en el feed, el banner superior se oculta con animación suave (`AnimatedCrossFade`) y sus accesos directos (Eventos, Notificaciones con badge numérico, Agenda y Logout) se integran compactos en el `AppBar` para no desperdiciar pantalla ni desbordar píxeles.
2. **Feed Social en Tiempo Real:** Carga las publicaciones ordenadas por fecha desde Firestore (`publicaciones`).
3. **Soporte Multimedia:** Visualización de imágenes (con carrusel interactivo si son varias) y reproducción de video con controles integrados (`VideoPlayer`).
4. **Interacciones Sociales:**
   - **Likes:** Contador y alternancia de "Me gusta" por usuario en tiempo real con subcolección `publicaciones/{id}/likes/{uid}`.
   - **Comentarios:** Modal deslizable para escribir y leer comentarios en tiempo real (`publicaciones/{id}/comentarios`).
5. **Creación de Publicaciones (`PostCreator`):**
   - Restringido a Coordinadores y Administradores.
   - Permite seleccionar fotos o videos desde la galería.
   - Sube los archivos multimedia a Supabase Storage en el bucket público `campju-media`.
   - Permite elegir si la publicación pertenece a un bosque específico o a la comunidad general.
6. **Eliminación de Publicaciones:** Coordinadores y administradores pueden borrar publicaciones no deseadas.

#### ⚠️ Limitaciones / Cosas a tener en cuenta:
- No existe edición de texto de una publicación después de creada (solo borrado).
- No hay compresión local de video antes de subirlo; videos pesados pueden tardar en redes lentas.

#### ❌ Lo que FALTA por completar:
- Paginación infinita en el feed (actualmente carga el stream directo de las publicaciones).
- Reporte/denuncia de publicaciones inapropiadas por parte de los campistas.

---

### Módulo 3: Bosques (Comunidades Locales y Chat)

**Archivos involucrados:**
- `lib/screens/bosque/bosque_screen.dart`
- `lib/screens/bosque/widgets/camping_chat_background.dart`
- `lib/services/bosque_service.dart`
- `lib/services/chat_service.dart`

####  Lo que SÍ funciona:
1. **Flujo de Usuario sin Bosque:**
   - Visualiza la lista de bosques existentes con información de zona, líder y número de miembros.
   - Permite enviar solicitud de ingreso a un bosque (`solicitudes`).
   - Muestra pantalla de espera interactiva si tiene una solicitud en estado `pendiente`.
2. **Chat Grupal del Bosque:**
   - Canal de mensajería instantánea en tiempo real (`bosques/{id}/mensajes`).
   - Fondo temático de campamento (`CampingChatBackground`).
   - Envío de mensajes de texto con identificación de remitente y hora.
   - Envío de imágenes y archivos adjuntos (documentos/PDFs), alojados en el bucket `chat-archivos` de Supabase Storage.
   - Visor de imágenes táctil integrado a pantalla completa con soporte de Zoom (pinch-to-zoom).
   - Paginación dinámica en el chat (carga 30 mensajes adicionales al hacer scroll hacia arriba).
3. **Perfil y Gestión del Bosque (Bottom Sheet modal):**
   - Información del bosque y lista completa de integrantes con avatar y rol.
   - Opción para que un campista abandone voluntariamente el bosque.
   - Actualización de la foto de perfil del bosque (solo coordinador), subiéndola a `bosques-fotos` de Supabase.
4. **Pestaña "Ingreso" (Coordinador):**
   - Lista en tiempo real las solicitudes de campistas para ingresar al bosque.
   - Botón para aceptar (agrega a `miembros`, actualiza el `bosqueId` del usuario y sube el contador) o rechazar la solicitud.
5. **Pestaña "Inscripciones" (Coordinador):**
   - Conectada con la nueva pantalla `RevisionInscripcionScreen` para auditar los documentos de los campistas de su bosque inscritos a campamentos.
6. **Creación de Bosque:**
   - Diálogo exclusivo de administradores con búsqueda dinámica de candidatos a coordinador.
   - Validación para que un coordinador no pueda tener más de un bosque.
   - **Blindaje de Rol:** Ya no degrada la cuenta del Super Admin a rol coordinador.

#### ⚠️ Limitaciones / Cosas a tener en cuenta:
- Existen archivos obsoletos o sin uso en la carpeta (`lib/screens/bosque/bosque_chat_screen.dart` está en blanco; `bosque_detalle_screen.dart` y `bosque_perfil_screen.dart` fueron reemplazados por los componentes integrados dentro de `bosque_screen.dart`).

#### ❌ Lo que FALTA por completar:
- Función para que el coordinador pueda expulsar a un miembro directamente desde la lista de integrantes.
- Asignación de subjefes o roles secundarios dentro del bosque.

---

### Módulo 4: Eventos, Inscripciones y Agenda (Bloque A)

**Archivos involucrados:**
- `lib/screens/eventos/eventos_screen.dart`
- `lib/screens/eventos/evento_detalle_screen.dart`
- `lib/screens/eventos/inscripcion_documentos_screen.dart`
- `lib/screens/eventos/revision_inscripcion_screen.dart`
- `lib/screens/eventos/agenda_screen.dart`
- `lib/screens/eventos/calendario_screen.dart`
- `lib/services/evento_service.dart`
- `lib/models/evento_model.dart`
- `lib/models/inscripcion_model.dart`

####  Lo que SÍ funciona:
1. **Listado de Eventos (`EventosScreen`):**
   - Muestra campamentos y actividades departamentales o de bosque.
   - Chip dinámico por tarjeta que indica el estado exacto de la inscripción del usuario (`Sin inscribirme`, `Borrador`, `Pendiente`, `Observada`, `Aprobada`, `Rechazada`).
2. **Detalle de Evento (`EventoDetalleScreen`):**
   - Muestra lugar limpio (sin guiones sueltos), fechas, cupo disponible y fecha límite.
   - Botón contextual según el estado del campista (`Inscribirme`, `Corregir documentos`, `En revisión`, `Confirmado`).
3. **Subida de Documentos (`InscripcionDocumentosScreen`):**
   - Selector de archivos para cada documento requerido por el campamento.
   - Valida formatos permitidos (PDF, JPG, PNG) y tamaño máximo de 5 MB.
   - Casilla de verificación obligatoria de tratamiento de datos personales que registra la fecha en `autorizacionDatosAt`.
   - Almacenamiento seguro en el bucket **privado** `inscripciones-documentos` de Supabase Storage.
4. **Revisión de Coordinador (`RevisionInscripcionScreen`):**
   - Permite al coordinador inspeccionar los datos del campista.
   - Acceso a documentos mediante **URLs firmadas temporales de 5 minutos** (`obtenerUrlFirmada`) para que ningún archivo privado quede expuesto públicamente en internet.
   - Marcación de documentos como correctos o rechazados con nota explicativa.
   - Aprobación transaccional (incrementa `aprobadosCount`, valida cupos) o devolución con observaciones (`observada`).
5. **Agenda Confirmada (`AgendaScreen`):**
   - Muestra únicamente los eventos en los que el campista tiene su inscripción en estado `aprobada` o que no requieren inscripción previa.
6. **Calendario (`CalendarioScreen`):**
   - Navegación por fechas para ver los eventos del día.

#### ⚠️ Limitaciones / Cosas a tener en cuenta:
- Se requiere que el bucket `inscripciones-documentos` esté configurado en Supabase con las políticas SQL proporcionadas.
- Si un coordinador se inscribe a un evento, el sistema no le permite auto-aprobarse (debe aprobarlo el Administrador).

#### ❌ Lo que FALTA por completar:
- Notificación automática por push al celular cuando el coordinador aprueba u observa la inscripción (la notificación interna se genera en Firestore, pero falta el trigger de envío push inmediato).

---

### Módulo 5: Panel de Administración (Super Admin)

**Archivos involucrados:**
- `lib/screens/admin/admin_panel_screen.dart`
- `lib/services/admin_service.dart`
- `lib/services/reporte_service.dart`

####  Lo que SÍ funciona:
1. **Pestaña 1 (Métricas):** Contadores globales en tiempo real de campistas registrados, coordinadores activos, bosques fundados y solicitudes de ingreso pendientes.
2. **Pestaña 2 (Bosques):** Listado general de bosques, creación de nuevos bosques asignando coordinador desde un buscador, y eliminación de bosques (con restricción exclusiva para el correo de Super Admin).
3. **Pestaña 3 (Usuarios):** Buscador de usuarios por nombre o documento, cambio de roles (campista <-> coordinador <-> admin), y visualización de su estado de perfil.
4. **Pestaña 4 (Inscripciones - Parcial):**
   - Selección de evento para auditar.
   - Contadores de inscripciones por estado: Aprobadas, Pendientes, Observadas, Rechazadas.
   - Filtro interactivo por estado.
   - Agrupación visual por Municipio y por Bosque mediante listas desplegables (`ExpansionTile`).
   - Exportación de reporte a formato CSV estructurado con codificación UTF-8 BOM para apertura directa en Excel (`ReporteService.exportarInscripcionesCsv`).

#### ⚠️ Limitaciones / Problemas por corregir (Bloque B pendiente):
- **Desbordamiento de píxeles:** En pantallas con ancho reducido (360 dp) o fuentes agrandadas (130%), las 4 tarjetas métricas horizontales de la pestaña inscripciones aún pueden generar advertencias de overflow. Requiere reestructurarse en cuadrícula 2x2.
- **Exportación:** El botón exporta actualmente a CSV; el requerimiento del Bloque B exige generar un archivo `.xlsx` real utilizando el paquete `excel` con dos hojas separadas ("Resumen" e "Inscritos").
- **Aprobación de Respaldo:** Al tocar una inscripción en la lista del admin, debe poder abrir la pantalla de revisión con URL firmada para aprobar inscripciones de coordinadores o actuar como respaldo.

---

### Módulo 6: Notificaciones

**Archivos involucrados:**
- `lib/screens/perfil/notificaciones_screen.dart`
- `lib/services/notification_service.dart`
- `lib/services/messaging_service.dart`
- `lib/models/notification_model.dart`

####  Lo que SÍ funciona:
1. **Colección en Firestore:** Estructura `notificaciones/{userId}/items/{notifId}`.
2. **Badge numérico en tiempo real:** Muestra el número de notificaciones no leídas sobre la campana del Dashboard.
3. **Pantalla de Notificaciones:** Lista las alertas recibidas (comentarios, likes, estados de solicitudes, eventos), marca como leídas al abrir y permite eliminarlas.
4. **Disparadores automáticos:** Se crean registros al recibir comentarios, likes o cambios de solicitud.

#### ⚠️ Limitaciones / Cosas a tener en cuenta:
- `MessagingService` tiene el código base para Firebase Cloud Messaging (FCM), pero las notificaciones push nativas en segundo plano requieren configurar certificados en Android (Google Play Services / SHA-256) y APNs en iOS.

#### ❌ Lo que FALTA por completar:
- Agrupación de notificaciones por fecha (Hoy, Ayer, Esta semana).
- Acción directa al tocar la notificación (deep-link al post o evento correspondiente).

---

### Módulo 7: Cursos y Formación

**Archivos involucrados:**
- `lib/screens/cursos/cursos_screen.dart`
- `lib/screens/cursos/curso_detalle_screen.dart`
- `lib/services/curso_service.dart`
- `lib/models/curso_model.dart`
- `lib/models/leccion_model.dart`

####  Lo que SÍ funciona:
1. **Lógica de backend preparada (`CursoService`):** Métodos escritos para leer cursos desde Firestore (`cursos`), obtener lecciones (`lecciones`), marcar lección completada y actualizar porcentaje de progreso.

#### ⚠️ Limitaciones / Problemas críticos:
- **Datos falsos en pantalla (`CursosScreen`):** La pantalla de cursos **NO usa el servicio de Firestore**. Tiene una lista estática en memoria con 4 cursos de ejemplo y enlaces a fotos de Unsplash (`ViewCourse`).
- **Detalle de curso vacío (`CursoDetalleScreen`):** Es literalmente un archivo placeholder de 20 líneas que dice *"Placeholder - pendiente implementación"*.

#### ❌ Lo que FALTA por completar:
- Conectar `CursosScreen` a Firestore mediante `CursoService`.
- Crear la pantalla de visualización de módulos y lecciones (reproducción de video, lectura de contenido, cuestionario).
- Guardar el avance real del campista en la base de datos para ascensos de rango.

---

### Módulo 8: Perfil, Configuración y Privacidad

**Archivos involucrados:**
- `lib/screens/perfil/perfil_screen.dart`
- `lib/screens/perfil/editar_perfil_screen.dart`
- `lib/screens/perfil/configuracion_screen.dart`
- `lib/screens/perfil/ayuda_soporte_screen.dart`
- `lib/screens/perfil/privacidad_seguridad_screen.dart`

####  Lo que SÍ funciona:
1. **Visualización de Perfil (`PerfilScreen`):** Avatar, rango del campista (Aspirante, Acampador, etc.), bosque actual, fecha de ingreso, datos de contacto y rol.
2. **Edición de Perfil (`EditarPerfilScreen`):** Actualización de teléfono, dirección, municipio, datos médicos y subida de foto de perfil a Supabase Storage (`usuarios-fotos`).
3. **Ayuda y Soporte (`AyudaSoporteScreen`):** Módulo de preguntas frecuentes y canal de soporte.
4. **Reset de Fábrica (`ConfiguracionScreen`):**
   - Herramienta de mantenimiento exclusiva del Super Admin.
   - **Completamente blindada:** Vacía todas las colecciones de Firestore (bosques, miembros, solicitudes, publicaciones, eventos, mensajes, notificaciones) y **elimina todos los archivos y carpetas de los 5 buckets de Supabase Storage**, conservando únicamente la cuenta del Super Admin intacta.

#### ⚠️ Limitaciones / Lo que está a medias:
- **Configuración de Cuenta:** Los botones "Cambiar Correo" y "Cambiar Contraseña" tienen comentarios `// TODO: Implementar`.
- **Preferencias:** Los switches de "Modo Oscuro" e "Idioma" son decorativos y no tienen persistencia.
- **Eliminación de Cuenta:** La opción actual en configuración borra el usuario de Firebase Auth y el documento básico, pero no hace la limpieza profunda exigida por la normativa de protección de datos (borrado de fotos de Supabase, salida formal del bosque y anonimización de comentarios).

#### ❌ Lo que FALTA por completar (Bloque C de Prompts):
- **`PrivacidadSeguridadScreen` está 100% desconectada:** Los 6 botones no hacen nada:
  1. *Términos y Condiciones:* Falta pantalla con visor Markdown (`terminos_v1.md`).
  2. *Política de Privacidad:* Falta pantalla con visor Markdown (`politica_privacidad_v1.md`).
  3. *Gestión de Datos:* Falta opción para descargar datos en JSON y eliminación segura con reautenticación (Bloque C2).
  4. *Verificación en dos pasos:* Falta integración con Identity Platform / SMS (Bloque C5).
  5. *Dispositivos Activos:* Falta colección `users/{uid}/dispositivos` y revocación de sesión remota (Bloque C4).
  6. *Bloqueo de Aplicación:* Falta integración con `local_auth` para solicitar huella o PIN al salir de la app (Bloque C3).

---

## 3. Matriz de Componentes Técnicos

| Componente Técnico | Estado Actual | Detalle de Implementación |
| :--- | :---: | :--- |
| **Flutter / Dart** | 3.5.4 | SDK moderno, Material 3, tema centralizado en `app_theme.dart`. |
| **Firebase Auth** | Activo | Email/Password y Google Sign-In configurados. |
| **Cloud Firestore** | Activo | Reglas de seguridad (`firestore.rules`) al día para usuarios, bosques, eventos e inscripciones. |
| **Supabase Storage** | Activo | 4 buckets públicos (`chat-archivos`, `bosques-fotos`, `usuarios-fotos`, `campju-media`) y 1 privado (`inscripciones-documentos`). |
| **URLs Firmadas** | Activo | Generación de enlaces temporales de 5 min (`createSignedUrl`) para documentos de identidad. |
| **Limpieza de Storage** | Activo | Método `vaciarTodosLosBuckets()` implementado en `SupabaseStorageService`. |
| **Local Auth (Biometría)** | No instalado | Falta agregar `local_auth` a `pubspec.yaml` para el bloqueo con huella. |
| **Generador Excel (.xlsx)** | No instalado | Falta agregar paquete `excel` a `pubspec.yaml` para los reportes administrativos. |

---

## 4. Próximos Pasos Recomendados (Orden de Prioridad)

Para llevar la aplicación a un estado de entrega y producción definitivo, se sugiere el siguiente orden de trabajo:

1. **Bloque B (Finalizar Pestaña de Inscripciones del Admin):**
   - Instalar el paquete `excel` y reemplazar el CSV por un archivo `.xlsx` real con hojas "Resumen" e "Inscritos".
   - Arreglar el diseño de los 4 contadores en una cuadrícula 2x2 para eliminar definitivamente cualquier riesgo de desbordamiento de píxeles.
   - Permitir que el Administrador toque cualquier inscripción y pueda aprobarla como respaldo.
2. **Bloque C1 (Términos, Políticas y Consentimiento Legal):**
   - Crear los archivos de términos y política en `assets/legal/`.
   - Conectar los dos primeros botones de la pantalla de Privacidad y registrar la aceptación en Firestore.
3. **Módulo de Cursos (Conexión Real):**
   - Retirar los datos estáticos de `cursos_screen.dart` y conectar la vista con `CursoService`.
   - Implementar la pantalla básica de detalle de curso.
4. **Bloques C2 y C3 (Gestión de Datos y Bloqueo Biométrico):**
   - Implementar descarga de datos personales en JSON y borrado legal de cuenta.
   - Configurar bloqueo por huella/PIN con `local_auth`.

