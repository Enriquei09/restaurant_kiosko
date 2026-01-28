import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Manejador centralizado de errores para la aplicación
class ErrorHandler {
  
  /// Maneja errores de API y muestra mensajes apropiados al usuario
  static void handleApiError(BuildContext context, dynamic error) {
    String message = 'Error inesperado. Intenta nuevamente.';
    
    if (error is SocketException) {
      message = 'Sin conexión a internet. Verifica tu conexión.';
    } else if (error is HttpException) {
      message = 'Error de servidor. Intenta más tarde.';
    } else if (error is FormatException) {
      message = 'Error en los datos recibidos.';
    } else if (error.toString().contains('timeout')) {
      message = 'La conexión tardó demasiado. Intenta nuevamente.';
    } else if (error.toString().contains('404')) {
      message = 'Servicio no encontrado. Contacta al administrador.';
    } else if (error.toString().contains('500')) {
      message = 'Error interno del servidor. Intenta más tarde.';
    } else if (error.toString().contains('unauthorized') || 
               error.toString().contains('401')) {
      message = 'No autorizado. Verifica las credenciales.';
    }
    
    // Log del error para debugging
    if (kDebugMode) {
      debugPrint('🚨 Error: $error');
      debugPrint('📍 Stack trace: ${StackTrace.current}');
    }
    
    // Mostrar snackbar al usuario
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Cerrar',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// Maneja errores de validación de formularios
  static void handleValidationError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Muestra mensaje de éxito
  static void showSuccess(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Muestra mensaje informativo
  static void showInfo(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Ejecuta una operación async con manejo de errores automático
  static Future<T?> safeExecute<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    bool showLoading = false,
  }) async {
    // Mostrar loading si se requiere
    if (showLoading && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(loadingMessage ?? 'Procesando...'),
            ],
          ),
        ),
      );
    }

    try {
      final result = await operation();
      
      // Cerrar loading si estaba abierto
      if (showLoading && context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Mostrar mensaje de éxito si se especificó
      if (successMessage != null) {
        showSuccess(context, successMessage);
      }
      
      return result;
    } catch (error) {
      // Cerrar loading si estaba abierto
      if (showLoading && context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Manejar el error
      handleApiError(context, error);
      return null;
    }
  }

  /// Retry operation con backoff exponencial
  static Future<T?> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempts++;
        
        if (attempts >= maxRetries) {
          rethrow; // Re-lanzar el error después de todos los intentos
        }
        
        if (kDebugMode) {
          debugPrint('Intento $attempts fallido, reintentando en ${delay.inSeconds}s...');
        }
        
        await Future.delayed(delay);
        delay *= 2; // Backoff exponencial
      }
    }
    
    return null;
  }

  /// Maneja errores específicos de la aplicación de kiosko
  static void handleKioskError(BuildContext context, String errorType, dynamic error) {
    String message;
    
    switch (errorType) {
      case 'cart_empty':
        message = 'Agrega productos al carrito antes de continuar.';
        break;
      case 'payment_failed':
        message = 'Error en el pago. Verifica los datos e intenta nuevamente.';
        break;
      case 'order_failed':
        message = 'Error al procesar la orden. Contacta al personal.';
        break;
      case 'kitchen_connection':
        message = 'Sin conexión con la cocina. Contacta al administrador.';
        break;
      case 'product_unavailable':
        message = 'Producto no disponible actualmente.';
        break;
      case 'invalid_modifier':
        message = 'Configuración de producto inválida.';
        break;
      default:
        handleApiError(context, error);
        return;
    }
    
    handleValidationError(context, message);
  }
}