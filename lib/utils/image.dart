import 'dart:io';

import 'package:image/image.dart';

Future<File> resizeImage(File origin, {int? width, int? height}) async {
  final image = decodeImage(await origin.readAsBytes());
  if (image == null) {
    return origin;
  }
  final resized = copyResize(image, width: width, height: height);
  return await origin.writeAsBytes(encodePng(resized));
}
