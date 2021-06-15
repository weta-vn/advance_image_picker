import 'dart:io';
import 'dart:math';

import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/image_object.dart';

class ImageUtils {
  static Future<ImageProperties> getImageProperties(String path) async {
    return await FlutterNativeImage.getImageProperties(path);
  }

  static Future<File> compressResizeImage(String path,
      {int quality = 90, int maxWidth = 1920, int maxHeight = 1080}) async {
    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(path);

    var outputWidth = properties.width;
    var outputHeight = properties.height;

    if (properties.width! > maxWidth || properties.height! > maxHeight) {
      var ratio = properties.width! / properties.height!;
      outputWidth = min(properties.width!, maxWidth);
      outputHeight = outputWidth ~/ ratio;
      if (outputHeight > maxHeight) {
        outputHeight = min(properties.height!, maxHeight);
        outputWidth = (outputHeight * ratio).toInt();
      }

      File compressedFile = await FlutterNativeImage.compressImage(path,
          quality: quality,
          targetWidth: outputWidth,
          targetHeight: outputHeight);
      return compressedFile;
    }

    return File(path);
  }

  static Future<File> cropImage(String path,
      {int originX = 0,
      int originY = 0,
      required double widthPercent,
      required double heightPercent}) async {
    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(path);

    return await FlutterNativeImage.cropImage(
        path,
        originX,
        originY,
        (widthPercent * properties.width!).toInt(),
        (heightPercent * properties.height!).toInt());
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
      var bytes = await File(img.modifiedPath!).readAsBytes();
      var decodedImg = decodeImage(bytes)!;
      img.modifiedWidth = decodedImg.width;
      img.modifiedHeight = decodedImg.height;
    }

    return img;
  }
}
