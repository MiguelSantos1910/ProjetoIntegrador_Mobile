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
            // Ícone no padrão da Home: quadrado verde-claro arredondado.
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.mainColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: AppColors.mainColor, size: 24),
            ),

            const SizedBox(width: 12),

            // Expanded: o texto ocupa só o espaço que sobra ao lado do ícone
            // (sem ele, títulos longos estouram cards estreitos).
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(color: Colors.black, fontSize: 13),
                  ),

                  const SizedBox(height: 8),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      valor,

                      style: TextStyle(
                        color: AppColors.mainColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
