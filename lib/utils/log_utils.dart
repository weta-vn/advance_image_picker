import 'package:flutter/foundation.dart';

/// Static logging utility class.
///
/// Used for debugging during development. Does not log in release builds.
///
/// NOTE: Future version may add configurable logging setting to control
/// in which build modes logging occurs.
class LogUtils {
  /// Log a message with debugPrint and a DateTime stamp to the console.
  ///
  /// Never logs in release mode builds.
  static void log(String message) {
    if (!kReleaseMode) {
      debugPrint("${DateTime.now().toIso8601String()}: $message");
    }
  }
}
