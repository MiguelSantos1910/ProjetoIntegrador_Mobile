/// Endereço da API.
///
/// Padrão: back-end local no próprio computador. Para o celular ou o
/// emulador, informe o endereço ao rodar ou gerar o app:
///
///   flutter run --dart-define=API_URL=http://10.0.2.2:8000/api      (emulador)
///   flutter run --dart-define=API_URL=http://192.168.0.10:8000/api  (celular)
///   flutter build apk --dart-define=API_URL=http://54.20.29.135/api (servidor)
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );
}
