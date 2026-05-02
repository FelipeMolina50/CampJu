import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Términos y Condiciones de Uso',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aplicación Móvil CampJu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              _sectionTitle('1. ACEPTACIÓN DE LOS TÉRMINOS'),
              _sectionText(
                  'Al registrarte y usar la aplicación CampJu, aceptas estos Términos y Condiciones. Si eres menor de edad, debes contar con la autorización de tu padre, madre o acudiente para usar esta aplicación.'),
              _sectionTitle('2. ¿QUÉ ES CAMPJU?'),
              _sectionText(
                  'CampJu es una aplicación móvil desarrollada por estudiantes de Ingeniería de Sistemas y Computación de la Universidad de Cundinamarca, con el objetivo de optimizar la gestión y experiencia de los integrantes del programa Campamentos Juveniles en el Valle de Ubaté. La app permite a los campistas acceder a información de eventos, cursos, su perfil personal y comunicarse con su bosque y coordinadores.'),
              _sectionTitle('3. USUARIOS Y ROLES'),
              _sectionText(
                  'CampJu reconoce tres tipos de usuarios: Campista, Coordinador y Administrador. Cada rol tiene acceso diferenciado a las funcionalidades de la aplicación. El administrador asignará el rol correspondiente a cada usuario luego del registro.'),
              _sectionTitle('4. REGISTRO Y CUENTA'),
              _sectionText(
                  'Para usar CampJu debes proporcionar un correo electrónico válido y verificarlo, crear una contraseña segura y aceptar estos términos al momento del registro. Eres responsable de mantener la confidencialidad de tu cuenta. Si detectas un uso no autorizado, debes reportarlo de inmediato a los administradores.'),
              _sectionTitle('5. TRATAMIENTO DE DATOS PERSONALES'),
              _sectionText(
                  'De acuerdo con la Ley 1581 de 2012 y el Decreto 1377 de 2013, CampJu recopila y trata datos personales únicamente con los siguientes fines: gestión de inscripciones a eventos del programa, seguimiento del proceso campamentil de cada usuario, comunicación sobre actividades y novedades del programa y asignación de roles y bosques dentro de la aplicación.'),
              _sectionText(
                  'Los datos recopilados incluyen: nombre, correo electrónico, foto de perfil, bosque asignado y registro de actividades. Si el usuario es menor de edad, el tratamiento de sus datos requiere autorización previa de sus padres o acudientes, conforme al Código de Infancia y Adolescencia (Ley 1098 de 2006, art. 47) y el Decreto 1377 de 2013. Los datos NO serán compartidos con terceros ni usados con fines distintos al programa Campamentos Juveniles.'),
              _sectionTitle('6. PROTECCIÓN DE MENORES DE EDAD'),
              _sectionText(
                  'Dado que la mayoría de los campistas son menores de edad, CampJu implementa las siguientes medidas: verificación de correo electrónico obligatoria al registrarse, asignación de rol por parte del administrador antes de acceder a todas las funcionalidades, almacenamiento seguro de datos personales mediante Firebase (plataforma de Google) y prohibición de compartir información personal sensible a través de los chats de la aplicación.'),
              _sectionTitle('7. USO ACEPTABLE'),
              _sectionText(
                  'Al usar CampJu te comprometes a usar la aplicación únicamente con fines relacionados al programa Campamentos Juveniles, no publicar contenido ofensivo, violento o inapropiado, no suplantar la identidad de otro campista o coordinador y no intentar acceder a funcionalidades de otros roles sin autorización. El incumplimiento de estas normas puede resultar en la suspensión o eliminación de tu cuenta.'),
              _sectionTitle('8. PROPIEDAD INTELECTUAL'),
              _sectionText(
                  'CampJu y todos sus contenidos (diseño, código, logos, textos) son propiedad de sus desarrolladores y del programa Campamentos Juveniles del Valle de Ubaté. Queda prohibida su reproducción o uso sin autorización.'),
              _sectionTitle('9. DISPONIBILIDAD DEL SERVICIO'),
              _sectionText(
                  'CampJu es una aplicación en desarrollo activo. El equipo se reserva el derecho de realizar actualizaciones, mantenimientos o modificaciones en cualquier momento. No garantizamos disponibilidad ininterrumpida del servicio.'),
              _sectionTitle('10. MARCO LEGAL APLICABLE'),
              _sectionText(
                  'Estos términos se rigen por la Constitución Política de Colombia (1991, art. 45), Ley de Juventud (1997, art. 5), Código de Infancia y Adolescencia (2006, art. 41 y 47), Ley 1581 de 2012 – Protección de Datos Personales, Decreto 1377 de 2013, Ley 1341 de 2009 – Ley de TIC, Resolución No. 091 de 2023 – Universidad de Cundinamarca y Resolución No. 285 del Ministerio del Deporte (2024).'),
              _sectionTitle('11. CONTACTO'),
              _sectionText(
                  'Para dudas, solicitudes o reportes relacionados con el uso de tus datos o el funcionamiento de la app, puedes escribirnos a: campju.app@gmail.com.'),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Al tocar "Acepto los Términos y Condiciones" confirmas que has leído, entendido y aceptado todo lo anterior.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.6,
      ),
      textAlign: TextAlign.justify,
    );
  }
}
