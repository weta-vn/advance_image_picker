import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../configs/image_picker_configs.dart';

/// Define ImageEditor parameters.
class EditorParams {
  /// Default constructor for defining ImageEditor parameters.
  EditorParams(
      {required this.title, required this.icon, required this.onEditorEvent});

  /// Title of the image editor.
  final String title;

  /// Icon for the image editor.
  final IconData icon;

  /// Callback function called when the image is edited.
  final Future<File?> Function(
      {required BuildContext context,
      required File file,
      required String title,
      int maxWidth,
      int maxHeight,
      int compressQuality,
      ImagePickerConfigs? configs}) onEditorEvent;
}
