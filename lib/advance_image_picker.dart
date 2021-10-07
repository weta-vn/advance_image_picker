// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter plugin in pure Dart code for selecting/editing multiple images
/// from the Android/iOS image library and taking new pictures with the
/// camera in the same view.
library advance_image_picker;

/// Image picker configuration.
export 'configs/image_picker_configs.dart';

/// Image model.
export 'models/image_object.dart';

/// Image utilities.
export 'utils/image_utils.dart';

/// Preset image editors
export 'widgets/editors/editor_params.dart';
export 'widgets/editors/image_edit.dart';
export 'widgets/editors/image_filter.dart';
export 'widgets/editors/image_sticker.dart';

/// Advanced image picker widget.
export 'widgets/picker/image_picker.dart';
