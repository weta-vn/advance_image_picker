import 'package:intl/intl.dart';

class LogUtils {
  static log(String message) {
    print(DateFormat.yMMMd().format(DateTime.now()) + message);
  }
}