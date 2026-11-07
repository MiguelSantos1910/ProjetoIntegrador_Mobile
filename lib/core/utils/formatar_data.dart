/// Formatação de datas no padrão brasileiro, sem pacotes extras.
String _doisDigitos(int valor) => valor.toString().padLeft(2, '0');

/// 07/11/2026
String dataFormatada(DateTime? data) {
  if (data == null) return '—';

  final local = data.toLocal();
  return '${_doisDigitos(local.day)}/${_doisDigitos(local.month)}/${local.year}';
}

/// 07/11/2026 14:32
String dataHoraFormatada(DateTime? data) {
  if (data == null) return '—';

  final local = data.toLocal();
  return '${dataFormatada(local)} '
      '${_doisDigitos(local.hour)}:${_doisDigitos(local.minute)}';
}
