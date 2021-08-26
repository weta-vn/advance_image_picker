/// Simple utilities to work with time
class TimeUtils {
  static String getTimeString(DateTime time,
      {String s1 = "", String s2 = "_", String s3 = ""}) {
    var month = time.month.toString().padLeft(2, '0');
    var day = time.day.toString().padLeft(2, '0');
    var hour = time.hour.toString().padLeft(2, '0');
    var minute = time.minute.toString().padLeft(2, '0');
    var second = time.second.toString().padLeft(2, '0');
    var milisecond = time.millisecond.toString().padLeft(3, '0');
    var text =
        '${time.year}$s1$month$s1$day$s2$hour$s3$minute$s3$second$s3$milisecond';
    return text;
  }
}
