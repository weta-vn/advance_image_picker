import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
  /// Singleton object of config
  static final ImagePickerConfigs _singleton = ImagePickerConfigs._internal();
  factory ImagePickerConfigs() {
    return _singleton;
  }
  ImagePickerConfigs._internal();

  /// UI labels translated function with 2 parameters [name] and [defaultValue]
  /// Declare [name] for what label needs to be translated in localization file, such as image_picker_select_images_title
  /// Confirm "UI label strings (for localization)" section below for understanding usage
  ///
  /// Sample usage
  /// If using Intl, function like this: configs.translateFunc = (name, value) => Intl.message(value, name: name);
  /// If using GetX, function like this: configs.translateFunc = (name, value) => name.tr;
  late String Function(String, String) translateFunc;

  /// Grid count for photo album grid view
  int albumGridCount = 4;

  /// Thumbnail image width
  int thumbWidth = 80;

  /// Thumbnail image height
  int thumbHeight = 80;

  /// Thumbnail image width inside album grid view
  int albumThumbWidth = 200;

  /// Thumbnail image height inside album grid view
  int albumThumbHeight = 200;

  /// Max width for output
  int maxWidth = 1920;

  /// Max height for output
  int maxHeight = 1080;

  /// Quality for output
  int compressQuality = 90;

  /// Resolution setting for camera, such as high, max, medium, low
  ResolutionPreset resolutionPreset = ResolutionPreset.high;

  /// Enable this option allow image pre-processing, such as cropping, ... after inputting
  bool imagePreProcessingEnabled = true;

  /// Enable this option allow image pre-processing, such as cropping, ... after editing
  bool imagePreProcessingBeforeEditingEnabled = true;

  /// Show delete button on selected list
  bool showDeleteButtonOnSelectedList = true;

  /// Show confirm alert if exiting with selected image
  bool showNonSelectedAlert = true;

  /// Enable image crop/rotation/scale function
  bool cropFeatureEnabled = true;

  /// Enable image filter function
  bool filterFeatureEnabled = true;

  /// Enable image ajusting function
  bool adjustFeatureEnabled = true;

  /// Enable sticker adding function
  bool stickerFeatureEnabled = true;

  /// UI style settings
  Color backgroundColor = Colors.black;
  Color bottomPanelColor = Colors.black;
  Color bottomPanelColorInFullscreen = Colors.black.withOpacity(0.3);
  Color appBarTextColor = Colors.white;
  Color appBarDoneButtonColor = Colors.blue;

  /// UI label strings (for localization)
  String get textSelectedImagesTitle => getTranslatedString(
      "image_picker_select_images_title", "Selected images count");
  String get textSelectedImagesGuide => getTranslatedString(
      "image_picker_select_images_guide",
      "You can drag images for sorting list...");
  String get textCameraTitle =>
      getTranslatedString("image_picker_camera_title", "Camera");
  String get textAlbumTitle =>
      getTranslatedString("image_picker_album_title", "Album");
  String get textPreviewTitle =>
      getTranslatedString("image_picker_preview_title", "Preview");
  String get textConfirm =>
      getTranslatedString("image_picker_confirm", "Confirm");
  String get textConfirmExitWithoutSelectingImages => translateFunc(
      "image_picker_exit_without_selecting",
      "Do you want to exit without selecting images?");
  String get textConfirmDelete => getTranslatedString(
      "image_picker_confirm_delete", "Do you want to delete this image?");
  String get textConfirmResetChanges => getTranslatedString(
      "image_picker_confirm_reset_changes",
      "Do you want to clear all changes for this image?");
  String get textYes => getTranslatedString("yes", "Yes");
  String get textNo => getTranslatedString("no", "No");
  String get textSave => getTranslatedString("save", "Save");
  String get textClear => getTranslatedString("clear", "Clear");
  String get textEditText =>
      getTranslatedString("image_picker_edit_text", "Edit text");
  String get textNoImages =>
      getTranslatedString("image_picker_no_images", "No images ...");
  String get textImageCropTitle =>
      getTranslatedString("image_picker_image_crop_title", "Image crop");
  String get textImageFilterTitle =>
      getTranslatedString("image_picker_image_filter_title", "Image filter");
  String get textImageEditTitle =>
      getTranslatedString("image_picker_image_edit_title", "Image edit");
  String get textImageStickerTitle =>
      getTranslatedString("image_picker_image_sticker_title", "Image sticker");
  String get textImageAddTextTitle =>
      getTranslatedString("image_picker_image_addtext_title", "Image add text");
  String get textSelectButtonTitle =>
      getTranslatedString("image_picker_select_button_title", "Select");
  String get textImageStickerGuide => getTranslatedString(
      "image_picker_image_sticker_guide",
      "You can click on below icons to add into image, double click to remove it from image");

  /// Translate string by translateFunc
  String getTranslatedString(String name, String defaultValue) {
    return translateFunc.call(name, defaultValue);
  }
}
