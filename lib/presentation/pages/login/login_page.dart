import 'package:flutter/material.dart';
import 'package:mobile_integrador/presentation/widgets/shared/form/form.dart';
import 'package:mobile_integrador/presentation/widgets/shared/botaoApp/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose(){
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm(){
    if(_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Carregando..."))
      )
    }
  }

  @override
  Widget Build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              FormData(
                labelText: "Nome de usuário",
                controller: _usernameController,
                prefixIcon: Icons.person, 
                validator: (value) => {
                  if(value == null || value.trim().isEmpty) return "Por favor, insira seu nome de usuário.";
                  return null;
                }
              ),
              FormData(
                labelText: "Senha do usuário",
                controller: _passwordController,
                prefixIcon: Icons.lock, 
                isPassword: true,
                validator: (value) => {
                  if(value == null) return "Por favor, insira a senha.";
                  return null;
                }
              ),

              const SizedBox(height: 20),

              BotaoApp(
                texto: "Entrar",
                onPressed: _submitForm,
              )
            ],
          ),
        )
      ),
    );
  }
}