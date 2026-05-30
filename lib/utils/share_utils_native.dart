// Native implementation — uses dart:io and path_provider
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareImageOnNative(
  List<int> imageBytes,
  String counterTitle,
  String subject,
) async {
  final directory = await getTemporaryDirectory();
  final imagePath =
      '${directory.path}/share_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File(imagePath);
  await file.writeAsBytes(imageBytes);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(imagePath)],
      subject: subject,
      text: 'Check out my streak on $counterTitle!',
    ),
  );
}

// This stub exists so web-conditional import compiles
Future<void> downloadImageOnWeb(List<int> bytes, String filename) async {
  // No-op on native — this path is never called
}
