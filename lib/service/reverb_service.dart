import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants.dart';

/// Servicio de WebSocket que implementa el protocolo Pusher
/// para conectarse a Laravel Reverb y escuchar eventos en tiempo real.
///
/// Uso:
/// ```dart
/// final reverb = ReverbService(
///   token: authProvider.token!,
///   restaurantId: 1,
///   onEvent: (event, data) { ... },
///   onConnected: () { ... },
///   onDisconnected: () { ... },
/// );
/// await reverb.connect();
/// // ...
/// reverb.dispose();
/// ```
class ReverbService {
  // ── Configuración Reverb (via --dart-define o fallback) ──
  static const _reverbKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'x9h3ug4zegnq7edjlhzw',
  );
  static const _reverbPort = String.fromEnvironment(
    'REVERB_PORT',
    defaultValue: '8080',
  );

  /// Deriva el host de Reverb desde la misma baseUrl de la API.
  /// Si baseUrl es "http://192.168.0.9:8000/api", el host será "192.168.0.9".
  /// Se puede sobreescribir con --dart-define=REVERB_HOST=mi-host.com
  static String get _reverbHost {
    const override = String.fromEnvironment('REVERB_HOST');
    if (override.isNotEmpty) return override;
    try {
      return Uri.parse(baseUrl).host;
    } catch (_) {
      return '127.0.0.1';
    }
  }

  /// Deriva el scheme (ws/wss) desde la baseUrl.
  static String get _reverbScheme {
    const override = String.fromEnvironment('REVERB_SCHEME');
    if (override.isNotEmpty) return override;
    try {
      return Uri.parse(baseUrl).scheme; // http → ws, https → wss
    } catch (_) {
      return 'http';
    }
  }

  // ── Estado ──
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _socketId;
  bool _disposed = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  // ── Parámetros ──
  final String token;
  final int restaurantId;
  final void Function(String event, Map<String, dynamic> data)? onEvent;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final void Function(String error)? onError;

  ReverbService({
    required this.token,
    required this.restaurantId,
    this.onEvent,
    this.onConnected,
    this.onDisconnected,
    this.onError,
  });

  bool get isConnected => _socketId != null;

  // ═══════════════════════════════════════════════════════════
  // CONEXIÓN
  // ═══════════════════════════════════════════════════════════

  /// Conectar al servidor Reverb vía WebSocket (protocolo Pusher).
  Future<void> connect() async {
    if (_disposed) return;

    try {
      final wsScheme = _reverbScheme == 'https' ? 'wss' : 'ws';
      final uri = Uri.parse(
        '$wsScheme://$_reverbHost:$_reverbPort/app/$_reverbKey'
        '?protocol=7&client=flutter&version=1.0&flash=false',
      );

      debugPrint('[Reverb] Conectando a $uri');

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('[Reverb] Error de WebSocket: $error');
          onError?.call(error.toString());
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[Reverb] WebSocket cerrado');
          _socketId = null;
          onDisconnected?.call();
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[Reverb] Error al conectar: $e');
      onError?.call(e.toString());
      _scheduleReconnect();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // MENSAJES ENTRANTES (Protocolo Pusher)
  // ═══════════════════════════════════════════════════════════

  void _handleMessage(dynamic raw) {
    if (_disposed) return;

    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = msg['event'] as String? ?? '';

      switch (event) {
        // ── Conexión establecida ──
        case 'pusher:connection_established':
          final connData = jsonDecode(msg['data'] as String);
          _socketId = connData['socket_id'] as String;
          _reconnectAttempts = 0;
          debugPrint('[Reverb] Conectado — socket_id: $_socketId');
          _startPingTimer();
          _subscribeToPrivateChannel();
          onConnected?.call();
          break;

        // ── Suscripción exitosa ──
        case 'pusher_internal:subscription_succeeded':
          final ch = msg['channel'] ?? '';
          debugPrint('[Reverb] Suscrito a $ch');
          break;

        // ── Error de suscripción ──
        case 'pusher:error':
          final errorData = msg['data'] is String
              ? jsonDecode(msg['data'] as String)
              : msg['data'];
          debugPrint('[Reverb] Error: $errorData');
          onError?.call(errorData.toString());
          break;

        // ── Pong del servidor ──
        case 'pusher:pong':
          break;

        // ── Eventos de la aplicación (OrderCreated, etc.) ──
        default:
          _handleAppEvent(event, msg);
          break;
      }
    } catch (e) {
      debugPrint('[Reverb] Error parseando mensaje: $e');
    }
  }

  /// Procesar eventos de la aplicación (como OrderCreated).
  void _handleAppEvent(String event, Map<String, dynamic> msg) {
    try {
      final rawData = msg['data'];
      final data = rawData is String
          ? jsonDecode(rawData) as Map<String, dynamic>
          : (rawData as Map<String, dynamic>?) ?? {};

      debugPrint('[Reverb] Evento recibido: $event');
      onEvent?.call(event, data);
    } catch (e) {
      debugPrint('[Reverb] Error procesando evento $event: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SUSCRIPCIÓN A CANAL PRIVADO
  // ═══════════════════════════════════════════════════════════

  /// Suscribirse al canal privado `private-restaurant.{restaurantId}`.
  ///
  /// Los canales privados requieren autenticación via POST a /broadcasting/auth
  /// antes de que Reverb permita la suscripción.
  Future<void> _subscribeToPrivateChannel() async {
    final channelName = 'private-restaurant.$restaurantId';

    try {
      // 1. Obtener auth signature del backend
      final authSignature = await _authenticateChannel(channelName);
      if (authSignature == null) {
        debugPrint('[Reverb] No se pudo autenticar canal $channelName');
        return;
      }

      // 2. Enviar suscripción al WebSocket con la firma
      _send({
        'event': 'pusher:subscribe',
        'data': {
          'auth': authSignature,
          'channel': channelName,
        },
      });

      debugPrint('[Reverb] Solicitando suscripción a $channelName');
    } catch (e) {
      debugPrint('[Reverb] Error suscribiendo a $channelName: $e');
      onError?.call('Error suscripción: $e');
    }
  }

  /// Autenticar canal privado via POST /broadcasting/auth.
  Future<String?> _authenticateChannel(String channelName) async {
    try {
      // Construir URL del broadcasting auth endpoint
      // baseUrl es "http://127.0.0.1:8000/api", necesitamos "http://127.0.0.1:8000"
      final broadcastUrl = baseUrl.replaceAll('/api', '');
      final uri = Uri.parse('$broadcastUrl/broadcasting/auth');

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: {
          'socket_id': _socketId!,
          'channel_name': channelName,
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['auth'] as String;
      } else {
        debugPrint('[Reverb] Auth failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[Reverb] Error en auth request: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PING / KEEP-ALIVE
  // ═══════════════════════════════════════════════════════════

  void _startPingTimer() {
    _pingTimer?.cancel();
    // Enviar ping cada 30 segundos para mantener la conexión viva
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send({'event': 'pusher:ping', 'data': {}});
    });
  }

  // ═══════════════════════════════════════════════════════════
  // RECONEXIÓN AUTOMÁTICA
  // ═══════════════════════════════════════════════════════════

  void _scheduleReconnect() {
    if (_disposed || _reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectAttempts++;
    _pingTimer?.cancel();
    _socketId = null;

    // Backoff exponencial: 1s, 2s, 4s, 8s... max 30s
    final delay = Duration(
      seconds: (_reconnectAttempts * _reconnectAttempts).clamp(1, 30),
    );

    debugPrint('[Reverb] Reconectando en ${delay.inSeconds}s '
        '(intento $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_disposed) connect();
    });
  }

  // ═══════════════════════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════════════════════

  void _send(Map<String, dynamic> data) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(data));
  }

  /// Cerrar conexión y liberar recursos.
  void dispose() {
    _disposed = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _socketId = null;
    debugPrint('[Reverb] Servicio dispuesto');
  }
}
