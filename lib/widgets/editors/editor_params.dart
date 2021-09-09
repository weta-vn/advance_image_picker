import 'dart:io';

import '../../configs/image_picker_configs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class EditorParams {
  EditorParams(
      {required this.title, required this.icon, required this.onEditorEvent});

  final String title;
  final IconData icon;
  final Future<File?> Function({required BuildContext context, required File file, required String title, int maxWidth, int maxHeight, int compressQuality, ImagePickerConfigs? configs}) onEditorEvent;
}
