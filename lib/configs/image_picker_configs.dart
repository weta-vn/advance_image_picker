import 'dart:core';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/image_object.dart';
import '../widgets/editors/editor_params.dart';

export 'package:camera/camera.dart' show FlashMode;

/// Enum used to define the type of used done button by the image picker.
enum DoneButtonStyle {
  /// Use an [OutlinedButton].
  outlinedButton,

  /// Use an [IconButton].
  iconButton,
}

/// Enum used to define the type of of behavior the done button has when
/// no images have been selected that will be returned.
enum DoneButtonDisabledBehavior {
  /// Done button is disabled
  disabled,

  /// Done button is hidden and not shown at all.
  hidden,
}

/// Global configuration for flutter app using advance_image_picker plugin
/// Call once inside application before using image picker functions
///
/// Sample usage
/// Calling in build function of app widget at main.dart
/// ```dart
/// var configs = ImagePickerConfigs();
/// configs.appBarTextColor = Colors.black;
/// configs.translateFunc = (name, value) => Intl.message(value, name: name);
/// ```
class ImagePickerConfigs {
  /// The default constructor is a factory that returns the configuration
  /// singleton of the picker configuration.
  ///
  /// Global configuration for flutter app using advance_image_picker plugin
  /// Call once inside application before using image picker functions
  ///
  /// Sample usage
  /// Calling in build function of app widget at main.dart
  /// ```dart
  /// var configs = ImagePickerConfigs();
  /// configs.appBarTextColor = Colors.black;
  /// configs.translateFunc = (name, value) => Intl.message(value, name: name);
  /// ```
  factory ImagePickerConfigs() {
    return _singleton;
  }
  ImagePickerConfigs._internal();

  /// Singleton object for holding the image picker configuration settings.
  static final ImagePickerConfigs _singleton = ImagePickerConfigs._internal();

  /// UI labels translated function with 2 parameters `name` and `defaultValue`
  /// Declare `name` for what label needs to be translated in localization file,
  /// such as image_picker_select_images_title. Confirm "UI label strings
  /// (for localization)" section below for understanding usage.
  ///
  /// Sample usage:
  ///
  /// If using Intl, function like this:
  /// configs.translateFunc = (name, value) => Intl.message(value, name: name);
  /// If using GetX, function like this:
  /// configs.translateFunc = (name, value) => name.tr;
  late String Function(String, String) translateFunc;

  /// Grid count for photo album grid view.
  ///
  /// Defaults to 4.
  int albumGridCount = 4;

  /// Thumbnail image width.
  ///
  /// Defaults to 80.
  int thumbWidth = 80;

  /// Thumbnail image height.
  ///
  /// Defaults to 80.
  int thumbHeight = 80;

  /// Thumbnail image width inside album grid view.
  ///
  /// Defaults to 200.
  int albumThumbWidth = 200;

  /// Thumbnail image height inside album grid view.
  ///
  /// Defaults to 200.
  int albumThumbHeight = 200;

  /// Max width for output.
  ///
  /// Defaults to 1080.
  int maxWidth = 1080;

  /// Max height for output.
  ///
  /// Defaults to 1920.
  int maxHeight = 1920;

  /// Quality for output.
  ///
  /// Defaults to 90%.
  int compressQuality = 90;

  /// Resolution setting for camera, such as high, max, medium, low.
  ///
  /// Defaults to [ResolutionPreset.high].
  ResolutionPreset resolutionPreset = ResolutionPreset.high;

  /// Enable this option allow image pre-processing, such as cropping,
  /// ... after inputting
  ///
  /// Defaults to true.
  bool imagePreProcessingEnabled = true;

  /// Enable this option to allow image pre-processing, such as cropping,
  /// after editing.
  ///
  /// Defaults to true.
  bool imagePreProcessingBeforeEditingEnabled = true;

  /// Show delete button on selected list.
  ///
  /// Defaults to true.
  bool showDeleteButtonOnSelectedList = true;

  /// Show confirm alert if removing an already selected image.
  ///
  /// Defaults to true.
  bool showRemoveImageAlert = true;

  /// Show confirm alert if exiting with selected image.
  ///
  /// Defaults to true.
  bool showNonSelectedAlert = true;

  /// Enable image crop/rotation/scale function.
  ///
  /// Defaults to true.
  bool cropFeatureEnabled = true;

  /// Enable image filter function.
  ///
  /// Defaults to true.
  bool filterFeatureEnabled = true;

  /// Enable image adjusting function.
  ///
  /// Defaults to true.
  bool adjustFeatureEnabled = true;

  /// Enable sticker adding function.
  ///
  /// Defaults to true.
  bool stickerFeatureEnabled = true;

  // Picker mode settings.

  /// Enable camera as image source.
  ///
  /// Defaults to true.
  bool cameraPickerModeEnabled = true;

  /// Enable device image album as image source.
  ///
  /// Defaults to true.
  bool albumPickerModeEnabled = true;

  /// Detect labels from image function
  Future<List<DetectObject>> Function(String path)? labelDetectFunc;

  /// Max count for label detection
  int labelDetectMaxCount = 5;

  /// Threshold for label detection
  double labelDetectThreshold = 0.7;

  /// Detect OCR from image function
  Future<String> Function(String path, {bool? isCloudService})? ocrExtractFunc;

  /// Custom sticker only flag
  ///
  /// Defaults to false.
  bool customStickerOnly = false;

  /// Custom sticker paths
  List<String> customStickers = [];

  /// Camera direction setting.
  ///
  /// Options:
  ///
  /// * null: use all available camera (default)
  /// * 0: only use front camera
  /// * 1: only use back camera
  int? cameraLensDirection;

  /// Show the lens direction toggle icon button.
  ///
  /// If you want to show only one camera, you may also want to hide the
  /// button than enables users switch camera, then set [showLensDirection]
  /// to false.
  ///
  /// If you show just one [cameraLensDirection] and [showLensDirection] is
  /// true, then the lens direction button is still shown, but disabled.
  ///
  /// Defaults to true.
  bool showLensDirection = true;

  /// Set the default flash mode.
  ///
  /// Options:
  /// * off: Do not use the flash when taking a picture.
  /// * auto: Device decide whether to flash the camera when taking a picture.
  /// * always: Always use the flash when taking a picture.
  /// * torch: In this app treated the same as using always.
  ///
  /// Defaults to [FlashMode.auto].
  FlashMode flashMode = FlashMode.auto;

  /// Show the flash mode icon button.
  ///
  /// If you want to set the FlashMode to a certain mode, typically
  /// [FlashMode.off], and also hide the button than enables users to
  /// change it, then set [showFlashMode] to false.
  ///
  /// Defaults to true.
  bool showFlashMode = true;

  // UI style settings.

  /// Background color of the camera and image picker.
  ///
  /// Defaults to [Colors.black].
  Color backgroundColor = Colors.black;

  /// Background color of the bottom section of the camera.
  ///
  /// Defaults to [Colors.black].
  Color bottomPanelColor = Colors.black;

  /// Background color of the bottom section of the camera when it is used
  /// in full screen mode.
  ///
  /// Defaults to [Colors.black] with 30% opacity.
  Color bottomPanelColorInFullscreen = Colors.black.withOpacity(0.3);

  /// The background color of the [AppBar] in the image picker.
  ///
  /// Defaults to null.
  /// This results in an AppBar background color that follows current theme.
  Color? appBarBackgroundColor;

  /// The text or foreground color of the [AppBar] in the image picker.
  ///
  /// Defaults to null.
  /// This results in an AppBar text color that follows current theme.
  Color? appBarTextColor;

  /// The background color of the image selection completed button.
  ///
  /// This color only applies to the [doneButtonStyle] of style
  /// [DoneButtonStyle.outlinedButton].
  ///
  /// Defaults to null.
  /// This results in [appBarBackgroundColor] being used.
  Color? appBarDoneButtonColor;

  /// The type of button used on the image picker to select images and close
  /// the image picker.
  ///
  /// The default is [DoneButtonStyle.outlinedButton].
  ///
  /// The alternate style [DoneButtonStyle.iconButton] uses an [IconButton] that
  /// is typically used in [AppBar] actions.
  DoneButtonStyle doneButtonStyle = DoneButtonStyle.outlinedButton;

  /// IconData used by the done button when [doneButtonStyle] is
  /// [DoneButtonStyle.iconButton].
  ///
  /// Defaults to Icon.check.
  IconData doneButtonIcon = Icons.check;

  /// Used to define the type of of behavior the done button has when
  /// no images have been selected that will be returned.
  ///
  /// Defaults to [DoneButtonDisabledBehavior.disabled].
  DoneButtonDisabledBehavior doneButtonDisabledBehavior =
      DoneButtonDisabledBehavior.disabled;

  /// Allow add custom image editors from external call.
  ///
  /// Sample usage:
  ///
  /// configs.externalImageEditors['external_image_editor'] = EditorParams(
  ///   title: 'external_image_editor',
  ///   icon: Icons.wb_sunny_outlined,
  ///   onEditorEvent: (
  ///      {required File file,
  ///       required String title,
  ///       int maxWidth = 1080,
  ///       int maxHeight = 1920,
  ///       ImagePickerConfigs? configs}) async => await
  ///         Navigator.of(context).push(MaterialPageRoute<File>(
  ///       fullscreenDialog: true,
  ///       builder: (context) => ImageEdit(file: file, title: title,
  ///         maxWidth: maxWidth, maxHeight: maxHeight, configs: _configs)))
  Map<String, EditorParams> externalImageEditors = {};

  // UI label strings (for localization)

  /// Get localized text for label "image_picker_select_images_title".
  ///
  /// Defaults to "Selected images count".
  String get textSelectedImagesTitle => getTranslatedString(
      "image_picker_select_images_title", "Selected images count");

  /// Get localized text for label "image_picker_select_images_guide".
  ///
  /// Defaults to "You can drag images for sorting list...".
  String get textSelectedImagesGuide => getTranslatedString(
      "image_picker_select_images_guide",
      "You can drag images for sorting list...");

  /// Get localized text for label "image_picker_camera_title".
  ///
  /// Defaults to "Camera".
  String get textCameraTitle =>
      getTranslatedString("image_picker_camera_title", "Camera");

  /// Get localized text for label "image_picker_album_title".
  ///
  /// Defaults to "Album".
  String get textAlbumTitle =>
      getTranslatedString("image_picker_album_title", "Album");

  /// Get localized text for label "image_picker_preview_title".
  ///
  /// Defaults to "Preview".
  String get textPreviewTitle =>
      getTranslatedString("image_picker_preview_title", "Preview");

  /// Get localized text for label "image_picker_confirm".
  ///
  /// Defaults to "Confirm".
  String get textConfirm =>
      getTranslatedString("image_picker_confirm", "Confirm");

  /// Get localized text for label "image_picker_exit_without_selecting".
  ///
  /// Defaults to "Do you want to exit without selecting images?".
  String get textConfirmExitWithoutSelectingImages => translateFunc(
      "image_picker_exit_without_selecting",
      "Do you want to exit without selecting images?");

  /// Get localized text for label "image_picker_confirm_delete".
  ///
  /// Defaults to "Do you want to delete this image?".
  String get textConfirmDelete => getTranslatedString(
      "image_picker_confirm_delete", "Do you want to delete this image?");

  /// Get localized text for label "image_picker_confirm_reset_changes".
  ///
  /// Defaults to "Do you want to clear all changes for this image?".
  String get textConfirmResetChanges => getTranslatedString(
      "image_picker_confirm_reset_changes",
      "Do you want to clear all changes for this image?");

  /// Get localized text for label "yes".
  ///
  /// Defaults to "Yes".
  String get textYes => getTranslatedString("yes", "Yes");

  /// Get localized text for label "no".
  ///
  /// Defaults to "No".
  String get textNo => getTranslatedString("no", "No");

  /// Get localized text for label "save".
  ///
  /// Defaults to "Save".
  String get textSave => getTranslatedString("save", "Save");

  /// Get localized text for label "clear".
  ///
  /// Defaults to "Clear".
  String get textClear => getTranslatedString("clear", "Clear");

  /// Get localized text for label "image_picker_edit_text".
  ///
  /// Defaults to "Edit text".
  String get textEditText =>
      getTranslatedString("image_picker_edit_text", "Edit text");

  /// Get localized text for label "image_picker_no_images".
  ///
  /// Defaults to "No images ...".
  String get textNoImages =>
      getTranslatedString("image_picker_no_images", "No images ...");

  /// Get localized text for label "image_picker_image_crop_title".
  ///
  /// Defaults to "Image crop".
  String get textImageCropTitle =>
      getTranslatedString("image_picker_image_crop_title", "Image crop");

  /// Get localized text for label "image_picker_image_filter_title".
  ///
  /// Defaults to "Image filter".
  String get textImageFilterTitle =>
      getTranslatedString("image_picker_image_filter_title", "Image filter");

  /// Get localized text for label "image_picker_image_edit_title".
  ///
  /// Defaults to "Image edit".
  String get textImageEditTitle =>
      getTranslatedString("image_picker_image_edit_title", "Image edit");

  /// Get localized text for label "image_picker_image_sticker_title".
  ///
  /// Defaults to "Image sticker".
  String get textImageStickerTitle =>
      getTranslatedString("image_picker_image_sticker_title", "Image sticker");

  /// Get localized text for label "image_picker_image_addtext_title".
  ///
  /// Defaults to "Image add text".
  String get textImageAddTextTitle =>
      getTranslatedString("image_picker_image_addtext_title", "Image add text");

  /// Get localized text for label "image_picker_select_button_title".
  ///
  /// Defaults to "Select".
  String get textSelectButtonTitle =>
      getTranslatedString("image_picker_select_button_title", "Select");

  /// Get localized text for label "image_picker_image_sticker_guide".
  ///
  /// Defaults to "You can click on below icons to add into image, double
  /// click to remove it from image".
  String get textImageStickerGuide => getTranslatedString(
      "image_picker_image_sticker_guide",
      "You can click on sticker icons to scale it or double click to "
          "remove it from image");

  /// Get localized text for label "image_picker_exposure_title".
  ///
  /// Defaults to "Exposure".
  String get textExposure =>
      getTranslatedString("image_picker_exposure_title", "Exposure");

  /// Get localized text for label "image_picker_exposure_locked_title".
  ///
  /// Defaults to "Locked".
  String get textExposureLocked =>
      getTranslatedString("image_picker_exposure_locked_title", "Locked");

  /// Get localized text for label "image_picker_exposure_auto_title".
  ///
  /// Defaults to "auto".
  String get textExposureAuto =>
      getTranslatedString("image_picker_exposure_auto_title", "auto");

  /// Get localized text for label "image_picker_image_edit_contrast".
  ///
  /// Defaults to "contrast".
  String get textContrast =>
      getTranslatedString("image_picker_image_edit_contrast", "contrast");

  /// Get localized text for label "image_picker_image_edit_brightness".
  ///
  /// Defaults to "brightness".
  String get textBrightness =>
      getTranslatedString("image_picker_image_edit_brightness", "brightness");

  /// Get localized text for label "image_picker_image_edit_saturation".
  ///
  /// Defaults to "saturation".
  String get textSaturation =>
      getTranslatedString("image_picker_image_edit_saturation", "saturation");

  /// Get localized text for label "image_picker_ocr".
  ///
  /// Defaults to "OCR".
  String get textOCR => getTranslatedString("image_picker_ocr", "OCR");

  /// Get localized text for label "image_picker_request_permission".
  ///
  /// Defaults to "Request Permission".
  String get textRequestPermission => getTranslatedString(
      "image_picker_request_permission", "Request Permission");

  /// Get localized text for label "image_picker_request_camera_permission".
  ///
  /// Defaults to "You need allow camera permission.".
  String get textRequestCameraPermission => getTranslatedString(
      "image_picker_request_camera_permission",
      "You need allow camera permission.");

  /// Get localized text for label "image_picker_request_gallery_permission".
  ///
  /// Defaults to "You need allow photo gallery permission.".
  String get textRequestGalleryPermission => getTranslatedString(
      "image_picker_request_gallery_permission",
      "You need allow photo gallery permission.");

  /// Translate string by translateFunc.
  String getTranslatedString(String name, String defaultValue) {
    return translateFunc.call(name, defaultValue);
  }
}
