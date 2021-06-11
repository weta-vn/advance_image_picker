import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/image_object.dart';

class ImageUtils {
  /// ```
  /// 1,0,0,0,0,
  /// 0,1,0,0,0,
  /// 0,0,1,0,0,
  /// 0,0,0,1,0
  /// ```
  static const defaultColorMatrix = const <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];

  static List<double> saturationColorMatrix(double saturation) {
    final m = List<double>.from(defaultColorMatrix);

    final invSat = 1 - saturation;
    final R = 0.213 * invSat;
    final G = 0.715 * invSat;
    final B = 0.072 * invSat;

    m[0] = R + saturation;
    m[1] = G;
    m[2] = B;
    m[5] = R;
    m[6] = G + saturation;
    m[7] = B;
    m[10] = R;
    m[11] = G;
    m[12] = B + saturation;

    return m;
  }

  static scaleColorMatrix(double rScale, double gScale, double bScale, double aScale) {
    final m = List<double>.filled(20, 0);
    m[0] = rScale;
    m[6] = gScale;
    m[12] = bScale;
    m[18] = aScale;
    return m;
  }

  static brightnessColorMatrix(double brightness) {
    return scaleColorMatrix(brightness, brightness, brightness, 1);
  }

  static contrastColorMatrix(double contrast) {
    final m = List<double>.from(defaultColorMatrix);
    m[0] = contrast;
    m[6] = contrast;
    m[12] = contrast;
    return m;
  }

  static Future<ImageProperties> getImageProperties(String path) async {
    return await FlutterNativeImage.getImageProperties(path);
  }

  static Future<File> compressResizeImage(String path,
      {int quality = 90, int maxWidth = 1920, int maxHeight = 1080}) async {
    ImageProperties properties = await FlutterNativeImage.getImageProperties(path);

    var outputWidth = properties.width;
    var outputHeight = properties.height;

    if (properties.width > maxWidth || properties.height > maxHeight) {
      var ratio = properties.width / properties.height;
      outputWidth = min(properties.width, maxWidth);
      outputHeight = outputWidth ~/ ratio;
      if (outputHeight > maxHeight) {
        outputHeight = min(properties.height, maxHeight);
        outputWidth = (outputHeight * ratio).toInt();
      }

      File compressedFile = await FlutterNativeImage.compressImage(path,
          quality: quality, targetWidth: outputWidth, targetHeight: outputHeight);
      return compressedFile;
    }

    return File(path);
  }

  static Future<File> cropImage(String path,
      {int originX = 0, int originY = 0, double widthPercent, double heightPercent}) async {
    ImageProperties properties = await FlutterNativeImage.getImageProperties(path);

    return await FlutterNativeImage.cropImage(
        path, originX, originY, (widthPercent * properties.width).toInt(), (heightPercent * properties.height).toInt());
  }

  static Future<File> getTempFile(String filename) async {
    var dir = await getTemporaryDirectory();
    return File('$dir/$filename');
  }

  static bool isTheSameAsset(AssetEntity asset, ImageObject image) {
    return (asset.id == image.assetId);
  }

  static Future<ImageObject> getImageInfo(ImageObject img) async {
    // Get image width/height
    if (img.modifiedWidth == null || img.modifiedHeight == null) {
      var bytes = await File(img.modifiedPath).readAsBytes();
      var decodedImg = decodeImage(bytes);
      img.modifiedWidth = decodedImg.width;
      img.modifiedHeight = decodedImg.height;
    }

    return img;
  }

  static applyColorMatrix(Uint8List bytes, List<List<double>> matrixes) {
    for (int i = 0; i < bytes.length; i += 4) {
      var R = bytes[i], G = bytes[i + 1], B = bytes[i + 2], A = bytes[i + 3];

      for (List<double> m in matrixes) {
        var tempR = m[0] * R + m[1] * G + m[2] * B + m[3] * A + m[4];
        var tempG = m[5] * R + m[6] * G + m[7] * B + m[8] * A + m[9];
        var tempB = m[10] * R + m[11] * G + m[12] * B + m[13] * A + m[14];
        var tempA = m[15] * R + m[16] * G + m[17] * B + m[18] * A + m[19];

        R = tempR.toInt();
        G = tempG.toInt();
        B = tempB.toInt();
        A = tempA.toInt();
      }

      bytes[i] = R;
      bytes[i + 1] = G;
      bytes[i + 2] = B;
      bytes[i + 3] = A;
    }
  }
}
