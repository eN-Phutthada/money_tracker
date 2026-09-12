// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file1024 = File('assets/icons/app_icon_1024.png');
  if (!file1024.existsSync()) {
    print('File assets/icons/app_icon_1024.png not found');
    return;
  }

  final bytes = file1024.readAsBytesSync();
  final image = img.decodePng(bytes);
  if (image == null) {
    print('Failed to decode image');
    return;
  }

  print('Loaded image: ${image.width}x${image.height}');

  // 1. Android Mipmaps
  final resDir = Directory(r'android/app/src/main/res');
  final androidSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in androidSizes.entries) {
    final folder = Directory('${resDir.path}/${entry.key}');
    if (!folder.existsSync()) folder.createSync(recursive: true);

    final size = entry.value;
    final resized = img.copyResize(image, width: size, height: size);
    
    // Square / Squircle ic_launcher
    File('${folder.path}/ic_launcher.png').writeAsBytesSync(img.encodePng(resized));

    // Round ic_launcher_round (crop circle)
    final round = img.copyCropCircle(resized);
    File('${folder.path}/ic_launcher_round.png').writeAsBytesSync(img.encodePng(round));
  }
  print('Android mipmaps updated successfully');

  // 2. iOS AppIcon.appiconset
  final iosDir = Directory(r'ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (iosDir.existsSync()) {
    final iosSizes = {
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
      'Icon-App-1024x1024@1x.png': 1024,
    };

    for (final entry in iosSizes.entries) {
      final resized = img.copyResize(image, width: entry.value, height: entry.value);
      File('${iosDir.path}/${entry.key}').writeAsBytesSync(img.encodePng(resized));
    }
    print('iOS AppIcon updated successfully');
  }

  // 3. Web icons
  final webDir = Directory(r'web');
  if (webDir.existsSync()) {
    final favicon = img.copyResize(image, width: 32, height: 32);
    File('${webDir.path}/favicon.png').writeAsBytesSync(img.encodePng(favicon));

    final iconsDir = Directory('${webDir.path}/icons');
    if (!iconsDir.existsSync()) iconsDir.createSync(recursive: true);

    final icon192 = img.copyResize(image, width: 192, height: 192);
    final icon512 = img.copyResize(image, width: 512, height: 512);

    File('${iconsDir.path}/Icon-192.png').writeAsBytesSync(img.encodePng(icon192));
    File('${iconsDir.path}/Icon-512.png').writeAsBytesSync(img.encodePng(icon512));
    File('${iconsDir.path}/Icon-maskable-192.png').writeAsBytesSync(img.encodePng(icon192));
    File('${iconsDir.path}/Icon-maskable-512.png').writeAsBytesSync(img.encodePng(icon512));
    print('Web icons updated successfully');
  }

  // 4. Windows app_icon.ico
  final winResDir = Directory(r'windows/runner/resources');
  if (winResDir.existsSync()) {
    final winIco = img.copyResize(image, width: 256, height: 256);
    File('${winResDir.path}/app_icon.ico').writeAsBytesSync(img.encodeIco(winIco));
    print('Windows app_icon.ico updated successfully');
  }

  // 5. Assets (512x512 & 1024x1024)
  final assetsDir = Directory(r'assets/icons');
  if (!assetsDir.existsSync()) assetsDir.createSync(recursive: true);
  final icon512 = img.copyResize(image, width: 512, height: 512);
  File('${assetsDir.path}/app_icon.png').writeAsBytesSync(img.encodePng(icon512));
  print('Assets app_icon.png (512x512) updated successfully');
}
