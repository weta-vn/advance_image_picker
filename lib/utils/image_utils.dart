import 'dart:io';
import 'dart:math';

import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/image_object.dart';

/// Image utilities class.
class ImageUtils {
  /// Get image properties from image file in [path], such as width, height
  static Future<ImageProperties> getImageProperties(String path) async {
    return FlutterNativeImage.getImageProperties(path);
  }

  /// Compare & resize image file in [path].
  /// Pass [quality], [maxWidth], [maxHeight] for output image file.
  static Future<File> compressResizeImage(String path,
      {int quality = 90, int maxWidth = 1080, int maxHeight = 1920}) async {
    // Get image properties
    final ImageProperties properties =
        await FlutterNativeImage.getImageProperties(path);

    // Create output width & height.
    int outputWidth = properties.width!;
    int outputHeight = properties.height!;

    // Re-calculate max width, max height with orientation info.
    int mWidth = maxWidth;
    int mHeight = maxHeight;
    if (properties.orientation == ImageOrientation.rotate90 ||
        properties.orientation == ImageOrientation.rotate270) {
      mWidth = maxHeight;
      mHeight = maxWidth;
    }

    // Re-calculate output width & height by comparing with original size.
    if (outputWidth > mWidth || outputHeight > mHeight) {
      final ratio = outputWidth / outputHeight;
      outputWidth = min(outputWidth, mWidth);
      outputHeight = outputWidth ~/ ratio;
      if (outputHeight > mHeight) {
        outputHeight = min(outputHeight, mHeight);
        outputWidth = (outputHeight * ratio).toInt();
      }

      // Compress output file.
      final File compressedFile = await FlutterNativeImage.compressImage(path,
          quality: quality,
          targetWidth: outputWidth,
          targetHeight: outputHeight);
      return compressedFile;
    }

    return File(path);
  }

  /// Crop image file in [path].
  static Future<File> cropImage(String path,
      {int originX = 0,
      int originY = 0,
      required double widthPercent,
      required double heightPercent}) async {
    // Get image properties.
    final ImageProperties properties =
        await FlutterNativeImage.getImageProperties(path);

    // Get exact image size from properties.
    final int width = properties.width!;
    final int height = properties.height!;

    // Re-calculate crop params with orientation info.
    double wPercent = widthPercent;
    double hPercent = heightPercent;
    if (properties.orientation == ImageOrientation.rotate90 ||
        properties.orientation == ImageOrientation.rotate270) {
      wPercent = heightPercent;
      hPercent = widthPercent;
    }

    // Crop image.
    int x = originX;
    int y = originY;
    if (properties.orientation == ImageOrientation.rotate270) {
      x = ((1.0 - wPercent) * width).toInt();
      y = ((1.0 - hPercent) * height).toInt();
    }
    return FlutterNativeImage.cropImage(
        path, x, y, (wPercent * width).toInt(), (hPercent * height).toInt());
  }

  /// Get temp file created in temporary directory of device.
  static Future<File> getTempFile(String filename) async {
    final dir = await getTemporaryDirectory();
    return File('$dir/$filename');
  }

  /// Check [asset] & [image] file is the same asset or not.
  static bool isTheSameAsset(AssetEntity asset, ImageObject image) {
    return asset.id == image.assetId;
  }

  /// Get image information of image object [img].
  static Future<ImageObject> getImageInfo(ImageObject img) async {
    // Get image width/height
    if (img.modifiedWidth == null || img.modifiedHeight == null) {
      final bytes = await File(img.modifiedPath).readAsBytes();
      final decodedImg = decodeImage(bytes)!;
      img.modifiedWidth = decodedImg.width;
      img.modifiedHeight = decodedImg.height;
    }

    return img;
  }
}
