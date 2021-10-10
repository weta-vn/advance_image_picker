/// Image object using inside this package.
class ImageObject {
  /// Default constructor for the image object using inside this package.
  ImageObject(
      {required this.originalPath,
      required this.modifiedPath,
      this.assetId = "",
      this.modifiedWidth,
      this.modifiedHeight,
      this.recognitions,
      this.label,
      this.ocrText,
      this.ocrOriginalText});

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

  /// Detected results
  List<DetectObject>? recognitions;

  /// Label
  String? label;

  /// OCR text
  String? ocrText;

  /// OCR original text
  String? ocrOriginalText;
}

/// Detected object
class DetectObject {
  /// Label
  String label;

  /// Confidence of the detection
  double? confidence;

  /// X value
  int x;

  /// Y value
  int y;

  /// W value
  int w;

  /// H value
  int h;

  /// Constructor
  DetectObject(
      {required this.label,
      this.confidence,
      this.x = 0,
      this.y = 0,
      this.w = 0,
      this.h = 0});
}
