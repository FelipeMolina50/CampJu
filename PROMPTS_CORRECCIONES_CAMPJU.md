# CampJu: Prompts de corrección tras las pruebas

Este documento parte de tres pantallazos de la app en un celular real. Cada bloque tiene su diagnóstico, sus criterios de aceptación y un prompt para pegar en la IA que programa. Adjunta también `PLAN_FINALIZACION_CAMPJU.md`: es la especificación de fondo, y estos prompts la concretan (si hay diferencias, mandan estos prompts).

---

## 1. Qué se ve en los pantallazos

**Pantallazo 1 y 3: pestaña Inscripciones del panel de administración**
- Los cuatro contadores (Aprobados, Pendientes, Observadas, Rechazadas) se desbordan: Flutter marca "RIGHT OVERFLOWED BY 38, 40, 44 y 45 PIXELS". El ícono y el texto compiten por el mismo espacio.
- La fila de filtros se corta por la derecha: el chip de Rechazadas no se alcanza a ver y el de Observadas queda partido.
- El botón "Exportar Reporte (Excel / CSV)" aparece gris y no hay ninguna explicación de por qué. Probablemente está deshabilitado porque hay 0 aprobados, lo cual es razonable, pero el usuario no lo sabe.
- El plan pedía agrupar los inscritos por **municipio**; la pantalla solo filtra por estado.
- Errores de texto: "Panel de Administracion" sin tilde; "Lugar: chegua -" con un guion colgando (se concatena un municipio vacío); mezcla de "Aprobados" y "Aprobadas"; "Selecciona un Evento" con mayúsculas innecesarias.
- El evento aparece con "Aprobados: 0 / 20", así que el modelo de cupos existe, pero nadie puede inscribirse todavía, por eso todo está en cero.

**Pantallazo 2: Privacidad y seguridad**
- Seis botones: Términos y Condiciones, Política de Privacidad, Gestión de Datos, Verificación en dos pasos, Dispositivos Activos y Bloqueo de Aplicación. Ninguno funciona hoy.
- La pantalla no tiene título ni barra superior visible: hay un espacio en blanco arriba.

**Causa raíz de todo lo demás:** falta la función de inscribirse a un evento. Sin ella no hay inscripciones que revisar, exportar ni mostrar en la Agenda.

---

## 2. Orden de trabajo recomendado

| Orden | Bloque | Por qué en este lugar |
| :---: | :--- | :--- |
| 1 | **A. Unirse a un evento** (campista y revisión del coordinador) | Bloquea todo lo demás: sin inscripciones no hay datos para el panel, el Excel ni la Agenda |
| 2 | **B. Pestaña Inscripciones del admin** | Los desbordes se pueden arreglar ya; el Excel se prueba de verdad cuando A produzca datos |
| 3 | **C1. Términos, Política y consentimiento** | Base legal de todo lo demás; debe existir antes de guardar documentos de personas reales |
| 4 | **C2. Gestión de datos** | Descarga y eliminación de la cuenta; depende de C1 |
| 5 | **C3. Bloqueo de aplicación** | Barato, útil, no necesita backend |
| 6 | **C4. Dispositivos activos** | Necesita una colección propia; el cierre remoto tiene límites (ver abajo) |
| 7 | **C5. Verificación en dos pasos** | Depende de una decisión de costo en Firebase; conviene dejarla al final |

## 3. Decisiones que debes tomar antes de programar

1. **Retención frente a supresión.** Si un usuario borra su cuenta, ¿el programa necesita conservar un registro mínimo de quién asistió a cada campamento (por seguros, informes o auditoría)? Si sí, hay que conservarlo de forma reducida y decirlo en la política. Si no, se borra todo. Es una decisión del programa, no técnica.
2. **Menores de edad.** Si hay campistas menores, el tratamiento de sus datos y la subida de sus documentos exige una vía de autorización del acudiente. Defínela con el programa; la app puede registrar esa autorización, pero no puede decidir cómo se obtiene.
3. **Verificación en dos pasos.** En Firebase, el segundo factor por SMS solo está disponible si actualizas Authentication a **Identity Platform**, exige correo verificado y los SMS tienen costo (revisa los precios vigentes antes de decidir). Si no quieres esa actualización, es mejor **quitar el botón** hasta que la haya, en lugar de dejar uno que no hace nada.
4. **Formato del reporte.** El prompt B pide Excel (`.xlsx`) como formato principal. Si además quieres CSV, se agrega como opción secundaria.
5. **Plan Blaze.** Sin él, la eliminación de cuenta se hace desde el celular y el cierre de sesión remoto es "cooperativo" y no una revocación real (explicado en C2 y C4).

---

## 4. Contexto común (pegar al inicio de cada prompt)

```text
Proyecto: CampJu, app móvil en Flutter (Dart 3.5.4) con Firebase Auth, Firestore, Firebase Messaging y Supabase Storage. Roles: campista, coordinador y super admin. Hay bosques (grupos) con un coordinador cada uno. Adjunto PLAN_FINALIZACION_CAMPJU.md como especificación; si algo de este prompt la contradice, manda este prompt.

Reglas para todo lo que hagas:
1. Antes de escribir código, revisa los archivos existentes relacionados y dime qué vas a crear o modificar. No cambies nada ajeno a la tarea.
2. Cero emojis en textos, botones, mensajes y datos de ejemplo; usa íconos de Material.
3. Colores, tipografía y espaciado solo desde el tema centralizado (app_theme.dart); nada de Color(0x...) sueltos.
4. Todo texto de interfaz en español correcto, con tildes y ñ, en mayúscula solo al inicio de la frase ("Selecciona un evento", no "Selecciona un Evento").
5. Toda pantalla debe tener estados de carga, vacío y error diseñados, y funcionar en pantallas angostas sin desbordes (prueba con ancho de 360 dp y con la fuente del sistema al 130 por ciento).
6. Los permisos se aplican en firestore.rules y en las reglas de Supabase, no solo escondiendo botones en la interfaz. Actualiza firestore.rules e índices cuando corresponda.
7. Usa StreamBuilder o snapshots() para datos en tiempo real; no dupliques estado local que compita con Firestore.
8. Al terminar: flutter analyze sin errores y una lista de pruebas manuales que yo pueda repetir con dos cuentas.
```

---

## Bloque A. Unirse a un evento (campista y coordinador)

### Criterios de aceptación
- Un campista con bosque abre un evento, ve los documentos requeridos, los sube y envía la inscripción.
- Su coordinador la recibe, revisa cada documento, la observa o la aprueba.
- Al aprobarse, el contador "Aprobados: n / cupo" del panel de admin sube y el evento pasa a la Agenda del campista.
- Un campista sin bosque no puede inscribirse y recibe una explicación clara.
- Un coordinador de otro bosque no puede leer ni aprobar esa inscripción.
- Un coordinador no puede aprobar su propia inscripción; el super admin sí puede aprobarla.
- Los documentos no son accesibles con un enlace guardado pasados unos minutos.

### Prompt A

```text
[Pegar aquí el contexto común]

TAREA: implementar la función de unirse (inscribirse) a un evento o campamento, incluyendo la revisión del coordinador. Hoy los eventos ya se crean (por ejemplo "Campamento municipal", tipo municipal, cupo 20, visible en el panel del admin con "Aprobados 0 / 20"), pero un campista no puede inscribirse.

Sigue las secciones 5.2 a 5.5 del PLAN adjunto. Concretamente:

PARTE 1. Campista
1. En la pantalla Eventos, cada evento lleva un chip con el estado de mi inscripción: sin inscribirme, borrador, pendiente, observada, aprobada, rechazada o cancelada.
2. Al tocar un evento se abre el detalle: título, tipo, fechas, lugar (solo muestra el municipio si existe; sin guiones sobrantes), cupos disponibles, fecha límite y la lista de documentos requeridos. Un botón principal cambia según el estado: "Inscribirme", "Continuar inscripción", "En revisión" (deshabilitado), "Corregir documentos", "Inscrito" y "Cancelar inscripción" como acción secundaria.
3. Comprueba antes de inscribir: que el usuario tenga bosque (si no, explica y ofrece "Buscar bosque"), que el evento esté abierto, que no haya pasado la fecha límite y que queden cupos.
4. Pantalla de documentos: una fila por documento requerido, con estado (falta, subido, correcto, rechazado con la nota del coordinador), botón para elegir archivo (PDF, JPG o PNG, máximo 5 MB, comprimiendo imágenes) y vista previa. Antes de subir el primer documento, casilla obligatoria de autorización de tratamiento de datos con enlace a la Política de Privacidad; guarda la fecha en la inscripción (autorizacionDatosAt).
5. Al enviar, la inscripción pasa a pendiente. Si el coordinador la observa, el campista solo vuelve a subir los documentos rechazados y reenvía.

PARTE 2. Coordinador
1. En su pantalla de bosque, una pestaña "Inscripciones a eventos", separada de las solicitudes de ingreso al bosque, con las inscripciones pendientes de SU bosque, filtro por evento y por estado.
2. Al abrir una inscripción, ve los datos del campista y cada documento. Abre cada archivo con una URL firmada de 5 minutos, y marca cada documento como correcto o rechazado con una nota corta.
3. Aprobar solo se habilita cuando todos los documentos obligatorios están correctos. Aprobar es una TRANSACCIÓN que revalida el cupo, cambia el estado, incrementa aprobadosCount del evento, y registra revisadoPor y revisadoAt. Si algún documento está rechazado, el botón cambia a "Devolver con observaciones" (estado observada). También puede rechazar definitivamente con motivo.
4. Si quien se inscribe es un coordinador, no puede aprobarse a sí mismo: su inscripción aparece en la bandeja del super admin. El super admin puede aprobar cualquier inscripción como respaldo.

PARTE 3. Datos, seguridad y reglas
- Colección inscripciones con id "eventoId_uid" (una por usuario y evento). Campos: eventoId, uid, bosqueId, copia de los datos del campista (nombre, documento, municipio, sexo, nivel, teléfono), estado, documentos { docId: { path, estado, nota } }, motivo, revisadoPor, revisadoAt, autorizacionDatosAt, createdAt, updatedAt.
- El formulario de creación de eventos debe permitir definir documentosRequeridos (nombre y si es obligatorio), la fecha límite de inscripción y el cupo. Si ya existen, reutilízalos; si no, agrégalos.
- Documentos en un bucket PRIVADO de Supabase con ruta <eventoId>/<uid>/<docId>. Nunca URLs públicas. Solo pueden leerlos el propio campista, el coordinador de su bosque y el super admin.
- firestore.rules: el campista crea y edita solo su inscripción y no puede tocar los campos de revisión; el coordinador solo cambia los campos de revisión de inscripciones de su bosque y nunca de la suya; el admin puede todo. Un usuario sin bosque no puede crear inscripciones.
- Cuando el estado cambie, genera una notificación al destinatario (coordinador al llegar una pendiente; campista al pasar a observada, aprobada o rechazada) con el servicio de notificaciones existente. Si el evento ya tiene pantalla de Agenda, un evento con inscripción aprobada debe aparecer allí; si no, deja la consulta lista.
- Índices necesarios: inscripciones por eventoId + estado + municipio, y por bosqueId + estado + createdAt.

Entrega: plan de archivos primero, luego el código, luego las pruebas manuales con tres cuentas (campista, coordinador y super admin).
```

---

## Bloque B. Pestaña Inscripciones del panel de administración

### Criterios de aceptación
- Ninguna pantalla muestra "RIGHT OVERFLOWED" con ancho de 360 dp y fuente al 130 por ciento.
- Los cuatro estados (Aprobadas, Pendientes, Observadas, Rechazadas) se ven completos y se pueden filtrar.
- Los inscritos se ven agrupados por municipio y luego por bosque, con totales.
- "Exportar Excel" genera un `.xlsx` real y se abre bien en Excel y en Google Sheets con tildes y ñ.
- Si no hay aprobadas, el botón está deshabilitado y dice por qué.
- El super admin puede abrir una inscripción y aprobarla como respaldo.

### Prompt B

```text
[Pegar aquí el contexto común]

TAREA: rediseñar y hacer funcional la pestaña "Inscripciones" del Panel de Administración (solo super admin). Debe funcionar con los datos que produce el Bloque A. Sigue la sección 5.7 del PLAN adjunto.

PROBLEMAS ACTUALES A CORREGIR
1. Los cuatro contadores se desbordan ("RIGHT OVERFLOWED BY 38 PIXELS" y similares) porque ícono y texto van en un Row sin Flexible. Muéstralos en una cuadrícula de 2 por 2 (o un Wrap adaptable). Cada tarjeta tiene el número grande, la etiqueta en una sola línea con ellipsis y un ícono pequeño alineado al número, no a la etiqueta.
2. La fila de filtros por estado se corta. Hazla desplazable horizontalmente o usa un control segmentado adaptable. Incluye siempre los cuatro estados con su conteo. Usa género femenino de forma consistente: Aprobadas, Pendientes, Observadas, Rechazadas.
3. El título dice "Panel de Administracion": corrígelo a "Panel de administración". Cambia "Selecciona un Evento para ver Inscritos y Reportes" por "Selecciona un evento para ver inscritos y reportes".
4. En las tarjetas de evento, "Lugar: chegua -" trae un guion sobrante. Construye el texto con el lugar y agrega el municipio solo si existe. Capitaliza el nombre del lugar.
5. El botón "Exportar Reporte (Excel / CSV)" está gris sin explicación. Reemplázalo por "Exportar Excel": habilitado si hay al menos una inscripción aprobada; si no, deshabilitado con un texto de ayuda debajo ("Aún no hay inscripciones aprobadas para exportar"). Ofrece CSV solo como opción secundaria en un menú, si no complica.

FUNCIONALIDAD
6. Lista de eventos: cada tarjeta muestra título, chip de tipo, fecha, lugar y contadores "Aprobadas n / cupo" y "Pendientes n". Ordenados por fecha. Obtén los conteos con consultas de agregación count() o streams ligeros; no descargues todas las inscripciones solo para contar.
7. Detalle del evento: contadores por estado, filtro por estado (por defecto Aprobadas) y agrupación por MUNICIPIO y dentro por bosque, con ExpansionTile y el total de cada grupo.
8. Cada inscripción muestra nombre, bosque, municipio, chip de estado y avance de documentos (por ejemplo 3 de 4). Al tocarla, abre el detalle, donde el super admin puede ver los documentos con URL firmada de 5 minutos y aprobar o devolver como respaldo del coordinador.
9. Exportación .xlsx generada en el dispositivo con el paquete excel y compartida con share_plus. Hoja "Resumen": una fila por municipio con total y desglose por bosque. Hoja "Inscritos": municipio, bosque, coordinador, nombre completo, documento, sexo, nivel, teléfono, estado de documentos y fecha de aprobación, ordenado por municipio, bosque y nombre. Exporta solo las aprobadas a menos que el filtro activo indique otra cosa. Nombre de archivo: campamento_<evento>_<fecha>.xlsx.
10. Estados vacíos con ícono y texto útil ("No hay inscripciones observadas en este evento"), pull-to-refresh, indicador de carga y estado de error con botón "Reintentar".
11. Acceso solo para super admin (la ruta valida el rol al entrar). Reutiliza la vista de inscritos y la exportación para el coordinador, limitadas a su bosque, dentro de su pestaña de inscripciones.

Entrega: plan de archivos primero, luego el código, y una lista de pruebas manuales que incluya el caso de ancho 360 dp con fuente al 130 por ciento.
```

---

## Bloque C. Privacidad y seguridad

Aplica a toda la pantalla: agrega un título y una barra superior ("Privacidad y seguridad") con el mismo estilo que el resto de la app, y ninguno de los seis botones puede quedar como placeholder.

### C1. Términos y Condiciones, Política de Privacidad y consentimiento

**Criterios de aceptación**
- Ambas pantallas muestran el texto con versión y fecha, y se pueden leer completas con desplazamiento.
- Nadie puede crear cuenta sin aceptar ambos documentos; queda registrada la versión y la fecha.
- Si publicas una versión nueva, los usuarios existentes deben aceptarla antes de seguir usando la app.

**Aviso importante:** el texto legal lo debe revisar alguien competente. Yo no soy abogado. El prompt le pide a la IA un **borrador** marcado como tal; no lo publiques sin revisión. Como referencia, en Colombia aplica la Ley 1581 de 2012 de protección de datos personales, que reconoce al titular derechos como conocer, actualizar, rectificar y suprimir sus datos y revocar su autorización.

```text
[Pegar aquí el contexto común]

TAREA: hacer funcionales "Términos y Condiciones" y "Política de Privacidad" en Privacidad y seguridad, con registro de consentimiento.

1. Guarda los textos como Markdown en assets/legal/terminos_v1.md y assets/legal/politica_privacidad_v1.md, y muéstralos con flutter_markdown en pantallas con título, "Versión 1.0 - actualizada el <fecha>" y desplazamiento. Las versiones viven en una constante central (kTerminosVersion, kPoliticaVersion).
2. Redacta un BORRADOR de ambos textos, con un banner interno "Borrador pendiente de revisión legal" controlado por la constante kLegalReviewed (false por ahora). La política debe describir lo que la app realmente hace: datos que se recogen (nombre, correo, documento, municipio, sexo, teléfono, foto, nivel en el programa, documentos subidos para inscribirse a eventos, mensajes y publicaciones), finalidades, dónde se almacenan (Firebase de Google y Supabase), quién puede ver cada dato (el propio usuario, su coordinador y el administrador), tiempo de conservación, tratamiento de datos de menores y de datos sensibles como los de salud, derechos del titular según la Ley 1581 de 2012 (conocer, actualizar, rectificar, suprimir, revocar la autorización y presentar quejas ante la Superintendencia de Industria y Comercio), y un canal de contacto (déjalo como constante configurable).
3. Consentimiento: en el registro y en el onboarding de Google Sign-In, casilla obligatoria "Acepto los Términos y Condiciones y la Política de Privacidad" con ambos enlaces. Guarda en users/{uid} el mapa consentimiento { terminosVersion, politicaVersion, aceptadoAt }.
4. Re-consentimiento: si la versión guardada es menor que la vigente, muestra una pantalla bloqueante para aceptar antes de entrar a la app.
5. firestore.rules: el usuario puede escribir su propio consentimiento pero no eliminarlo.

Entrega: plan de archivos, código y pruebas manuales (registro nuevo, usuario existente ante una versión nueva).
```

### C2. Gestión de datos

**Criterios de aceptación**
- El usuario ve qué datos suyos guarda la app y puede descargarlos en un archivo.
- Puede corregir sus datos (menos rol y bosque).
- Puede eliminar su cuenta con confirmación y reautenticación; después no queda su información personal ni sus documentos.
- Un coordinador o el único admin no puede eliminar su cuenta sin antes entregar el cargo.

```text
[Pegar aquí el contexto común]

TAREA: hacer funcional "Gestión de datos" en Privacidad y seguridad, con cuatro acciones.

1. "Mis datos": pantalla de solo lectura con el perfil, el bosque, las inscripciones (evento, estado, fecha) y la lista de documentos subidos (nombres, sin enlaces).
2. "Descargar mis datos": genera en el dispositivo un archivo JSON con el perfil, las inscripciones, las preferencias y el consentimiento, y lo comparte con share_plus. Exige reautenticación reciente antes de generarlo.
3. "Corregir mis datos": lleva a la edición de perfil existente. El rol y el bosque no son editables por el usuario (las reglas ya lo impiden).
4. "Eliminar mi cuenta":
   - Explica con claridad qué se borra y qué se conserva.
   - Bloquea la acción, con un mensaje claro, si el usuario es coordinador de un bosque (debe reasignarse primero) o si es el único super admin.
   - Pide escribir ELIMINAR y reautenticar (contraseña o Google).
   - Orden de operaciones: 1) borrar sus archivos en Supabase (documentos de inscripciones y foto de perfil); 2) borrar sus inscripciones; 3) sacarlo del bosque con una transacción que decremente miembrosCount; 4) borrar sus subcolecciones de notificaciones y dispositivos; 5) eliminar sus likes (agrega un campo uid a los documentos de likes para poder usar collectionGroup) y anonimizar sus comentarios ("Usuario eliminado", sin foto); 6) borrar users/{uid}; 7) por último, FirebaseAuth.currentUser.delete(). Si un paso falla, no borres el siguiente y muestra un error con opción de reintentar.
   - Si el proyecto tiene Cloud Functions, prefiere hacer todo el borrado en el servidor con una función invocable y dejar el cliente solo con la confirmación.
   - Si el programa necesita conservar un registro mínimo de asistencia a campamentos (decisión pendiente, déjala como constante kConservarRegistroAsistencia), conserva solo evento, fecha y bosque, sin datos personales, y dilo en la pantalla.

Entrega: plan de archivos, código y pruebas manuales, incluyendo el caso del coordinador que intenta eliminarse.
```

### C3. Bloqueo de aplicación

**Criterios de aceptación**
- El usuario puede activar o desactivar el bloqueo, elegir en cuánto tiempo se activa y desbloquear con huella, rostro o el PIN o patrón del teléfono.
- Al volver a la app tras el tiempo elegido, se pide desbloqueo antes de mostrar cualquier contenido.
- Tras varios intentos fallidos se cierra la sesión.

```text
[Pegar aquí el contexto común]

TAREA: hacer funcional "Bloqueo de aplicación" en Privacidad y seguridad, sin backend.

1. Usa local_auth con biometría y credencial del dispositivo como respaldo (biometricOnly: false), para no crear ni guardar un PIN propio. Configura Android: MainActivity debe extender FlutterFragmentActivity y agrega el permiso USE_BIOMETRIC en el manifiesto.
2. Pantalla de ajustes: interruptor "Bloquear la aplicación" (solo se puede activar tras una autenticación exitosa y si el dispositivo tiene una credencial configurada; si no, explica cómo hacerlo) y selector de tiempo: inmediato, 30 segundos, 1 minuto o 5 minutos.
3. Guarda la configuración con flutter_secure_storage (por dispositivo, no en Firestore).
4. Con WidgetsBindingObserver, guarda la hora en que la app pasa a segundo plano. Al volver, si pasó el tiempo elegido, muestra una pantalla de bloqueo que cubre toda la interfaz (también en el selector de apps recientes, con una vista neutra) hasta autenticar.
5. Tras 5 intentos fallidos, cierra la sesión de Firebase y vuelve al login.
6. Opcional: en las pantallas que muestran documentos de identidad, activa FLAG_SECURE para bloquear capturas de pantalla.
7. Evita estados donde el usuario quede atrapado (por ejemplo, si borró su credencial del teléfono): permite entrar cerrando sesión.

Entrega: plan de archivos, código y pruebas manuales (bloqueo inmediato, con tiempo, intentos fallidos, cambiar de app y volver).
```

### C4. Dispositivos activos

**Límites que debes conocer.** Firebase Auth no ofrece una lista de sesiones. La solución práctica es llevar una colección propia de dispositivos. Cerrar sesión en otro dispositivo de forma **cooperativa** (el otro dispositivo detecta que fue revocado y se cierra solo) funciona sin backend, pero no invalida de verdad el token: alguien con acceso técnico al otro dispositivo podría seguir hasta que el token expire. La revocación real de tokens requiere el Admin SDK, o sea Cloud Functions (plan Blaze).

**Criterios de aceptación**
- La pantalla muestra los dispositivos con modelo, plataforma, último acceso y una etiqueta "Este dispositivo".
- "Cerrar sesión" en otro dispositivo lo desconecta en segundos si tiene la app abierta, y al abrirla si no.
- "Cerrar sesión en todos los demás" funciona igual.

```text
[Pegar aquí el contexto común]

TAREA: hacer funcional "Dispositivos activos" en Privacidad y seguridad.

1. Colección users/{uid}/dispositivos/{deviceId}: modelo, plataforma, versionApp, ultimoAcceso, createdAt, fcmToken, revocado (bool). El deviceId es un UUID generado una vez por instalación y guardado en flutter_secure_storage; el modelo sale de device_info_plus. No guardes la IP ni datos innecesarios.
2. Al iniciar sesión, registra o actualiza el documento del dispositivo. Actualiza ultimoAcceso al abrir la app, como máximo una vez cada 15 minutos.
3. Pantalla: lista ordenada por último acceso con ícono por plataforma, etiqueta "Este dispositivo" y botón "Cerrar sesión" en cada uno de los demás, más "Cerrar sesión en todos los demás" con confirmación.
4. Cerrar sesión en otro dispositivo marca revocado: true. Cada instalación escucha su propio documento con un stream; si detecta revocado o que fue eliminado, hace signOut, borra su fcmToken y vuelve al login con un aviso.
5. Al cerrar sesión normalmente, elimina el documento del dispositivo y su token FCM.
6. firestore.rules: cada usuario solo lee y escribe sus propios dispositivos.
7. Si el proyecto ya tiene Cloud Functions, agrega una función invocable que llame revokeRefreshTokens(uid) para una revocación real, y explícame cómo desplegarla. Si no las tiene, deja la revocación cooperativa y dime claramente cuál es su limitación.

Entrega: plan de archivos, código y pruebas manuales con dos dispositivos.
```

### C5. Verificación en dos pasos

**Precondiciones (verificadas en la documentación de Firebase para Flutter)**
- Authentication debe estar actualizado a **Identity Platform**.
- Hay que activar "SMS Multi-factor Authentication" en Authentication, Sign-in method, Avanzado.
- El correo del usuario debe estar verificado antes de poder inscribir un segundo factor.
- En Android, el hash SHA-256 de la app debe estar registrado en la consola de Firebase.
- Es recomendable registrar números de prueba para no ser bloqueado por límite de intentos durante el desarrollo.

**Recomendación de diseño:** opcional para campistas y **obligatoria para coordinadores y super admin**, porque son quienes acceden a documentos de identidad y a datos de salud de otras personas.

**Riesgo:** si un usuario pierde su teléfono, queda bloqueado. Desde el cliente no se puede quitar un segundo factor ajeno; el super admin tendría que resolverlo en la consola de Firebase o con una función que use el Admin SDK. Define ese procedimiento antes de hacer obligatorio el segundo factor.

**Criterios de aceptación**
- Un usuario con correo verificado puede activar el segundo factor con su número (+57 y el número) y un código SMS.
- Al iniciar sesión, si tiene el segundo factor, la app pide el código antes de entrar; funciona también con Google Sign-In.
- Puede desactivarlo desde la misma pantalla, tras reautenticar.
- Un coordinador o admin sin segundo factor ve un aviso y, pasado el plazo definido, no puede acceder a funciones sensibles (revisión de documentos, panel de admin).

```text
[Pegar aquí el contexto común]

PRECONDICIÓN: confirmo que Authentication ya está actualizado a Identity Platform y que SMS Multi-factor Authentication está activado en la consola. Si esto no está hecho, dímelo y no implementes nada; en ese caso oculta el botón "Verificación en dos pasos".

TAREA: hacer funcional "Verificación en dos pasos" en Privacidad y seguridad, con segundo factor por SMS de Firebase Auth.

1. Pantalla de estado: indica si está activado y con qué número (enmascarado: +57 *** *** 1234). Botones "Activar" y "Desactivar".
2. Activar: exige correo verificado (si no, ofrece reenviar la verificación); reautentica al usuario; pide el número en formato internacional con selector de país (+57 por defecto); usa user.multiFactor.getSession() y verifyPhoneNumber con multiFactorSession; pide el código de 6 dígitos y completa con user.multiFactor.enroll(PhoneMultiFactorGenerator.getAssertion(...), displayName: ...). Maneja tiempos de espera, reenvío del código y errores con mensajes claros en español.
3. Inicio de sesión (correo/contraseña y Google): captura FirebaseAuthMultiFactorException, usa e.resolver para pedir el código del hint inscrito y llamar resolver.resolveSignIn. Pantalla de código con reenvío y contador.
4. Desactivar: tras reautenticar, user.multiFactor.unenroll(...).
5. Política por rol: para coordinador y super admin, muestra un aviso persistente si no tienen segundo factor y, pasado el plazo definido en una constante (kPlazoMfaDias), restringe las pantallas sensibles hasta que lo activen. Comprueba el segundo factor con el token (firebase claim sign_in_second_factor) y no solo con la interfaz.
6. No guardes el número en texto claro fuera de lo que Firebase ya administra.

Entrega: plan de archivos, código, pasos exactos de configuración en la consola de Firebase y pruebas manuales (activar, iniciar sesión con segundo factor, desactivar, código incorrecto, teléfono sin cobertura).
```

---

## 5. Verificación final del conjunto

1. Recorre con tres cuentas (campista, coordinador, super admin) el ciclo completo: crear evento, inscribirse, subir documentos, observar, corregir, aprobar y ver el evento en la Agenda.
2. Como super admin, exporta el Excel y comprueba que los totales por municipio coinciden con la pantalla.
3. Intenta desde la consola de reglas de Firestore que un coordinador ajeno lea una inscripción y que un campista modifique su propio estado a "aprobada". Ambas deben fallar.
4. Activa el bloqueo de aplicación, cambia de app y vuelve.
5. Elimina una cuenta de prueba y confirma en Firestore y en Supabase que no quedan sus datos ni sus archivos.
6. Busca en `lib/` emojis y colores fuera del tema.
