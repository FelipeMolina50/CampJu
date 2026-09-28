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
| 2 | Comentarios y publicaciones en el feed (a nombre del bosque o de la organización) | Cierra el feed |
| 3 | Panel de administración | Desbloquea roles y bosques sin tocar la consola |
| 4 | Bosques y solicitudes de ingreso | Depende de roles y coordinadores reales |
| 5 | Campamentos, inscripciones, agenda y exportación a Excel | Necesita roles y bosques con coordinadores reales |
| 6 | Notificaciones (chat, feed, eventos) y push en segundo plano | Se conecta a todo lo anterior |
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
  allow create: if canPublish(request.resource.data);   // definida en la Fase 2
  allow update: if canModerate(resource.data) || onlyCounterChange();
  allow delete: if canModerate(resource.data);

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

## Fase 2: Comentarios y publicaciones en el feed

### 2.1 Especificación funcional

**Quién publica y a nombre de quién**
- El feed es público: todo usuario autenticado ve todas las publicaciones, pertenezca o no a un bosque.
- Publican únicamente el **Coordinador** y el **Super Admin**. El campista solo lee, da like y comenta. Así se limita quién publica y se mantiene el feed enfocado en los campamentos.
- El coordinador publica para todo el mundo, pero la publicación figura **a nombre de su bosque**, no de él: la tarjeta muestra el nombre y la foto del bosque, y el nombre del coordinador no aparece en ninguna parte (ni en la tarjeta ni en el detalle). Las fotos y videos pertenecen a ese bosque.
- Tocar el nombre del bosque en la tarjeta abre el perfil del bosque (la hoja modal que ya existe).
- Si cambia el coordinador de un bosque, las publicaciones anteriores siguen siendo del bosque y el nuevo coordinador puede moderarlas.
- El Super Admin publica como organización (nombre del programa, por ejemplo "CampJu"), con una insignia con ícono (sin emoji) que lo distingue de las de un bosque.
- Opción de fijar una publicación (`pinned`) para que aparezca arriba del feed (solo admin).
- Contenido: texto, una o varias imágenes, o video.

**Control de contenido: solo cosas de campamentos**
Ningún sistema puede verificar automáticamente qué muestra una foto. Lo que sí se puede hacer, y es lo que propongo:
1. Solo dos roles pueden publicar (arriba).
2. **El coordinador debe asociar cada publicación a un campamento o actividad** de su bosque, elegido en un selector al publicar. La tarjeta muestra una etiqueta con el título del evento. El admin puede publicar sin asociar.
3. El admin puede eliminar cualquier publicación que se salga del tema.

El punto 2 depende de los eventos, que se construyen en la Fase 5. Por eso en esta fase el campo `eventoId` se crea como opcional y la regla que lo vuelve obligatorio para coordinadores se activa en la sub-fase 5A. Si prefieres que sea opcional de forma permanente, basta con no activar esa regla.

**Comentarios**
- Al tocar el ícono de comentarios se abre una hoja modal inferior con la lista y un campo para escribir.
- Cada comentario muestra foto, nombre, tiempo relativo y texto.
- El autor puede borrar su comentario; el coordinador del bosque de la publicación y el admin pueden borrar cualquiera.
- El contador `commentsCount` de la tarjeta se actualiza en tiempo real para todos.

**Menú de tres puntos en la tarjeta:** editar o eliminar, visible solo para el coordinador del bosque emisor y para el admin.

**Notificación al publicar:** los miembros del bosque emisor reciben aviso (comportamiento actual). El resto de usuarios ve la publicación en el feed sin notificación. Las del admin se notifican a todos (Fase 6).

### 2.2 Plan técnico
```
posts/{postId}
  tipo: 'publicacion' | 'evento'
  autorTipo: 'bosque' | 'organizacion'
  bosqueId: string?          // null si autorTipo == 'organizacion'
  creadoPor: uid             // solo auditoría y moderación; NO se muestra en ninguna pantalla
  eventoId: string?          // campamento o actividad al que se refiere la publicación
  text: string
  media: [{url, type: 'image'|'video'}]
  pinned: bool
  likesCount, commentsCount
  createdAt, editedAt?
posts/{postId}/comments/{commentId}
  authorId, authorName, authorPhoto, text, createdAt
```
- El nombre y la foto del bosque **no se copian** al post: la tarjeta los resuelve desde una lista de bosques cargada una vez y en caché (son pocos). Así, si un bosque cambia de nombre o de foto, todas sus publicaciones se actualizan solas.
- Ya no existe el campo `scope`: todas las publicaciones son visibles para todos.
- Feed: consulta ordenada por `pinned desc, createdAt desc`; requiere índice compuesto (Firestore lo sugiere en el error de consola).
- Paginación: 10 publicaciones por página con `startAfterDocument`; evita cargar todo el feed.
- Subida de medios: mantener Supabase Storage. Comprimir imágenes antes de subir (`flutter_image_compress`), límite recomendado 1600 px de lado largo. Ruta sugerida `posts/<bosqueId o org>/<postId>/<archivo>`, que permite mostrar la galería de un bosque y limpiar archivos al borrar.
- Crear comentario: transacción que agrega el documento e incrementa `commentsCount`.
- Borrar publicación: eliminar también sus archivos de Supabase (para no acumular basura de storage).
- Migración: las publicaciones existentes con `authorId` y `bosqueId` se convierten a `creadoPor`, `autorTipo` y `bosqueId`; las del admin pasan a `autorTipo: 'organizacion'`.

Reglas (fragmento; reemplaza el de la Fase 1 para `posts`):
```
function canPublish(data) {
  return isAdmin()
    || (isCoordinador()
        && data.autorTipo == 'bosque'
        && data.bosqueId == myBosqueId()
        && data.creadoPor == request.auth.uid);
        // desde la Fase 5A: && data.eventoId != null
}
function canModerate(post) {
  return isAdmin() || (isCoordinador() && post.bosqueId == myBosqueId());
}

match /posts/{postId} {
  allow read: if request.auth != null;
  allow create: if canPublish(request.resource.data);
  allow update: if canModerate(resource.data) || onlyCounterChange();
  allow delete: if canModerate(resource.data);

  match /comments/{cid} {
    allow read: if request.auth != null;
    allow create: if request.auth.uid == request.resource.data.authorId;
    allow delete: if request.auth.uid == resource.data.authorId
      || canModerate(get(/databases/$(database)/documents/posts/$(postId)).data);
  }
}
```
Nota: moderar se define por el **bosque** de la publicación y no por quien la creó, para que un coordinador nuevo herede la moderación.

### 2.3 Criterios de aceptación
- Un comentario escrito en la cuenta A aparece en B en menos de 2 segundos.
- Una publicación del coordinador del bosque X muestra el nombre y la foto de X, y en ningún lugar el nombre del coordinador.
- Un campista de otro bosque (o sin bosque) ve esa publicación en su feed.
- Un campista no tiene botón de publicar y, aunque lo intentara por código, las reglas rechazan la creación.
- Un coordinador no puede publicar a nombre de otro bosque (las reglas lo rechazan).
- Al cambiar el coordinador de un bosque, el nuevo puede editar y eliminar las publicaciones anteriores del bosque.
- El admin publica 3 imágenes como organización y se ven en el carrusel del feed de un campista.
- Un post fijado se mantiene arriba aunque haya posts más nuevos.
- (Desde 5A) Un coordinador no puede publicar sin elegir un campamento o actividad.

### 2.4 Prompt para la IA
> En CampJu (Flutter, Firestore, Supabase Storage) implementa: 1) hoja modal de comentarios con `posts/{id}/comments`, transacción que incrementa `commentsCount`, borrado por autor, coordinador del bosque de la publicación o admin. 2) Publicaciones del feed visibles para todos los usuarios autenticados. Solo publican Coordinador y Super Admin. El coordinador publica **a nombre de su bosque**: guarda `autorTipo: 'bosque'`, `bosqueId` y `creadoPor` (solo para auditoría), y la tarjeta muestra nombre y foto del bosque resueltos desde una lista de bosques en caché, sin mostrar jamás el nombre del coordinador; tocar el bosque abre su perfil. El admin publica como organización (`autorTipo: 'organizacion'`) con insignia. Soporta múltiples imágenes o video, `pinned` (solo admin) y un campo opcional `eventoId` con selector de evento. Elimina el campo `scope`. 3) Menú de tres puntos con editar y eliminar solo para el coordinador del bosque emisor y el admin. 4) Paginación de 10 en 10, orden `pinned desc, createdAt desc`. 5) Al eliminar un post, borra sus archivos en Supabase. 6) Script de migración de las publicaciones existentes. Actualiza `firestore.rules` con `canPublish` y `canModerate` definidos por el bosque del post, y `firestore.indexes.json`. Cero emojis (usar Icons), colores solo desde `app_theme.dart`. Muéstrame primero el plan de archivos.

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

## Fase 5: Campamentos, inscripciones, agenda y exportación

Esta fase reemplaza el antiguo "Calendario y cronograma". Es la más grande del proyecto, así que se divide en cuatro sub-fases (5A a 5D), cada una con su prompt. Depende de que la Fase 3 (roles) y la Fase 4 (bosques y coordinadores reales) estén terminadas.

### 5.0 Nombres y pantallas

| Pantalla | Qué responde | Qué muestra |
| :--- | :--- | :--- |
| **Eventos** (antes "Cronograma") | En qué me puedo inscribir | Campamentos y actividades dirigidos a mí, con su estado de inscripción |
| **Agenda** (antes "Calendario") | A qué voy | Vista mensual y lista de lo confirmado únicamente |

El nombre "Cronograma" desaparece. Accesos rápidos del dashboard: Eventos, Alertas y Agenda (con íconos, sin emojis). Son dos pantallas con propósitos distintos, no una lista repetida.

### 5.1 Tipos de evento y quién hace qué

| Tipo | Lo crea | Destinatarios | Inscripción | Quién aprueba |
| :--- | :--- | :--- | :---: | :--- |
| Actividad de bosque | Coordinador | Su bosque | Opcional | Coordinador |
| Campista por un día | Coordinador | Su bosque | Sí | Coordinador |
| Municipal | Coordinador | Su bosque | Sí | Coordinador |
| Interzonal | Super Admin | Los bosques que el admin elija | Sí | Coordinador de cada bosque |
| Departamental | Super Admin | Todos los bosques | Sí | Coordinador de cada bosque |
| Nacional | Super Admin | Todos los bosques | Sí | Coordinador de cada bosque |

Notas:
- El Super Admin también puede crear los tres primeros tipos, para cualquier bosque.
- Supuesto: el campamento nacional se crea y se inscribe igual que el departamental. Si tiene reglas propias (otros documentos, inscripción por otra vía), se define aparte.
- El coordinador es quien filtra: el admin crea el campamento, pero **no revisa inscritos uno por uno**. Esa es la razón de ser del diseño.

### 5.2 Flujo de inscripción

Estados de una inscripción: `borrador`, `pendiente`, `observada`, `aprobada`, `rechazada`, `cancelada`.

1. El evento se publica. Los destinatarios reciben la notificación (Fase 6).
2. El campista abre el evento desde Eventos y toca "Inscribirme". Ve la lista de documentos requeridos y sube cada uno (estado `borrador`).
3. Al enviar, la inscripción pasa a `pendiente` y el coordinador de su bosque recibe la alerta.
4. El coordinador abre la inscripción y revisa **documento por documento**: marca cada uno como correcto o rechazado con una nota corta ("la autorización no tiene firma").
5. Si hay documentos rechazados, la inscripción pasa a `observada`: el campista recibe la nota, vuelve a subir solo lo rechazado y reenvía (`pendiente` de nuevo).
6. Cuando todos los documentos están correctos, el coordinador aprueba (`aprobada`). El evento aparece en la Agenda del campista y cuenta para el listado del admin.
7. El coordinador puede rechazar definitivamente (`rechazada`, con motivo). El campista puede cancelar (`cancelada`) antes de la fecha límite.

### 5.3 Reglas de negocio

- Solo se inscribe quien pertenece a un bosque; sin bosque no hay coordinador que apruebe. La pantalla lo explica y lleva a "Buscar bosque".
- Un coordinador solo revisa inscripciones de su bosque.
- **El coordinador que quiere ir a un campamento** no puede aprobarse a sí mismo: su inscripción la revisa el Super Admin. Es un caso pequeño pero real y hay que resolverlo desde el inicio.
- **Coordinador ausente:** el Super Admin puede aprobar cualquier inscripción como plan de respaldo.
- Cada evento define su lista de `documentosRequeridos` (nombre, obligatorio o no). Ejemplos: copia del documento, autorización firmada, carnet de salud, comprobante de pago.
- Fecha límite de inscripción: pasada, no se puede enviar ni modificar; el coordinador puede seguir revisando pendientes hasta `fechaLimiteAprobacion`.
- Cupos opcionales: total del evento y/o por bosque. Se validan en una transacción al aprobar.
- Si el Super Admin modifica fecha, lugar o cancela el evento, se notifica a los inscritos aprobados y pendientes.

### 5.4 Modelo de datos

```
eventos/{eventoId}
  titulo, descripcion, lugar, municipioSede
  tipo: 'actividad' | 'campista_dia' | 'municipal'
        | 'interzonal' | 'departamental' | 'nacional'
  bosquesIds: [string]        // bosque, municipal, interzonal: los destinatarios
                              // departamental y nacional: vacío = todos
  inicio, fin: timestamp
  requiereInscripcion: bool
  documentosRequeridos: [{id, nombre, obligatorio}]
  fechaLimiteInscripcion, fechaLimiteAprobacion: timestamp?
  cupoTotal: int?, cupoPorBosque: int?
  aprobadosCount: int
  estado: 'abierto' | 'cerrado' | 'cancelado'
  creadoPor, creadorRol, createdAt

inscripciones/{eventoId}_{uid}         // id compuesto: una por usuario y evento
  eventoId, uid, bosqueId
  nombre, documentoId, municipio, sexo, nivel, telefono   // copia al inscribirse (para el Excel)
  estado: 'borrador'|'pendiente'|'observada'|'aprobada'|'rechazada'|'cancelada'
  documentos: { <docReqId>: { path, estado: 'pendiente'|'ok'|'rechazado', nota? } }
  motivo?: string
  revisadoPor?, revisadoAt?
  createdAt, updatedAt
```

Decisiones:
- Se copian los datos del campista a la inscripción para que el Excel sea una lectura simple y no dependa de cambios posteriores en su perfil.
- El id compuesto `eventoId_uid` impide inscripciones duplicadas sin consultas extra.
- Consulta de eventos para un usuario: eventos donde `bosquesIds` contiene su `bosqueId`, más los de tipo departamental y nacional. Son dos consultas fusionadas en el cliente. Nota: el operador `in` de Firestore admite máximo 30 valores por consulta; por eso se usa `array-contains` sobre el bosque del usuario y no al revés.
- Índices: `inscripciones` por `eventoId + estado + municipio`; `inscripciones` por `bosqueId + estado + createdAt`; `eventos` por `estado + inicio`.

### 5.5 Documentos: almacenamiento y privacidad

Esta parte es la más delicada del proyecto. Los archivos pueden incluir copias de documento de identidad, autorizaciones de menores y datos de salud.

- Bucket **privado** en Supabase (`inscripciones-docs`), nunca público. Ruta: `<eventoId>/<uid>/<docReqId>.<ext>`.
- Acceso solo mediante URLs firmadas de corta duración (por ejemplo, 5 minutos), generadas cuando el coordinador o el admin abre el documento.
- Lectura permitida únicamente para: el propio campista, el coordinador de su bosque y el Super Admin.
- Formatos permitidos: PDF, JPG, PNG. Límite de 5 MB por archivo, con compresión de imágenes en el cliente.
- Política de retención: borrar los documentos unos días o semanas después de terminado el campamento (definir plazo). No conviene acumular datos sensibles sin necesidad.
- Si hay menores de edad, el tratamiento de sus datos exige autorización y cuidado especial. No soy abogado, pero conviene revisar con quien corresponda en el programa el cumplimiento de la ley colombiana de protección de datos (Ley 1581 de 2012) antes de lanzar.

### 5.6 Agenda

La Agenda del campista muestra un evento únicamente cuando:
- es un evento sin inscripción de su bosque, o
- tiene una inscripción en estado `aprobada`.

Todo lo demás (pendiente, observada, rechazada, o sin inscribirse) aparece solo en la pantalla Eventos con su estado y no en la Agenda. Vista mensual con `table_calendar`, vista de lista por día, zona horaria `America/Bogota`, y botón "Recordarme" con `zonedSchedule` de `flutter_local_notifications`.

El coordinador ve en su Agenda, además, los eventos de su bosque que él creó, aunque no tengan inscripción propia.

### 5.7 Reportes y Excel para el Super Admin

Pantalla "Inscritos" del evento, accesible desde el Panel de Administración:
- Contadores: total aprobados, pendientes, observadas y rechazadas.
- Vista agrupada por **municipio** y, dentro de cada uno, por bosque.
- Filtro por estado. Por defecto solo aprobados.
- Botón "Exportar Excel".

Estructura del archivo `.xlsx`:
1. **Resumen:** una fila por municipio con total de inscritos y desglose por bosque.
2. **Inscritos:** todas las filas ordenadas por municipio, luego bosque, luego nombre. Columnas: municipio, bosque, coordinador, nombre completo, documento, sexo, nivel, teléfono, estado de documentos y fecha de aprobación.
3. Opcional: una hoja por municipio, si el listado se va a imprimir por delegación.

Implementación: generar el archivo **en el dispositivo** con el paquete `excel` y compartirlo con `share_plus`. No requiere backend ni el plan Blaze; con cientos de inscritos es suficiente. El coordinador puede exportar el listado de su propio bosque con el mismo componente.

El Excel contiene datos personales: solo el Super Admin (todo) y cada coordinador (su bosque) pueden generarlo.

### 5.8 Reglas de Firestore (fragmento)

```
match /eventos/{id} {
  allow read: if request.auth != null;   // el filtro fino es de la consulta; ver nota
  allow create: if isAdmin()
    || (isCoordinador()
        && request.resource.data.tipo in ['actividad','campista_dia','municipal']
        && request.resource.data.bosquesIds == [myBosqueId()]);
  allow update, delete: if isAdmin()
    || (isCoordinador() && resource.data.creadoPor == request.auth.uid);
}

match /inscripciones/{id} {
  allow read: if request.auth.uid == resource.data.uid
    || isCoordinadorDe(resource.data.bosqueId) || isAdmin();
  allow create: if request.auth.uid == request.resource.data.uid
    && request.resource.data.bosqueId == myBosqueId()
    && request.resource.data.estado in ['borrador','pendiente'];
  allow update: if
    (request.auth.uid == resource.data.uid          // campista: sus documentos y envío
       && !touchesReviewFields())
    || (isCoordinadorDe(resource.data.bosqueId)      // coordinador: solo la revisión
       && request.auth.uid != resource.data.uid
       && onlyReviewFields())
    || isAdmin();
}
```
Nota: las reglas de lectura no filtran; solo autorizan. Que cada usuario vea solo sus eventos lo resuelve la consulta. Como los eventos no contienen datos sensibles, que sean legibles para todo usuario autenticado es aceptable. Las inscripciones sí están restringidas.

### 5.9 Sub-fases, criterios y prompts

#### 5A: Creación de eventos y pantalla Eventos

Criterios:
- El coordinador solo ve en el selector los tipos actividad, campista por un día y municipal; el admin ve todos.
- El admin puede elegir los bosques de un interzonal.
- Un coordinador que intente crear un departamental por código es rechazado por las reglas.
- Desde esta sub-fase se activa la regla de la Fase 2: el coordinador debe elegir un campamento o actividad al publicar en el feed. El selector muestra los eventos dirigidos a su bosque, incluidos los ya pasados.

Prompt:
> En CampJu (Flutter, Firestore) reemplaza el placeholder del cronograma por la pantalla **Eventos**. Modelo `eventos` con tipos actividad, campista_dia, municipal, interzonal, departamental y nacional, `bosquesIds`, `requiereInscripcion`, `documentosRequeridos`, fechas límite y cupos opcionales. El formulario de creación depende del rol: el coordinador solo crea actividad, campista por un día y municipal, siempre con su bosque; el Super Admin crea todos y elige bosques destinatarios en interzonal. La lista muestra los eventos dirigidos al usuario (consulta por `bosquesIds` array-contains su bosque, más departamental y nacional) con chip de estado de inscripción. Activa además la regla de la Fase 2 que obliga a un coordinador a asociar cada publicación del feed a un evento (`eventoId`), con un selector que lista los eventos dirigidos a su bosque, incluidos los pasados. Actualiza reglas e índices. Sin emojis, íconos de Material por tipo, colores desde `app_theme.dart`. Muestra el plan de archivos antes de codificar.

#### 5B: Inscripción, documentos y aprobación

Criterios:
- Un campista sin bosque no puede inscribirse y recibe una explicación.
- El coordinador rechaza un documento con nota, el campista solo resube ese documento y reenvía.
- El coordinador de otro bosque no puede leer ni aprobar la inscripción.
- El coordinador no puede aprobar su propia inscripción; el Super Admin sí puede.
- Un documento no se puede abrir con un enlace guardado pasados los minutos de vigencia.

Prompt:
> En CampJu implementa inscripciones a eventos. Colección `inscripciones` con id `eventoId_uid`, estados borrador, pendiente, observada, aprobada, rechazada y cancelada, y `documentos` por cada `documentoRequerido`. El campista sube archivos (PDF, JPG, PNG, máximo 5 MB, comprimiendo imágenes) a un bucket **privado** de Supabase con ruta `<eventoId>/<uid>/<docId>`. El coordinador ve las inscripciones pendientes de su bosque, abre cada documento con URL firmada de 5 minutos, marca ok o rechazado con nota, y aprueba solo cuando todos están ok. La aprobación es una transacción que valida cupos e incrementa `aprobadosCount`. El coordinador no puede aprobarse a sí mismo; en ese caso aprueba el Super Admin. El Super Admin puede aprobar cualquiera como respaldo. Actualiza `firestore.rules`. En la pantalla del coordinador separa dos pestañas: "Ingreso al bosque" (Fase 4) e "Inscripciones a eventos". Sin emojis. Primero el plan de archivos.

#### 5C: Agenda

Criterios:
- Un evento con inscripción pendiente no aparece en la Agenda; al aprobarse, aparece sin reiniciar la app.
- Un recordatorio programado suena con la app cerrada.
- Cambiar la hora de un evento actualiza la Agenda de los aprobados.

Prompt:
> En CampJu reemplaza el placeholder del calendario por la pantalla **Agenda**: vista mensual con `table_calendar` y vista de lista por día, zona `America/Bogota`. Muestra solo eventos sin inscripción del bosque del usuario y eventos con inscripción en estado `aprobada`. Detalle con botón "Recordarme" usando `zonedSchedule`. El coordinador ve además los eventos que creó. Streams en tiempo real; sin estado local duplicado. Sin emojis, colores desde el tema. Plan de archivos primero.

#### 5D: Inscritos por municipio y exportación a Excel

Criterios:
- El admin ve los aprobados agrupados por municipio y los totales coinciden con el Excel.
- El coordinador solo exporta su bosque.
- El archivo abre bien en Excel y en Google Sheets, con tildes y ñ correctas.

Prompt:
> En CampJu agrega al Panel de Administración la pantalla "Inscritos" por evento: contadores por estado, agrupación por municipio y luego bosque, filtro por estado (por defecto aprobados) y botón "Exportar Excel". Genera el `.xlsx` en el dispositivo con el paquete `excel` y compártelo con `share_plus`. Hojas: Resumen (municipio, total, desglose por bosque) e Inscritos (municipio, bosque, coordinador, nombre, documento, sexo, nivel, teléfono, estado de documentos, fecha de aprobación), ordenado por municipio, bosque y nombre. Reutiliza el componente para que el coordinador exporte solo su bosque. Solo admin y coordinador del bosque pueden generarlo. Sin emojis. Muestra primero el plan.

---

## Fase 6: Notificaciones y push en segundo plano

Actualizada con el nuevo flujo de campamentos.

### 6.1 Especificación funcional

**Destino de la notificación de un evento nuevo**

| Tipo de evento | Chat del bosque | Notificaciones | Feed | Al tocar |
| :--- | :---: | :---: | :---: | :--- |
| Actividad, campista por un día, municipal | Sí (su bosque) | Sí (miembros) | No | Detalle del evento |
| Interzonal | Sí (cada bosque elegido) | Sí | Sí, como tarjeta | Inscripción |
| Departamental y nacional | Sí (todos los bosques) | Sí (todos) | Sí, como tarjeta | Inscripción |

- En el chat aparece un mensaje automático del sistema con ícono y título del evento, distinto visualmente de los mensajes de personas.
- En el feed aparece una tarjeta con aspecto de publicación, con insignia de evento, título, fechas y botón "Inscribirme". No lleva likes ni comentarios, o se decide aparte si sí.
- Al tocar cualquiera de los tres, se abre la pantalla de inscripción del evento.

**Otros tipos de notificación**

| Tipo | Quién la recibe |
| :--- | :--- |
| `publicacion` | Miembros del bosque emisor (o todos si es de la organización) |
| `comentario` | Autor del post |
| `mensaje` | Miembros del bosque (chat) |
| `evento_nuevo` | Destinatarios según la tabla anterior |
| `inscripcion_pendiente` | Coordinador del bosque (o admin si es un coordinador quien se inscribe) |
| `inscripcion_observada` | Campista, con la nota del coordinador |
| `inscripcion_aprobada` | Campista |
| `inscripcion_rechazada` | Campista, con el motivo |
| `evento_modificado` y `evento_cancelado` | Inscritos pendientes y aprobados |
| `evento_recordatorio` | Solo inscritos aprobados, 24 h y 1 h antes |
| `solicitud_nueva` y `solicitud_resuelta` | Coordinador o solicitante (ingreso al bosque, Fase 4) |
| `rol_cambiado` | Usuario afectado |

- El usuario puede activar o desactivar cada tipo en Preferencias. Las notificaciones de inscripción no deberían poder silenciarse, porque son parte del proceso.
- El badge del dashboard cuenta solo no leídas.
- Tocar una notificación navega a la pantalla correspondiente.

### 6.2 Plan técnico

```
users/{uid}/notificaciones/{id}
  tipo, titulo, cuerpo, leida: bool, createdAt
  ref: { tipo: 'post'|'evento'|'inscripcion'|'solicitud'|'chat', id: string }

bosques/{bosqueId}/mensajes/{id}
  tipo: 'texto' | 'imagen' | 'archivo' | 'sistema_evento'
  eventoId?: string          // si es un mensaje del sistema
  ...

posts/{postId}
  tipo: 'publicacion' | 'evento'
  eventoId?: string          // si es una tarjeta de evento en el feed
```

**Cloud Functions** (necesarias para push con la app cerrada y para repartir a muchos destinatarios):
- `onEventoCreate`: según el tipo, escribe el mensaje del sistema en el chat de cada bosque destinatario, crea la tarjeta en el feed (solo interzonal, departamental y nacional), crea las notificaciones por usuario y envía FCM a los topics `bosque_<id>` o `global`. Para el reparto masivo usa lotes de 500 escrituras.
- `onEventoUpdate`: modificación y cancelación, dirigida a inscritos.
- `onInscripcionWrite`: notifica al coordinador cuando llega una inscripción `pendiente`, y al campista cuando pasa a `observada`, `aprobada` o `rechazada`.
- `scheduleRecordatorios` (Cloud Scheduler cada 15 minutos): recordatorios 24 h y 1 h antes, solo a inscritos aprobados, sin duplicados (marca de recordatorio enviado por evento).
- `onChatMessageCreate`: FCM al topic del bosque, excluyendo al remitente.
- `onLikeWrite` y `onCommentWrite`: mantienen `likesCount` y `commentsCount` (permite endurecer las reglas de la Fase 1).

**Aviso de costo:** Cloud Functions y Cloud Scheduler requieren el plan Blaze de Firebase (pago por uso, con cuota gratuita generosa). Es la decisión que más condiciona esta fase.

**Alternativa sin Blaze:** el reparto lo hace el celular del admin al crear el evento, con escrituras por lotes de 500 (viable con unos cientos de usuarios). Se mantienen el listado interno de notificaciones, el mensaje en el chat, la tarjeta en el feed y los recordatorios locales de la Agenda. Se pierde el push con la app cerrada y los recordatorios automáticos globales. Además, si el admin cierra la app a mitad del reparto, algunos destinatarios no reciben la notificación.

Cliente:
- Suscribir el topic `bosque_<id>` al unirse a un bosque y desuscribir al salir; suscribir a `global` siempre.
- Manejar los tres estados de FCM: primer plano, segundo plano y app cerrada (`getInitialMessage`, `onMessageOpenedApp`).
- Canal de notificaciones de Android con nombre e importancia definidos.

### 6.3 Criterios de aceptación
- El admin crea un departamental; en menos de un minuto llega el mensaje a los chats de todos los bosques, la notificación a todos los usuarios y la tarjeta al feed.
- Tocar la tarjeta, el mensaje del chat o la notificación abre la misma pantalla de inscripción.
- El coordinador crea un campista por un día; solo lo reciben los miembros de su bosque, sin tarjeta en el feed.
- Con la app cerrada en el dispositivo B, la aprobación de una inscripción en el dispositivo A hace sonar B.
- Un campista con inscripción `pendiente` no recibe el recordatorio de 1 h; uno `aprobado` lo recibe una sola vez.

### 6.4 Prompt para la IA
> En CampJu implementa notificaciones completas con el flujo de campamentos. Mueve las notificaciones a `users/{uid}/notificaciones` con `tipo`, `leida` y `ref` para navegar. Crea Cloud Functions (Node/TypeScript): `onEventoCreate` reparte según el tipo del evento: mensaje `sistema_evento` en `bosques/{id}/mensajes` de cada bosque destinatario, tarjeta `tipo: 'evento'` en el feed solo para interzonal, departamental y nacional, notificaciones por usuario en lotes de 500 y FCM a los topics `bosque_<id>` o `global`. Agrega `onEventoUpdate`, `onInscripcionWrite` (avisa al coordinador cuando llega una pendiente y al campista cuando pasa a observada, aprobada o rechazada), recordatorios 24 h y 1 h solo a aprobados con Cloud Scheduler y sin duplicados, y el mantenimiento de `likesCount` y `commentsCount`. En Flutter maneja primer plano, segundo plano y app cerrada, con navegación a la pantalla de inscripción al tocar. Respeta las preferencias por tipo, salvo las de inscripción. Sin emojis en títulos ni cuerpos. Antes de programar, dime qué requiere el plan Blaze y cómo cambiaría el diseño sin él.

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
| Publicar en el feed (visible para todos) | No | Sí, a nombre de su bosque | Sí, como organización |
| Editar, fijar o eliminar publicaciones | No | Editar y eliminar las de su bosque | Todas (y fijar) |
| Solicitar ingreso a bosque | Sí | No aplica | No aplica |
| Aceptar o rechazar ingreso al bosque | No | Su bosque | Todos |
| Crear actividad, campista por un día y municipal | No | Su bosque | Cualquier bosque |
| Crear interzonal, departamental y nacional | No | No | Sí |
| Editar o cancelar eventos | No | Los que él creó | Todos |
| Inscribirse a un evento | Sí (con bosque) | Sí (lo aprueba el admin) | No aplica |
| Revisar documentos y aprobar inscripciones | No | Solo su bosque | Todas (respaldo) |
| Ver documentos de una inscripción | Los suyos | Su bosque | Todos |
| Ver Agenda | Eventos aprobados | Aprobados y los que creó | Los que creó |
| Exportar Excel de inscritos | No | Su bosque | Todos |
| Cambiar roles | No | No | Sí |
| Crear, editar o eliminar bosques | No | No | Sí |
| Chat del bosque | Su bosque | Su bosque | Lectura y moderación |

## Anexo B: Riesgos que debes decidir pronto

1. **Documentos sensibles.** La inscripción implica almacenar copias de identidad, autorizaciones de menores y posiblemente datos de salud. Bucket privado, URLs firmadas, acceso mínimo y política de borrado son obligatorios, no opcionales. Conviene revisar con quien corresponda en el programa el cumplimiento de la ley colombiana de protección de datos personales antes de lanzar. Un error aquí es mucho más grave que cualquier bug de la app.
2. **Cuello de botella en el coordinador.** Todo el sistema descansa en que cada coordinador revise a tiempo. Por eso el Super Admin conserva el respaldo de aprobar cualquier inscripción y existe `fechaLimiteAprobacion`; ajusta los plazos a la realidad de tus coordinadores.
3. **Coordinador que también viaja.** No puede aprobarse a sí mismo; lo revisa el admin. Con muchos coordinadores inscritos, parte del trabajo vuelve al admin. Es una excepción que debes aceptar.
4. **Plan Blaze de Firebase.** Sin él no hay push con la app cerrada, ni recordatorios automáticos, ni contadores a prueba de manipulación, y el reparto masivo de un departamental depende del celular del admin.
5. **Contadores desde el cliente.** Hoy son manipulables por un usuario técnico. Aceptable para un programa comunitario pequeño; moverlos a Cloud Functions cuando se active Blaze.
6. **Dependencia doble de Firebase y Supabase.** Dos proveedores complican reglas y limpieza de archivos. Cada borrado (post, evento, inscripción) debe limpiar ambos lados.
7. **Tema visual.** Si la paleta propuesta tampoco convence, cámbiala en `app_theme.dart` antes de la Fase 2; cambiarla después obliga a revisar pantallas ya hechas.
