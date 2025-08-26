import 'dart:developer' as developer;

class DebugLogger {
  static void log(String message, {String? tag}) {
    developer.log(message, name: tag ?? 'Strep');
  }
}
