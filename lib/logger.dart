
import 'package:flutter/foundation.dart';

abstract class Logger {
  void log<T>(T data);

  void i<T>(T data);

  void e<T>(T data);

  const Logger();

  factory Logger.create() {
    return _DefaultLogger();
  }
}

class _DefaultLogger extends Logger {
  @override
  void log<T>(T data) {
    if (kDebugMode) {
      print(data);
    }
  }
  
  @override
  void i<T>(T data) {
    log(data);
  }
  
  @override
  void e<T>(T data) {
    log(data);
  }
  
}

final logger = Logger.create();