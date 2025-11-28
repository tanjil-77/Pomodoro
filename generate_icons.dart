// ignore_for_file: avoid_print

import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  // Read the source image
  final sourceFile = File('assets/icon/pomodoro_icon.png');
  final sourceBytes = await sourceFile.readAsBytes();
  final sourceImage = img.decodeImage(sourceBytes);

  if (sourceImage == null) {
    print('Error: Could not decode image');
    return;
  }

  // Android icon sizes
  final androidSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  // Create Android icons
  for (var entry in androidSizes.entries) {
    final size = entry.value;
    final folder = entry.key;
    final resized = img.copyResize(sourceImage, width: size, height: size);

    final dir = Directory('android/app/src/main/res/$folder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File('${dir.path}/ic_launcher.png');
    await file.writeAsBytes(img.encodePng(resized));
    print('✓ Created ${file.path}');
  }

  print('\n✓ All Android icons generated successfully!');
}
