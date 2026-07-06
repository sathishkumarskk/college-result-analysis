import 'dart:typed_data';

Future<String> saveFileBytes(
  Uint8List bytes, {
  required String fileName,
  String? destinationPath,
}) {
  throw UnsupportedError('Saving files is not supported on this platform.');
}
