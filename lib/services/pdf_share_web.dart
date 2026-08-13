import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

Future<String> savePdfToFile(Uint8List bytes, String filename) async {
  return filename;
}

Future<void> sharePdfFile(
    Uint8List bytes, String filename, String subject, String text) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(bytes,
            mimeType: 'application/pdf', name: '$filename.pdf'),
      ],
      subject: subject,
      text: text,
    ),
  );
}
