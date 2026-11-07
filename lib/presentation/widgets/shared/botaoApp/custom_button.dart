import 'package:flutter/material.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';

/// Botão principal do app, no visual do botão "Entrar" da tela de login:
/// largura total, 54 px de altura, verde, cantos arredondados, texto em
/// negrito e ícone à direita. Com [carregando], mostra um indicador de
/// progresso e fica desabilitado.
class BotaoApp extends StatelessWidget {
  final String texto;
  final IconData? icone;
  final VoidCallback? onPressed;
  final bool carregando;

  const BotaoApp({
    super.key,
    required this.texto,
    this.icone,
    this.onPressed,
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: carregando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.mainColor.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: carregando
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    texto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (icone != null) ...[
                    const SizedBox(width: 10),
                    Icon(icone, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}
