extension Common on String {
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
}