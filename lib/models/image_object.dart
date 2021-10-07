/// Image object using inside this package.
class ImageObject {
  /// Default constructor for the image object using inside this package.
  ImageObject(
      {required this.originalPath,
      required this.modifiedPath,
      this.assetId = "",
      this.modifiedWidth,
      this.modifiedHeight});

  /// Original image path (input image path).
  String originalPath;

  /// Modified image path (output image path).
  String modifiedPath;

  /// Output image width.
  int? modifiedWidth;

  /// Output image height.
  int? modifiedHeight;

  /// Asset id.
  String? assetId;
}
