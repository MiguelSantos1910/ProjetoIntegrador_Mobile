import 'package:flutter/material.dart';

/// Rótulos, cores e ícones dos status e tipos de ativo, num só lugar.
/// As cores de Ativo, Em manutenção e Devolvido são as mesmas da Home.
class StatusAtivo {
  StatusAtivo._();

  static const String ativo = 'ATIVO';
  static const String emManutencao = 'EM_MANUTENCAO';
  static const String devolvido = 'DEVOLVIDO';
  static const String inativo = 'INATIVO';

  static const List<String> todos = [ativo, emManutencao, devolvido, inativo];

  static String normalizar(String status) {
    final valor = status.trim().toUpperCase();
    return valor == 'EM MANUTENÇÃO' ? emManutencao : valor;
  }

  static String rotulo(String status) {
    switch (normalizar(status)) {
      case ativo:
        return 'Ativo';
      case emManutencao:
        return 'Em manutenção';
      case devolvido:
        return 'Devolvido';
      case inativo:
        return 'Inativo';
      default:
        return status.trim().isEmpty ? 'Não informado' : status;
    }
  }

  static Color cor(String status) {
    switch (normalizar(status)) {
      case ativo:
        return const Color(0xFF16A34A);
      case emManutencao:
        return const Color(0xFFF59E0B);
      case devolvido:
        return const Color(0xFF64748B);
      case inativo:
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  static String rotuloTipo(String tipo) {
    switch (tipo.trim().toUpperCase()) {
      case 'GABINETE':
        return 'Gabinete';
      case 'MONITOR':
        return 'Monitor';
      case 'TECLADO':
        return 'Teclado';
      case 'MESA':
        return 'Mesa';
      default:
        return tipo.trim().isEmpty ? 'Não informado' : tipo;
    }
  }

  static IconData iconeTipo(String tipo) {
    switch (tipo.trim().toUpperCase()) {
      case 'GABINETE':
        return Icons.computer_outlined;
      case 'MONITOR':
        return Icons.monitor_outlined;
      case 'TECLADO':
        return Icons.keyboard_outlined;
      case 'MESA':
        return Icons.table_restaurant_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}

/// Etiqueta colorida com o status do ativo.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cor = StatusAtivo.cor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        StatusAtivo.rotulo(status),
        style: TextStyle(
          color: cor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
