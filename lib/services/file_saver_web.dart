// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

Future<String> saveFileBytes(
  Uint8List bytes, {
  required String fileName,
  String? destinationPath,
}) async {
  final blob = html.Blob(
    <dynamic>[bytes],
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: objectUrl)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(objectUrl);

  return fileName;
}
