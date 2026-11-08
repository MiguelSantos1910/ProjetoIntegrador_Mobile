/// Endereço da API.
///
/// Padrão: back-end local no próprio computador. Para o celular ou o
/// emulador, informe o endereço ao rodar ou gerar o app:
///
///   flutter run --dart-define=API_URL=https://miguel1910.pythonanywhere.com/api      (emulador)
///   flutter run --dart-define=API_URL=https://miguel1910.pythonanywhere.com/api  (celular)
///   flutter build apk --dart-define=API_URL=https://miguel1910.pythonanywhere.com/api (servidor)
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://miguel1910.pythonanywhere.com/api/',
  );
}
