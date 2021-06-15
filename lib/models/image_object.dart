class ImageObject {
  String? originalPath;
  String? modifiedPath;
  int? modifiedWidth;
  int? modifiedHeight;
  String assetId;

  ImageObject(
      {this.originalPath,
      this.modifiedPath,
      this.assetId = "",
      this.modifiedWidth,
      this.modifiedHeight});
}
