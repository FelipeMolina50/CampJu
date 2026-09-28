# CampJu: Plan de Finalización por Fases

Documento maestro para cerrar la aplicación. Mezcla tres capas en cada fase: **especificación funcional** (qué hace), **plan técnico** (cómo se modela y se construye) y **prompt listo** para dárselo a una IA que programe.

Base: `ESTADO_GENERAL_CAMPJU.md`. Stack existente: Flutter (Dart 3.5.4), Firebase Auth, Firestore, Firebase Messaging, Supabase Storage.

---

## 0. Reglas globales (aplican a todas las fases)

### 0.1 Regla de cero emojis
- Ningún emoji en textos, títulos, botones, notificaciones, SnackBars, datos de ejemplo ni mensajes de error.
- Todo símbolo visual se resuelve con `Icon(...)` de Material Icons (o `Symbols` si se adopta `material_symbols_icons`).
- Búsqueda de control antes de cada entrega: buscar en `lib/` caracteres fuera del rango ASCII/latino en strings de UI. Los tildes y la ñ son válidos; los emojis no.
- Las notificaciones push y locales tampoco llevan emojis en título o cuerpo.

### 0.2 Sistema de diseño (tokens centralizados)
Toda la UI consume un único archivo `lib/core/theme/app_theme.dart`. Prohibido usar `Color(0x...)` sueltos en pantallas.

Propuesta de paleta (temática campamento/bosque, editable; si tu paleta actual no te gusta, cambiar estos valores en un solo lugar cambia toda la app):

| Token | Valor | Uso |
| :--- | :--- | :--- |
| `primary` | `#1F4D3A` | Barras, botones principales |
| `primaryContainer` | `#DCEBE2` | Fondos de chips y tarjetas destacadas |
| `secondary` | `#C8781E` | Acciones secundarias, acentos |
| `accent` | `#E0A526` | Badges, resaltados puntuales |
| `background` | `#F6F4EE` | Fondo de pantallas |
| `surface` | `#FFFFFF` | Tarjetas |
| `onSurface` | `#1B1F1D` | Texto principal |
| `onSurfaceMuted` | `#5F6B65` | Texto secundario |
| `error` | `#B3261E` | Errores |
| `like` | `#D6336C` | Corazón activo |

Reglas: máximo 1 color de acento por pantalla, radio de esquinas uniforme (12 px en tarjetas, 999 en chips), espaciado múltiplo de 4, tipografía única (Poppins o Inter vía `google_fonts`), modo claro obligatorio; modo oscuro opcional al final.

### 0.3 Seguridad: los permisos viven en Firestore Rules, no en la UI
Esconder un botón no protege nada. Cada regla de rol de este documento debe reflejarse en `firestore.rules`. Es el punto que más suele fallar y, como se ve en la Fase 1, probablemente es la causa del bug de likes.

### 0.4 Estructura de carpetas objetivo
```
lib/
  core/
    theme/app_theme.dart
    widgets/            (botones, tarjetas, estados vacíos, loaders reutilizables)
    utils/time_ago.dart
  models/               (user, bosque, post, comment, evento, solicitud, notificacion)
  services/             (auth, post, comment, bosque, solicitud, evento, notificacion)
  screens/...
```
Regla: las pantallas no llaman a Firestore directamente; usan `services/`.

### 0.5 Definición de terminado (para cada fase)
1. Funciona con dos cuentas reales distintas en dos dispositivos o emuladores.
2. Las reglas de Firestore lo permiten para el rol correcto y lo bloquean para los demás.
3. Estados vacío, cargando y error diseñados.
4. Cero emojis y cero colores fuera del tema.
5. `flutter analyze` sin errores.

---

## Orden de fases

| Fase | Contenido | Por qué en este orden |
| :--- | :--- | :--- |
| 1 | Base de diseño + arreglo de likes | El bug es de datos y contamina todo lo social |
| 2 | Comentarios y publicaciones del admin en dashboard | Cierra el feed |
| 3 | Panel de administración | Desbloquea roles y bosques sin tocar la consola |
| 4 | Bosques y solicitudes de ingreso | Depende de roles y coordinadores reales |
| 5 | Calendario y cronograma | Necesita bosques y roles definidos |
| 6 | Notificaciones (grupo y calendario) y push en segundo plano | Se conecta a todo lo anterior |
| 7 | Chat: pulido y cierre | Funciona hoy; se pule al final |
| 8 | QA final y release | Verificación completa |

---

## Fase 1: Base de diseño y arreglo de likes

### 1.1 Especificación funcional
- Aplicar el tema global (sección 0.2) y eliminar emojis existentes.
- Cuando cualquier usuario da like, **todos** los usuarios ven el conteo actualizado en tiempo real, y cada usuario ve su propio corazón activo o inactivo.
- Un usuario solo puede dar un like por publicación; tocar de nuevo lo quita.

### 1.2 Diagnóstico del bug (hipótesis ordenadas por probabilidad)
1. **Reglas de Firestore bloquean la escritura.** Si `posts/{id}` solo permite `update` al autor (coordinador/admin), el campo `likesCount` de un campista falla en silencio. Revisar la consola de depuración: aparecerá `permission-denied`.
2. **La UI no escucha en tiempo real.** Si la tarjeta usa `get()` o `FutureBuilder` en vez de `snapshots()` / `StreamBuilder`, el conteo queda congelado hasta recargar.
3. **Estado local optimista sin sincronizar.** El contador sube en el dispositivo que dio el like (variable local) pero nunca se escribe o nunca se relee.
4. **Contador y lista desalineados.** Si se guarda `likesCount` por un lado y un arreglo `likedBy` por otro sin transacción, se desincronizan.

### 1.3 Plan técnico
Modelo (fuente de verdad única):
```
posts/{postId}
  likesCount: int
  commentsCount: int
posts/{postId}/likes/{uid}
  createdAt: timestamp
```
Alternar like en **una transacción** (o `WriteBatch`) que crea o borra `likes/{uid}` y hace `FieldValue.increment(±1)` sobre `likesCount`.

```dart
Future<void> toggleLike(String postId, String uid) async {
  final db = FirebaseFirestore.instance;
  final postRef = db.collection('posts').doc(postId);
  final likeRef = postRef.collection('likes').doc(uid);
  await db.runTransaction((tx) async {
    final like = await tx.get(likeRef);
    if (like.exists) {
      tx.delete(likeRef);
      tx.update(postRef, {'likesCount': FieldValue.increment(-1)});
    } else {
      tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
      tx.update(postRef, {'likesCount': FieldValue.increment(1)});
    }
  });
}
```

UI: `PostCard` usa dos streams: el documento del post (para `likesCount`) y `likes/{uid}` del usuario actual (para el corazón activo). Sin estado local que compita.

Reglas (fragmento):
```
match /posts/{postId} {
  allow read: if request.auth != null;
  allow create: if isCoordinadorOrAdmin();
  allow update: if isAuthorOrAdmin() || onlyCounterChange();
  allow delete: if isAuthorOrAdmin();

  match /likes/{uid} {
    allow read: if request.auth != null;
    allow create, delete: if request.auth.uid == uid;
  }
}
// onlyCounterChange: request.resource.data.diff(resource.data)
//   .affectedKeys().hasOnly(['likesCount','commentsCount'])
```
Nota: la regla `onlyCounterChange` permite que cualquier usuario autenticado modifique el contador. Es aceptable en este nivel del proyecto, pero un usuario malicioso podría inflarlo. La versión robusta es un Cloud Function que mantenga el contador (se puede hacer en la Fase 6 cuando ya existan funciones).

Migración: script único que recorra `posts`, cuente `likes` y corrija `likesCount` de publicaciones antiguas.

### 1.4 Criterios de aceptación
- Cuenta A da like; en cuenta B el conteo sube sin recargar.
- Cuenta A quita el like; el conteo baja en B.
- Dos likes simultáneos de cuentas distintas suman 2.
- Un usuario no puede tener 2 documentos de like en el mismo post.

### 1.5 Prompt para la IA
> Trabajo en una app Flutter con Firebase (Firestore) llamada CampJu. Bug: cuando un usuario da like a una publicación, otros usuarios no ven el contador actualizado. Refactoriza el sistema de likes así: subcolección `posts/{postId}/likes/{uid}` más campo `likesCount` con `FieldValue.increment` dentro de una transacción. La `PostCard` debe usar `StreamBuilder` sobre el documento del post y sobre `likes/{uid}` del usuario actual, sin estado local duplicado. Actualiza `firestore.rules` para que cualquier usuario autenticado pueda crear o borrar solo su propio like y modificar únicamente `likesCount` y `commentsCount` del post. Incluye un script de migración que recalcule `likesCount` de posts existentes. Aplica el tema de `app_theme.dart`, sin emojis ni colores sueltos. Antes de tocar código, lista qué archivos vas a modificar.

---

## Fase 2: Comentarios y publicaciones del administrador en el dashboard

### 2.1 Especificación funcional
**Comentarios**
- Al tocar el ícono de comentarios se abre una hoja modal inferior con la lista y un campo para escribir.
- Cada comentario muestra foto, nombre, tiempo relativo y texto.
- El autor puede borrar su comentario; el coordinador (en su bosque) y el admin pueden borrar cualquiera.
- El contador `commentsCount` de la tarjeta se actualiza en tiempo real para todos.

**Publicaciones del administrador**
- El Super Admin publica desde el dashboard con alcance global: texto, una o varias imágenes, o video.
- Los posts globales se distinguen visualmente (insignia con ícono, sin emoji) del contenido de un bosque.
- Opción de fijar una publicación (`pinned`) para que aparezca arriba del feed.
- Menú de tres puntos en la tarjeta: editar o eliminar (autor, coordinador del bosque emisor, admin).

### 2.2 Plan técnico
```
posts/{postId}
  authorId, authorName, authorRole
  scope: 'global' | 'bosque'
  bosqueId: string?        (null si es global)
  text: string
  media: [{url, type: 'image'|'video'}]
  pinned: bool
  likesCount, commentsCount
  createdAt, editedAt?
posts/{postId}/comments/{commentId}
  authorId, authorName, authorPhoto, text, createdAt
```
- Feed: consulta ordenada por `pinned desc, createdAt desc`; requiere índice compuesto (Firestore lo sugiere en el error de consola).
- Paginación: 10 posts por página con `startAfterDocument`; evita cargar todo el feed.
- Subida de medios: mantener Supabase Storage. Comprimir imágenes antes de subir (`flutter_image_compress`), límite recomendado 1600 px de lado largo.
- Crear comentario: transacción que agrega el documento e incrementa `commentsCount`.
- Borrar publicación: eliminar también sus archivos de Supabase (para no acumular basura de storage).

Reglas: `comments` lectura para autenticados; creación con `authorId == request.auth.uid`; borrado para autor, coordinador del bosque del post o admin.

### 2.3 Criterios de aceptación
- Un comentario escrito en la cuenta A aparece en B en menos de 2 segundos.
- El admin publica 3 imágenes y se ven en el carrusel del feed de un campista.
- Un post fijado se mantiene arriba aunque haya posts más nuevos.
- Un campista no ve el menú de editar/eliminar en posts ajenos y, aunque lo intentara por código, las reglas lo bloquean.

### 2.4 Prompt para la IA
> En CampJu (Flutter, Firestore, Supabase Storage) implementa: 1) hoja modal de comentarios con `posts/{id}/comments`, transacción que incrementa `commentsCount`, borrado por autor, coordinador del bosque o admin. 2) Publicaciones globales del Super Admin con múltiples imágenes o video, campo `pinned` y `scope`. 3) Menú de tres puntos con editar y eliminar según rol. 4) Paginación de 10 en 10 del feed, orden `pinned desc, createdAt desc`. 5) Al eliminar un post, borra sus archivos en Supabase. Actualiza `firestore.rules` y `firestore.indexes.json`. Cero emojis (usar Icons), colores solo desde `app_theme.dart`. Muéstrame primero el plan de archivos.

---

## Fase 3: Panel de administración (Super Admin)

### 3.1 Especificación funcional
Acceso: el botón aparece en el perfil **solo si** `role == UserRole.admin`, y la ruta además valida el rol al entrar.

Pantallas:
1. **Resumen:** tarjetas con total de campistas, coordinadores, bosques y solicitudes pendientes.
2. **Usuarios:** listado con buscador (nombre, correo, documento) y filtros por rol y municipio. Al tocar un usuario: ver ficha y cambiar rol.
3. **Bosques (CRUD):** crear, editar (nombre, descripción, cupos, foto) y eliminar bosques.
4. **Asignación de coordinadores:** desde un bosque, elegir un usuario como coordinador.

Reglas de negocio:
- Un coordinador solo existe si tiene un bosque asignado. No se puede ascender a Coordinador sin elegir bosque en el mismo paso.
- Un bosque tiene exactamente un coordinador.
- Degradar a Campista libera el bosque como coordinado, pero el usuario puede seguir como miembro si así se decide (definir en pantalla con una opción explícita).
- El admin no puede quitarse su propio rol de admin desde la app (evita quedarse sin administrador).
- Eliminar un bosque exige confirmación con el nombre escrito y decide qué pasa con sus miembros: quedan sin bosque.

### 3.2 Plan técnico
```
users/{uid}
  role: 'campista' | 'coordinador' | 'admin'
  bosqueId: string?         (bosque al que pertenece)
  nombreLower: string       (para búsqueda por prefijo)
bosques/{bosqueId}
  nombre, descripcion, fotoUrl
  cupos: int, miembrosCount: int
  coordinadorId: string?
  createdAt
```
- Asignar coordinador = `WriteBatch`: actualizar `users.role`, `users.bosqueId`, `bosques.coordinadorId`, y si había coordinador previo, devolverlo a `campista`.
- Búsqueda: Firestore no tiene búsqueda de texto completo. Con pocos cientos de usuarios, cargar y filtrar en cliente es suficiente; si crece, búsqueda por prefijo sobre `nombreLower`.
- Reglas: `users.role` y `users.bosqueId` solo modificables por admin (o por el flujo de solicitudes de la Fase 4). Un usuario puede editar su perfil pero **no** su rol:
```
allow update: if request.auth.uid == uid
  && !request.resource.data.diff(resource.data).affectedKeys()
       .hasAny(['role','bosqueId']);
```
- Helper de reglas: `isAdmin()` leyendo `get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'`.
- Primer admin: se crea manualmente una sola vez en la consola (campo `role`). Después todo se hace desde la app.

### 3.3 Criterios de aceptación
- El admin asciende a un campista a coordinador asignándole un bosque y el usuario ve el cambio sin reiniciar sesión.
- Un campista que edita su perfil no puede cambiarse el rol (probado con la consola de reglas).
- Un usuario no admin que navega directamente a la ruta del panel es redirigido.

### 3.4 Prompt para la IA
> En CampJu implementa el Panel de Administración. Pantallas: resumen con contadores, usuarios (buscador, filtros por rol, cambio de rol), CRUD de bosques (nombre, descripción, cupos, foto en Supabase) y asignación de coordinador. Reglas de negocio: un coordinador exige bosque; un bosque tiene un solo coordinador; el admin no puede degradarse a sí mismo. Usa `WriteBatch` para asignaciones. Acceso al botón y a la ruta solo con `role == admin`. Actualiza `firestore.rules` para que `role` y `bosqueId` solo los cambie un admin. Sin emojis, solo Icons; colores desde `app_theme.dart`. Empieza mostrando el árbol de archivos.

---

## Fase 4: Bosques y solicitudes de ingreso

### 4.1 Especificación funcional
**Campista sin bosque**
- Ve el listado de bosques con nombre, coordinador, cupos disponibles y botón "Solicitar unirme".
- Estados de solicitud visibles: pendiente, aceptada, rechazada. Puede cancelar una pendiente.
- Solo una solicitud pendiente a la vez.

**Coordinador**
- Pantalla "Solicitudes" con nombre, municipio, nivel y fecha; botones aceptar y rechazar (con motivo opcional).
- Al aceptar: el usuario pasa a ser miembro, se incrementa `miembrosCount`, y se valida que haya cupo.
- Ve la lista de miembros de su bosque y puede retirar a un miembro.

**Todos**
- Perfil de bosque en hoja modal (ya existe): mantener y mostrar cupos y coordinador.
- Un campista puede salir voluntariamente de su bosque.

### 4.2 Plan técnico
```
solicitudes/{solicitudId}
  userId, userName, bosqueId
  estado: 'pendiente' | 'aceptada' | 'rechazada' | 'cancelada'
  motivoRechazo?: string
  createdAt, resolvedAt?, resolvedBy?
```
- Aceptar = **transacción**: releer el bosque, validar `miembrosCount < cupos`, actualizar la solicitud, escribir `users.bosqueId`, incrementar `miembrosCount`, crear notificación al solicitante.
- Como `users.bosqueId` solo lo cambia el admin según la Fase 3, agregar excepción en reglas: el coordinador del bosque puede establecer `bosqueId` de un usuario únicamente al valor de su propio bosque y solo si existe solicitud pendiente. Si esto se vuelve engorroso en reglas, es la segunda razón (junto con contadores) para introducir Cloud Functions en la Fase 6.
- Índice compuesto: `solicitudes` por `bosqueId + estado + createdAt`.

### 4.3 Criterios de aceptación
- Un campista solicita, el coordinador acepta, y el campista ve su bosque y recibe notificación.
- Con el bosque lleno, el coordinador no puede aceptar y ve un mensaje claro.
- Dos coordinadores no pueden ver solicitudes de bosques ajenos.

### 4.4 Prompt para la IA
> En CampJu implementa solicitudes de ingreso a bosques. Colección `solicitudes` con estados pendiente, aceptada, rechazada y cancelada. El campista sin bosque ve el listado con cupos y solicita; solo una pendiente a la vez y puede cancelar. El coordinador ve solicitudes de su bosque y acepta o rechaza; aceptar es una transacción que valida cupos, actualiza `users.bosqueId`, incrementa `miembrosCount` y crea una notificación al solicitante. Agrega también salir del bosque y retirar miembro. Actualiza `firestore.rules` e índices. Sin emojis, tema centralizado. Muestra el plan antes de codificar.

---

## Fase 5: Calendario y cronograma

### 5.1 Especificación funcional
**Calendario**
- Vista mensual con marcadores por día que tiene eventos, y vista de lista del día seleccionado. Alternar mensual y semanal.
- Filtros: todos, globales, de mi bosque.
- Cada tipo de evento tiene ícono y color del tema (por ejemplo: campamento, reunión de bosque, ceremonia, capacitación).

**Cronograma**
- Línea de tiempo agrupada por día con hora, lugar, responsable y descripción.
- Pantalla de detalle del evento con botón "Recordarme" (programa alarma local) y, si el usuario tiene permiso, editar y eliminar.

**Quién crea qué**
- Super Admin: eventos globales (visibles para todos) y de cualquier bosque.
- Coordinador: eventos solo de su bosque.
- Campista: solo lectura y recordatorios personales.

### 5.2 Plan técnico
```
eventos/{eventoId}
  titulo, descripcion, lugar, responsable
  tipo: 'campamento' | 'reunion' | 'ceremonia' | 'capacitacion' | 'otro'
  scope: 'global' | 'bosque'
  bosqueId: string?
  inicio: timestamp, fin: timestamp
  creadoPor, createdAt
```
- Paquete de calendario: `table_calendar`. Zona horaria fija `America/Bogota` con el paquete `timezone`.
- Consulta del mes: eventos con `inicio` entre el primer y último día visible, más un `where scope == global` combinado con los del bosque del usuario (dos consultas fusionadas en cliente).
- Recordatorios locales: `flutter_local_notifications` con `zonedSchedule`, guardando el id del recordatorio localmente. Permiso `SCHEDULE_EXACT_ALARM` en Android 12+ o usar programación inexacta si no se concede.
- Reemplazar las pantallas `placeholder_screen.dart` de Cronograma y Calendario y enlazar los accesos rápidos del dashboard.
- Al crear un evento se genera una notificación para los destinatarios (Fase 6).

### 5.3 Criterios de aceptación
- El coordinador crea un evento de su bosque; solo los miembros de ese bosque lo ven.
- El admin crea un evento global; todos lo ven.
- Un campista programa un recordatorio y suena a la hora indicada con la app cerrada.
- Editar la hora de un evento actualiza el cronograma de todos.

### 5.4 Prompt para la IA
> En CampJu reemplaza los placeholders de Calendario y Cronograma. Colección `eventos` con `scope` global o bosque, tipo, inicio, fin, lugar y responsable. Calendario con `table_calendar` (mensual y semanal), zona `America/Bogota`, filtros todos, globales y mi bosque. Cronograma como línea de tiempo por día. Detalle con botón Recordarme usando `zonedSchedule` de `flutter_local_notifications`. Permisos: admin crea globales y de cualquier bosque; coordinador solo de su bosque; campista solo lectura. Actualiza reglas e índices. Sin emojis: íconos por tipo de evento con Icons. Colores desde `app_theme.dart`. Primero dame el plan de archivos.

---

## Fase 6: Notificaciones (grupo y calendario) y push en segundo plano

### 6.1 Especificación funcional
Eventos que generan notificación:

| Tipo | Quién la recibe |
| :--- | :--- |
| `publicacion` | Miembros del bosque emisor (o todos si es global) |
| `comentario` | Autor del post |
| `mensaje` | Miembros del bosque (chat) |
| `evento_nuevo` | Destinatarios del evento (global o bosque) |
| `evento_recordatorio` | Destinatarios, 24 h y 1 h antes |
| `solicitud_nueva` | Coordinador del bosque |
| `solicitud_resuelta` | Solicitante |
| `rol_cambiado` | Usuario afectado |

- El usuario puede activar o desactivar cada tipo en Preferencias (ya existe la pestaña; ampliarla a estos tipos).
- El badge del dashboard cuenta solo no leídas.
- Tocar una notificación navega a la pantalla correspondiente (post, chat, evento, solicitudes).

### 6.2 Plan técnico
```
users/{uid}/notificaciones/{id}
  tipo, titulo, cuerpo, leida: bool, createdAt
  ref: { tipo: 'post'|'evento'|'solicitud'|'chat', id: string }
```
Mover las notificaciones a subcolección por usuario simplifica reglas (cada usuario lee solo las suyas) y consultas.

**Cloud Functions (recomendado y necesario para push con app cerrada):**
- `onPostCreate`: crea notificaciones y envía FCM al topic `bosque_<id>` o `global`.
- `onEventoCreate`: igual para eventos.
- `onChatMessageCreate`: FCM al topic del bosque, excluyendo al remitente.
- `onSolicitudWrite`: notifica a coordinador o solicitante.
- `scheduleRecordatorios` (Cloud Scheduler cada 15 min): busca eventos que empiezan en 24 h o 1 h y envía recordatorios.
- `onLikeWrite` / `onCommentWrite`: mantienen `likesCount` y `commentsCount` (permite endurecer las reglas de la Fase 1).

**Aviso de costo:** Cloud Functions y Cloud Scheduler requieren el plan Blaze de Firebase (pago por uso, con cuota gratuita generosa). Sin Blaze, no hay forma confiable de enviar push con la app cerrada; en ese caso quedan solo las notificaciones locales y el listado interno. Confirma esto antes de comprometerte con la fase.

Cliente:
- Suscribir el topic `bosque_<id>` al unirse a un bosque y desuscribir al salir; suscribir a `global` siempre.
- Manejar los tres estados de FCM: primer plano, segundo plano y app cerrada (`getInitialMessage`, `onMessageOpenedApp`).
- Canal de notificaciones de Android con nombre e importancia definidos.

### 6.3 Criterios de aceptación
- Con la app cerrada en el dispositivo B, un post del coordinador en A hace sonar B.
- Al tocar la notificación se abre el post o evento correcto.
- Un usuario con el tipo `publicacion` desactivado no recibe esas notificaciones.
- El recordatorio de 1 h llega una sola vez (sin duplicados).

### 6.4 Prompt para la IA
> En CampJu implementa notificaciones completas. Mueve las notificaciones a `users/{uid}/notificaciones` con `tipo`, `leida` y `ref` para navegar. Crea Firebase Cloud Functions (Node/TypeScript) para: publicación, evento nuevo, mensaje de chat, solicitudes, recordatorios de evento 24 h y 1 h antes (Cloud Scheduler) y mantenimiento de `likesCount` y `commentsCount`. Envía FCM a topics `bosque_<id>` y `global`. En Flutter maneja primer plano, segundo plano y app cerrada, con navegación al tocar. Respeta las preferencias por tipo del usuario. Sin emojis en títulos ni cuerpos. Antes de programar, dime qué requiere el plan Blaze y qué haría falta si no lo tengo.

---

## Fase 7: Chat, pulido y cierre

El chat funciona (85%). Cerrar lo que suele faltar:
- Contador de no leídos por bosque (`lastReadAt` por usuario en el bosque).
- Indicador de fecha entre mensajes de días distintos.
- Borrado de mensaje propio y moderación por coordinador o admin.
- Paginación de mensajes (últimos 30, cargar más al subir).
- Estados de envío (enviando, enviado, error con reintento) para adjuntos.
- Límite de tamaño de adjuntos y mensaje claro si se excede.

### Prompt para la IA
> En CampJu pule el chat de bosque: contador de no leídos con `lastReadAt`, separadores de fecha, borrado de mensajes propios y moderación, paginación de 30 en 30, estados de envío con reintento para adjuntos y límite de tamaño con mensaje claro. Sin emojis, íconos de Material, tema centralizado. Muestra primero los archivos a tocar.

---

## Fase 8: QA final y release

- Prueba de humo con tres cuentas: campista, coordinador, admin, en dos dispositivos.
- Matriz rol contra acción: recorrer cada permiso de este documento y confirmar que lo permitido funciona y lo prohibido es rechazado por las reglas (no solo oculto en la UI).
- Revisar Firestore: índices creados, reglas desplegadas, sin colecciones abiertas (`allow read, write: if true` prohibido).
- Revisar Supabase: buckets con políticas correctas y sin acceso de escritura anónimo.
- Rendimiento: imágenes comprimidas, listas paginadas, streams cancelados al salir de pantalla.
- Buscar emojis y colores fuera del tema en todo `lib/`.
- Generar APK de release firmado (`flutter build apk --release`), probar instalación limpia y actualización sobre versión previa.
- Congelar versión y escribir un `CHANGELOG.md`.

---

## Anexo A: Matriz de permisos

| Acción | Campista | Coordinador | Super Admin |
| :--- | :---: | :---: | :---: |
| Ver feed | Sí | Sí | Sí |
| Dar like y comentar | Sí | Sí | Sí |
| Publicar en bosque | No | Su bosque | Cualquiera |
| Publicar global | No | No | Sí |
| Editar o eliminar posts | Los suyos (si aplica) | Su bosque | Todos |
| Solicitar ingreso a bosque | Sí | No aplica | No aplica |
| Aceptar o rechazar solicitudes | No | Su bosque | Todos |
| Crear eventos | No | Su bosque | Globales y todos |
| Cambiar roles | No | No | Sí |
| Crear, editar o eliminar bosques | No | No | Sí |
| Chat del bosque | Su bosque | Su bosque | Lectura y moderación |

## Anexo B: Riesgos que debes decidir pronto

1. **Plan Blaze de Firebase.** Sin él no hay push con app cerrada ni contadores a prueba de manipulación. Decisión que condiciona la Fase 6.
2. **Contadores desde el cliente.** Hoy son manipulables por un usuario técnico. Aceptable para un programa comunitario pequeño; moverlos a Cloud Functions cuando se active Blaze.
3. **Dependencia doble de Firebase y Supabase.** Dos proveedores para storage y datos complican reglas y limpieza de archivos. No hace falta migrar ahora, pero cada borrado debe limpiar ambos lados.
4. **Datos personales.** La app guarda documento, municipio y sexo de campistas. Verifica que quién los ve esté restringido por reglas (solo el propio usuario y el admin), y que Privacidad y Seguridad declare esto con claridad.
5. **Tema visual.** Si la paleta propuesta tampoco convence, cámbiala en `app_theme.dart` antes de la Fase 2; cambiarla después obliga a revisar pantallas ya hechas.
