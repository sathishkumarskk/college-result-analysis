import 'dart:typed_data';

import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart' as saver;

Future<String> saveFileBytes(
  Uint8List bytes, {
  required String fileName,
  String? destinationPath,
}) {
  return saver.saveFileBytes(
    bytes,
    fileName: fileName,
    destinationPath: destinationPath,
  );
}
