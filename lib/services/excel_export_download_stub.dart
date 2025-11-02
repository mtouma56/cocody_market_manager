import 'package:flutter/foundation.dart';

Future<void> downloadFileWeb(String content, String fileName) async {
  if (kDebugMode) {
    debugPrint(
      'downloadFileWeb is not supported outside web. Request ignored for $fileName.',
    );
  }
}
