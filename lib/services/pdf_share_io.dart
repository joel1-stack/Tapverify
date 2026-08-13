import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> savePdfToFile(Uint8List bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename.pdf');
  await file.writeAsBytes(bytes);
  return file.path;
}

Future<void> sharePdfFile(
    Uint8List bytes, String filename, String subject, String text) async {
  final path = await savePdfToFile(bytes, filename);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: 'application/pdf')],
      subject: subject,
      text: text,
    ),
  );
}
