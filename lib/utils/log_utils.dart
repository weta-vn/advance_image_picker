import 'package:intl/intl.dart';

class LogUtils {
  static log(String message) {
    print(DateTime.now().toIso8601String() + ": " + message);
  }
}