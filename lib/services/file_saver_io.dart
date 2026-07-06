import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> saveFileBytes(
  Uint8List bytes, {
  required String fileName,
  String? destinationPath,
}) async {
  final targetPath = await _resolveOutputPath(
    fileName: fileName,
    destinationPath: destinationPath,
  );
  final file = File(targetPath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<String> _resolveOutputPath({
  required String fileName,
  String? destinationPath,
}) async {
  if (destinationPath != null && destinationPath.trim().isNotEmpty) {
    return _ensureExcelExtension(destinationPath);
  }

  final directory = await getApplicationDocumentsDirectory();
  return p.join(directory.path, fileName);
}

String _ensureExcelExtension(String filePath) {
  return p.extension(filePath).toLowerCase() == '.xlsx'
      ? filePath
      : '$filePath.xlsx';
}
