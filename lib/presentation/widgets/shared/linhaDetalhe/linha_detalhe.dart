import 'package:flutter/material.dart';

import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';

// ================================================================
// LINHA DE DETALHE (ícone, rótulo e valor), usada nas telas de
// detalhe do ativo e do chamado
// ================================================================

class LinhaDetalhe extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;
  final bool selecionavel;
  final bool ultima;

  const LinhaDetalhe({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.selecionavel = false,
    this.ultima = false,
  });

  @override
  Widget build(BuildContext context) {
    const estiloValor = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: ultima
            ? null
            : const Border(bottom: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: AppColors.mainColor),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              rotulo,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: selecionavel
                ? SelectableText(valor, style: estiloValor)
                : Text(valor, style: estiloValor),
          ),
        ],
      ),
    );
  }
}
