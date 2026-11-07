import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_integrador/presentation/pages/app.dart';
import 'package:mobile_integrador/presentation/providers/sessao_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SessaoProvider(),
      child: const App(),
    ),
  );
}
