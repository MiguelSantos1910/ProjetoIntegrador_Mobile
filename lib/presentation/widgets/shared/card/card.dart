import 'package:flutter/material.dart';

import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';

class CardApp extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const CardApp({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.backgroundCards,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Row(
          children: [
            Icon(icone, color: AppColors.mainColor, size: 28),

            const SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  titulo,

                  style: const TextStyle(color: Colors.black, fontSize: 13),
                ),

                const SizedBox(height: 8),

                Text(
                  valor,

                  style: TextStyle(
                    color: AppColors.mainColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
