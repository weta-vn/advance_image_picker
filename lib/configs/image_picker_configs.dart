import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ImagePickerConfigs {
  static final ImagePickerConfigs _singleton = ImagePickerConfigs._internal();
  factory ImagePickerConfigs() {
    return _singleton;
  }
  ImagePickerConfigs._internal();

  // Functions
  String Function(String, String) translateFunc;

  // Image settings
  int albumGridCount = 4;
  int thumbWidth = 80;
  int thumbHeight = 80;
  int albumThumbWidth = 200;
  int albumThumbHeight = 200;
  int maxWidth = 1920;
  int maxHeight = 1080;
  int compressQuality = 90;
  ResolutionPreset resolutionPreset = ResolutionPreset.high;
  bool imagePreProcessingEnabled = true;
  bool imagePreProcessingBeforeEditingEnabled = true;
  bool showDeleteButtonOnSelectedList = true;
  bool showNonSelectedAlert = true;
  bool cropFeatureEnabled = true;
  bool filterFeatureEnabled = true;
  bool adjustFeatureEnabled = true;
  bool stickerFeatureEnabled = true;
  bool addTextFeatureEnabled = true;

  // UI style settings
  Color backgroundColor = Colors.black;
  Color bottomPanelColor = Colors.black;
  Color bottomPanelColorInFullscreen = Colors.black.withOpacity(0.3);
  Color appBarTextColor = Colors.white;
  Color appBarDoneButtonColor = Colors.blue;

  // UI label strings (for localization)
  String get textSelectedImagesTitle => translateFunc("image_picker_select_images_title", "Selected images count");
  String get textSelectedImagesGuide =>
      translateFunc("image_picker_select_images_guide", "You can drag images for sorting list...");
  String get textCameraTitle => translateFunc("image_picker_camera_title", "Camera");
  String get textAlbumTitle => translateFunc("image_picker_album_title", "Album");
  String get textPreviewTitle => translateFunc("image_picker_preview_title", "Preview");
  String get textConfirm => translateFunc("image_picker_confirm", "Confirm");
  String get textConfirmExitWithoutSelectingImages =>
      translateFunc("image_picker_exit_without_selecting", "Do you want to exit without selecting images?");
  String get textConfirmDelete => translateFunc("image_picker_confirm_delete", "Do you want to delete this image?");
  String get textConfirmResetChanges =>
      translateFunc("image_picker_confirm_reset_changes", "Do you want to clear all changes for this image?");
  String get textYes => translateFunc("yes", "Yes");
  String get textNo => translateFunc("no", "No");
  String get textSave => translateFunc("save", "Save");
  String get textClear => translateFunc("clear", "Clear");
  String get textEditText => translateFunc("image_picker_edit_text", "Edit text");
  String get textNoImages => translateFunc("image_picker_no_images", "No images ...");
  String get textImageCropTitle => translateFunc("image_picker_image_crop_title", "Image crop");
  String get textImageFilterTitle => translateFunc("image_picker_image_filter_title", "Image filter");
  String get textImageEditTitle => translateFunc("image_picker_image_edit_title", "Image edit");
  String get textImageStickerTitle => translateFunc("image_picker_image_sticker_title", "Image sticker");
  String get textImageAddTextTitle => translateFunc("image_picker_image_addtext_title", "Image add text");
  String get textSelectButtonTitle => translateFunc("image_picker_select_button_title", "Select");
  String get textImageStickerGuide => translateFunc("image_picker_image_sticker_guide",
      "You can click on below icons to add into image, double click to remove it from image");

  String getTranslatedString(String name, String defaultValue) {
    return translateFunc?.call(name, defaultValue) ?? defaultValue;
  }
}
