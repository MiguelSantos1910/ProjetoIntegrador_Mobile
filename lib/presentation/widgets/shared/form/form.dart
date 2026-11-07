import 'package:flutter/material.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';

/// Campo de formulário reutilizável do app, no visual da tela de login:
/// rótulo acima do campo, fundo claro, cantos arredondados, ícone verde,
/// borda verde no foco e vermelha no erro.
///
/// Com [isPassword], o campo oculta o texto e mostra o botão de
/// mostrar/ocultar senha.
///
/// O espaçamento entre um campo e o próximo fica a cargo da tela.
class FormData extends StatefulWidget {
  /// Texto exibido acima do campo (ex.: "Nome de usuário").
  final String? label;

  /// Texto exibido dentro do campo (ex.: "Digite seu usuário").
  final String hintText;

  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool autocorrect;
  final bool enabled;

  /// Linhas do campo (ex.: 4 para uma descrição). Senha é sempre 1 linha.
  final int maxLines;
  final int? maxLength;

  const FormData({
    super.key,
    required this.hintText,
    required this.controller,
    this.label,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.autofillHints,
    this.autocorrect = true,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
  });

  /// Decoração padrão dos campos do app. Também serve para campos que não
  /// são TextFormField (ex.: um seletor), para manter o mesmo visual.
  static InputDecoration decoracaoPadrao({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    bool alinharNoTopo = false,
  }) {
    return InputDecoration(
      labelText: hintText,
      alignLabelWithHint: alinharNoTopo,
      errorText: errorText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.mainColor)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.lightBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.mainColor, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  @override
  State<FormData> createState() => _FormDataState();
}

class _FormDataState extends State<FormData> {
  bool _mostrarSenha = false;

  InputDecoration _decoracao() {
    return FormData.decoracaoPadrao(
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon,
      alinharNoTopo: widget.maxLines > 1,
      suffixIcon: widget.isPassword
          ? IconButton(
              tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
              onPressed: () {
                setState(() {
                  _mostrarSenha = !_mostrarSenha;
                });
              },
              icon: Icon(
                _mostrarSenha
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final campo = TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && !_mostrarSenha,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autocorrect: widget.isPassword ? false : widget.autocorrect,
      enableSuggestions: !widget.isPassword,
      autofillHints: widget.autofillHints,
      enabled: widget.enabled,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      minLines: 1,
      maxLength: widget.maxLength,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: _decoracao(),
    );

    if (widget.label == null) {
      return campo;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label!,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 9),
        campo,
      ],
    );
  }
}
