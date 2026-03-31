// URL base de la API — configurable via --dart-define=API_BASE_URL=https://tu-dominio.com/api
// En desarrollo (web/macOS): 127.0.0.1 funciona directo
// En dispositivo físico: flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000/api
// En producción: flutter build apk --dart-define=API_BASE_URL=https://api.tudominio.com/api
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api',
);


