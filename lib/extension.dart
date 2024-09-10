extension StringExt on String {
  String trimStringFromJavascript() {
    var data = replaceFirst("\"", "", 0);
    data = data.replaceFirst("\"", "", data.length - 1);
    data = data.replaceAll("\\", "");
    return data;
  }

  String decodeUnicode() {
    return replaceAllMapped(RegExp(r'u[0-9a-fA-F]{4}'), (match) {
    return String.fromCharCode(int.parse(match.group(0)!.substring(2), radix: 16));
  });
  }

  String parseUuidWithoutDashes() {
  // Ensure the string has the correct length for a UUID (32 characters)
  if (length != 32) {
    throw const FormatException('Invalid UUID format: the string must have 32 characters.');
  }

  // Insert dashes at the correct positions
  final uuidWithDashes = '${substring(0, 8)}-'
      '${substring(8, 12)}-'
      '${substring(12, 16)}-'
      '${substring(16, 20)}-'
      '${substring(20, 32)}';

  return uuidWithDashes;
}
}

extension IntExt on int {
  String toTimeDisplay() {
    String formatTime(int time) => time < 10 ? "0$time" : "$time";

    final seconds = this ~/ 1000;
    final hoursDisplay = seconds ~/ 3600;
    final remainSeconds = seconds - hoursDisplay * 3600;
    final minutesDisplay = remainSeconds ~/ 60;
    final secondDisplay = remainSeconds % 60;

    return "${formatTime(hoursDisplay)}:${formatTime(minutesDisplay)}:${formatTime(secondDisplay)}";

  }
}