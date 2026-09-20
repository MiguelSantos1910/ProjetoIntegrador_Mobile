import 'package:flutter/material.dart';
import 'package:mobile_integrador/routes/routes.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appTheme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Easy Asset',

      theme: AppTheme.appTheme,

      initialRoute: AppRoutes.home,

      onGenerateRoute: AppRoutes.generatedRoute,
    );
  }
}
