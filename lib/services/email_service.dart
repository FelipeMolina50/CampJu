import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static const String smtpHost = 'smtp.gmail.com'; // Cambia si usas otro proveedor
  static const int smtpPort = 587; // 587 para TLS, 465 para SSL
  static const String smtpUsername = 'tuemail@gmail.com'; // Tu email
  static const String smtpPassword = 'tu_app_password'; // App password de Gmail

  static Future<void> sendCustomEmail({
    required String to,
    required String subject,
    required String htmlBody,
  }) async {
    final smtpServer = SmtpServer(
      smtpHost,
      port: smtpPort,
      username: smtpUsername,
      password: smtpPassword,
      ssl: false,
      allowInsecure: false,
    );

    final message = Message()
      ..from = Address(smtpUsername, 'CampJu')
      ..recipients.add(to)
      ..subject = subject
      ..html = htmlBody;

    try {
      final sendReport = await send(message, smtpServer);
      print('Email enviado: $sendReport');
    } catch (e) {
      print('Error enviando email: $e');
      rethrow;
    }
  }

  static String generatePasswordResetHtml(String resetLink, String userName) {
    return '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recupera tu contraseña - CampJu</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 20px; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        .header { text-align: center; padding: 20px 0; }
        .logo { max-width: 150px; }
        .content { padding: 20px; text-align: center; }
        .button { display: inline-block; padding: 12px 24px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 4px; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="https://via.placeholder.com/150x50?text=CampJu+Logo" alt="CampJu Logo" class="logo">
            <h1>Recupera tu contraseña</h1>
        </div>
        <div class="content">
            <p>Hola $userName,</p>
            <p>Hemos recibido una solicitud para restablecer tu contraseña en CampJu.</p>
            <p>Haz clic en el botón de abajo para crear una nueva contraseña:</p>
            <a href="$resetLink" class="button">Restablecer Contraseña</a>
            <p>Si no solicitaste este cambio, ignora este correo.</p>
            <p>Este enlace expirará en 1 hora por seguridad.</p>
        </div>
        <div class="footer">
            <p>© 2024 CampJu. Todos los derechos reservados.</p>
            <p>Si tienes problemas, contáctanos en soporte@campju.com</p>
        </div>
    </div>
</body>
</html>
''';
  }

  static String generateEmailVerificationHtml(String verificationLink, String userName) {
    return '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verifica tu cuenta - CampJu</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 20px; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        .header { text-align: center; padding: 20px 0; }
        .logo { max-width: 150px; }
        .content { padding: 20px; text-align: center; }
        .button { display: inline-block; padding: 12px 24px; background-color: #2196F3; color: white; text-decoration: none; border-radius: 4px; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="https://via.placeholder.com/150x50?text=CampJu+Logo" alt="CampJu Logo" class="logo">
            <h1>Verifica tu cuenta</h1>
        </div>
        <div class="content">
            <p>Hola $userName,</p>
            <p>¡Bienvenido a CampJu! Para completar tu registro, verifica tu dirección de correo electrónico.</p>
            <p>Haz clic en el botón de abajo para verificar tu cuenta:</p>
            <a href="$verificationLink" class="button">Verificar Cuenta</a>
            <p>Si no creaste esta cuenta, ignora este correo.</p>
        </div>
        <div class="footer">
            <p>© 2024 CampJu. Todos los derechos reservados.</p>
            <p>Si tienes problemas, contáctanos en soporte@campju.com</p>
        </div>
    </div>
</body>
</html>
''';
  }
}