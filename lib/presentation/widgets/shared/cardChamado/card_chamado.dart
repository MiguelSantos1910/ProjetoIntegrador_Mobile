import 'package:flutter/material.dart';

import 'package:mobile_integrador/core/utils/formatar_data.dart';
import 'package:mobile_integrador/data/models/ativo.dart';
import 'package:mobile_integrador/data/models/ordem_manutencao.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/statusBadge/status_badge.dart';

// ================================================================
// CARD DE UM CHAMADO (lista de chamados e Home)
// ================================================================

class CardChamado extends StatelessWidget {
  final OrdemManutencao ordem;
  final Ativo? ativo;
  final VoidCallback onTap;

  const CardChamado({
    super.key,
    required this.ordem,
    required this.ativo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = StatusOrdem.cor(ordem.status);
    final nomeAtivo = ativo?.descricao ?? 'Ativo #${ordem.ativoId}';

    return Material(
      color: AppColors.backgroundCards,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(StatusOrdem.icone(ordem.status), color: cor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${ordem.id} · $nomeAtivo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ordem.descricao.isEmpty
                          ? 'Sem descrição'
                          : ordem.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusOrdemBadge(status: ordem.status),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '${ordem.responsavel} · '
                            '${dataFormatada(ordem.dataAbertura)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
