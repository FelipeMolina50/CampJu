import 'package:flutter/material.dart';

/// Fondo temático de campamento estilo WhatsApp (patrón de carpas, fogatas, pinos, montañas y estrellas)
class CampingChatBackground extends StatelessWidget {
  final Widget child;

  const CampingChatBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7ECE6), // Tono pergamino bosque suave
      child: CustomPaint(
        painter: const _CampingDoodlePainter(),
        child: child,
      ),
    );
  }
}

class _CampingDoodlePainter extends CustomPainter {
  const _CampingDoodlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B4D3E).withOpacity( 0.085)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF1B4D3E).withOpacity( 0.04)
      ..style = PaintingStyle.fill;

    const cellW = 90.0;
    const cellH = 90.0;
    final cols = (size.width / cellW).ceil() + 1;
    final rows = (size.height / cellH).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final offsetX = c * cellW + ((r % 2 == 1) ? cellW / 2 : 0);
        final offsetY = r * cellH;

        canvas.save();
        canvas.translate(offsetX, offsetY);

        // Alternar diferentes ilustraciones según la celda
        final itemType = (r * 3 + c * 2) % 5;
        switch (itemType) {
          case 0:
            _drawCarpa(canvas, paint, fillPaint);
            break;
          case 1:
            _drawPino(canvas, paint, fillPaint);
            break;
          case 2:
            _drawFogata(canvas, paint);
            break;
          case 3:
            _drawMontana(canvas, paint, fillPaint);
            break;
          case 4:
            _drawEstrella(canvas, paint);
            break;
        }

        canvas.restore();
      }
    }
  }

  // 1. DIBUJO DE CARPA (TENT) ⛺
  void _drawCarpa(Canvas canvas, Paint stroke, Paint fill) {
    final path = Path();
    // Silueta de carpa triangular
    path.moveTo(15, 45);
    path.lineTo(35, 18);
    path.lineTo(55, 45);
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    // Entrada de la carpa (solapas abiertas)
    final flap = Path();
    flap.moveTo(35, 18);
    flap.lineTo(35, 45);
    canvas.drawPath(flap, stroke);

    final leftFlap = Path();
    leftFlap.moveTo(25, 45);
    leftFlap.lineTo(35, 26);
    leftFlap.lineTo(45, 45);
    canvas.drawPath(leftFlap, stroke);

    // Estacas / vientos
    canvas.drawLine(const Offset(15, 45), const Offset(9, 48), stroke);
    canvas.drawLine(const Offset(55, 45), const Offset(61, 48), stroke);
  }

  // 2. DIBUJO DE PINO (TREE) 🌲
  void _drawPino(Canvas canvas, Paint stroke, Paint fill) {
    final path = Path();
    // Nivel superior
    path.moveTo(35, 16);
    path.lineTo(43, 26);
    path.lineTo(39, 26);
    // Nivel medio
    path.lineTo(47, 36);
    path.lineTo(42, 36);
    // Nivel base
    path.lineTo(51, 46);
    path.lineTo(19, 46);
    path.lineTo(28, 36);
    path.lineTo(23, 36);
    path.lineTo(31, 26);
    path.lineTo(27, 26);
    path.close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    // Tronco
    final tronco = Path();
    tronco.moveTo(32, 46);
    tronco.lineTo(32, 52);
    tronco.lineTo(38, 52);
    tronco.lineTo(38, 46);
    canvas.drawPath(tronco, stroke);
  }

  // 3. DIBUJO DE FOGATA (CAMPFIRE) 🔥
  void _drawFogata(Canvas canvas, Paint stroke) {
    // Leña cruzada
    canvas.drawLine(const Offset(22, 46), const Offset(48, 40), stroke);
    canvas.drawLine(const Offset(22, 40), const Offset(48, 46), stroke);

    // Llama central
    final llama = Path();
    llama.moveTo(35, 20);
    llama.cubicTo(43, 27, 43, 37, 35, 41);
    llama.cubicTo(27, 37, 27, 27, 35, 20);
    canvas.drawPath(llama, stroke);

    // Pequeña chispa
    canvas.drawCircle(const Offset(38, 14), 1.4, stroke);
    canvas.drawCircle(const Offset(31, 12), 1.0, stroke);
  }

  // 4. DIBUJO DE MONTAÑAS (MOUNTAINS) 🏔️
  void _drawMontana(Canvas canvas, Paint stroke, Paint fill) {
    final path = Path();
    // Pico grande
    path.moveTo(16, 48);
    path.lineTo(34, 20);
    path.lineTo(52, 48);
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    // Nieve en la cumbre
    final nieve = Path();
    nieve.moveTo(30, 27);
    nieve.lineTo(34, 30);
    nieve.lineTo(38, 27);
    canvas.drawPath(nieve, stroke);

    // Pico pequeño lateral
    final pico2 = Path();
    pico2.moveTo(39, 48);
    pico2.lineTo(48, 30);
    pico2.lineTo(58, 48);
    canvas.drawPath(pico2, stroke);
  }

  // 5. DIBUJO DE ESTRELLA DE ORIENTACIÓN / CAMPING ✨
  void _drawEstrella(Canvas canvas, Paint stroke) {
    const cx = 35.0;
    const cy = 35.0;

    final star = Path();
    // Estrella 4 puntas scout
    star.moveTo(cx, cy - 14);
    star.quadraticBezierTo(cx, cy, cx + 14, cy);
    star.quadraticBezierTo(cx, cy, cx, cy + 14);
    star.quadraticBezierTo(cx, cy, cx - 14, cy);
    star.quadraticBezierTo(cx, cy, cx, cy - 14);
    canvas.drawPath(star, stroke);

    // Punto central
    canvas.drawCircle(const Offset(cx, cy), 1.5, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
