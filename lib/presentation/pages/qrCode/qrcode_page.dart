import 'package:flutter/material.dart';

import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';

class QrCodePage extends StatelessWidget {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      appBar: AppBar(title: const Text('Escanear QR Code')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            const SizedBox(height: 20),

            // ======================================================
            // TÍTULO
            // ======================================================
            const Text(
              'Escaneie o QR Code do ativo',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Posicione o QR Code dentro da área de leitura.',

              textAlign: TextAlign.center,

              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),

            const SizedBox(height: 32),

            // ======================================================
            // ÁREA DO SCANNER
            // ======================================================
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxWidth: 320,
                    maxHeight: 320,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Stack(
                    alignment: Alignment.center,

                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 180,
                      ),

                      // Cantos da área de leitura
                      Positioned(
                        top: 30,
                        left: 30,

                        child: _ScannerCorner(top: true, left: true),
                      ),

                      Positioned(
                        top: 30,
                        right: 30,

                        child: _ScannerCorner(top: true, left: false),
                      ),

                      Positioned(
                        bottom: 30,
                        left: 30,

                        child: _ScannerCorner(top: false, left: true),
                      ),

                      Positioned(
                        bottom: 30,
                        right: 30,

                        child: _ScannerCorner(top: false, left: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ======================================================
            // INFORMAÇÃO
            // ======================================================
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: AppColors.mainColorLight,

                borderRadius: BorderRadius.circular(8),

                border: Border.all(color: AppColors.borderColor),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.mainColor,
                    size: 22,
                  ),

                  const SizedBox(width: 10),

                  const Expanded(
                    child: Text(
                      'Aponte a câmera para o QR Code localizado no ativo.',

                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ======================================================
            // BOTÃO
            // ======================================================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () {},

                icon: const Icon(Icons.camera_alt_outlined),

                label: const Text('Iniciar Scanner'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  final bool top;
  final bool left;

  const _ScannerCorner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,

      child: CustomPaint(
        painter: _CornerPainter(top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;

  _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mainColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (top && left) {
      path
        ..moveTo(0, 15)
        ..lineTo(0, 0)
        ..lineTo(15, 0);
    }

    if (top && !left) {
      path
        ..moveTo(size.width - 15, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, 15);
    }

    if (!top && left) {
      path
        ..moveTo(0, size.height - 15)
        ..lineTo(0, size.height)
        ..lineTo(15, size.height);
    }

    if (!top && !left) {
      path
        ..moveTo(size.width - 15, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - 15);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
