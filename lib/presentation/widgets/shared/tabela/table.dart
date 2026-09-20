import 'package:flutter/material.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';

class Tabela extends StatelessWidget {
  final String titulo;
  final List<String> colunas;
  final List<List<String>> dados;

  const Tabela({
    super.key,
    required this.titulo,
    required this.colunas,
    required this.dados,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: AppColors.tableHeader,

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // TÍTULO

          Padding(
            padding: const EdgeInsets.all(16),

            child: Text(
              titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // TABELA
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,

            child: DataTable(
              columnSpacing: 32,

              headingRowHeight: 44,

              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,

              headingTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),

              dataTextStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),

              columns: colunas.map((coluna) {
                return DataColumn(label: Text(coluna));
              }).toList(),

              rows: dados.map((linha) {
                return DataRow(
                  cells: linha.map((valor) {
                    return DataCell(Text(valor));
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
