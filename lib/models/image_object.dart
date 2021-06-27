/// Image object using inside this package
class ImageObject {
  /// Original image path (input image path)
  String originalPath;

  /// Modified image path (output image path)
  String modifiedPath;

  /// Output image width
  int? modifiedWidth;

  /// Output image height
  int? modifiedHeight;

  /// Asset id
  String? assetId;

  ImageObject(
      {required this.originalPath,
      required this.modifiedPath,
      this.assetId = "",
      this.modifiedWidth,
      this.modifiedHeight});
}
