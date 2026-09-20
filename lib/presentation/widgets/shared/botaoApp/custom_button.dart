import 'package:flutter/material.dart';

class BotaoApp extends StatelessWidget {
  final String texto;
  final IconData? icone;
  final VoidCallback? onPressed;

  const BotaoApp({super.key, required this.texto, this.icone, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,

      icon: Icon(icone ?? Icons.add),

      label: Text(texto),
    );
  }
}
