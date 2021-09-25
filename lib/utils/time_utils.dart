/// Simple utilities to work with time
class TimeUtils {
  /// Returns a nicely formatted date time string.
  static String getTimeString(DateTime time,
      {String s1 = "", String s2 = "_", String s3 = ""}) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');

    final milliSecond = time.millisecond.toString().padLeft(3, '0');
    final text = '${time.year}$s1$month$s1$day$s2$hour$s3$minute$s3$second$s3'
        '$milliSecond';
    return text;
  }
}
