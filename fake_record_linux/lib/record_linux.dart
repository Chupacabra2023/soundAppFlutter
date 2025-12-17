// Fake empty plugin to disable Linux support
import 'package:flutter/foundation.dart';

class RecordLinux {
  static void registerWith() {
    if (kDebugMode) {
      print('RecordLinux fake plugin registered (Linux support disabled)');
    }
  }
}
