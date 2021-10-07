import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_editor/image_editor.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../../configs/image_picker_configs.dart';
import '../../utils/time_utils.dart';
import '../common/custom_track_shape.dart';
import '../common/portrait_mode_mixin.dart';

/// Image editing widget, such as cropping, rotating and scaling.
class ImageEdit extends StatefulWidget {
  /// Default constructor for the image editing widget.
  const ImageEdit(
      {final Key? key,
      required this.file,
      required this.title,
      this.configs,
      this.maxWidth = 1080,
      this.maxHeight = 1920})
      : super(key: key);

  @override
  _ImageEditState createState() => _ImageEditState();

  /// Input file object.
  final File file;

  /// Title for image edit widget.
  final String title;

  /// Max width.
  final int maxWidth;

  /// Max height.
  final int maxHeight;

  /// Configuration.
  final ImagePickerConfigs? configs;
}

class _ImageEditState extends State<ImageEdit>
    with PortraitStatefulModeMixin<ImageEdit> {
  double _contrast = 0;
  double _brightness = 0;
  double _saturation = 0;
  Uint8List? _imageBytes;
  Uint8List? _orgImageBytes;
  final List<double> _contrastValues = [0];
  final List<double> _brightnessValues = [0];
  final List<double> _saturationValues = [0];
  bool _isProcessing = false;
  bool _controlExpanded = true;
  ImagePickerConfigs _configs = ImagePickerConfigs();

  @override
  void initState() {
    super.initState();
    if (widget.configs != null) _configs = widget.configs!;
  }

  @override
  void dispose() {
    _contrastValues.clear();
    _brightnessValues.clear();
    _saturationValues.clear();
    super.dispose();
  }

  Future<Uint8List?>? _readImage() async {
    _orgImageBytes ??= await widget.file.readAsBytes();
    return _imageBytes ??= Uint8List.fromList(_orgImageBytes!);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Use theme based AppBar colors if config values are not defined.
    // The logic is based on same approach that is used in AppBar SDK source.
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppBarTheme appBarTheme = AppBarTheme.of(context);
    final Color _appBarBackgroundColor = _configs.appBarBackgroundColor ??
        appBarTheme.backgroundColor ??
        (colorScheme.brightness == Brightness.dark
            ? colorScheme.surface
            : colorScheme.primary);
    final Color _appBarTextColor = _configs.appBarTextColor ??
        appBarTheme.foregroundColor ??
        (colorScheme.brightness == Brightness.dark
            ? colorScheme.onSurface
            : colorScheme.onPrimary);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: _appBarBackgroundColor,
        foregroundColor: _appBarTextColor,
        actions: <Widget>[_buildDoneButton(context)],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: _buildImageViewer(context)),
          _buildAdjustControls(context)
        ],
      ),
    );
  }

  Widget _buildAdjustControls(BuildContext context) {
    const textStyle = TextStyle(color: Colors.white, fontSize: 10);

    if (_controlExpanded) {
      return Container(
        color: const Color(0xFF212121),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _controlExpanded = false;
                });
              },
              child: Row(
                  children: const [Spacer(), Icon(Icons.keyboard_arrow_down)]),
            ),
            const Divider(),
            _buildContrastAdjustControl(context),
            _buildBrightnessAdjustControl(context),
            _buildSaturationAdjustControl(context)
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: () {
          setState(() {
            _controlExpanded = true;
          });
        },
        child: Container(
            color: const Color(0xFF212121),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      "${_configs.textContrast}: "
                      "${_contrast.toString()}",
                      style: textStyle),
                  Text("${_configs.textBrightness}: ${_brightness.toString()}",
                      style: textStyle),
                  Text("${_configs.textSaturation}: ${_saturation.toString()}",
                      style: textStyle),
                  const Icon(Icons.keyboard_arrow_up)
                ])),
      );
    }
  }

  Widget _buildDoneButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.done),
      onPressed: () async {
        final dir = await path_provider.getTemporaryDirectory();
        final targetPath = "${dir.absolute.path}/temp_"
            "${TimeUtils.getTimeString(DateTime.now())}.jpg";
        final File file = File(targetPath);
        await file.writeAsBytes(_imageBytes!);
        if (!mounted) return;
        Navigator.of(context).pop(file);
      },
    );
  }

  Widget _buildImageViewer(BuildContext context) {
    Widget imageView() => Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black,
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        );

    if (_imageBytes == null) {
      return FutureBuilder(
          future: _readImage(),
          builder: (BuildContext context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return imageView();
            } else {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }
          });
    } else {
      return imageView();
    }
  }

  Future<void> _processImage() async {
    if (_isProcessing) return;

    if (_contrastValues.length > 1 ||
        _brightnessValues.length > 1 ||
        _saturationValues.length > 1) {
      _isProcessing = true;

      // Get last value
      final contrast = _contrastValues.last;
      final brightness = _brightnessValues.last;
      final saturation = _saturationValues.last;

      // Remove old values
      if (_contrastValues.length > 1) {
        _contrastValues.removeRange(0, _contrastValues.length - 1);
      }
      if (_brightnessValues.length > 1) {
        _brightnessValues.removeRange(0, _brightnessValues.length - 1);
      }
      if (_saturationValues.length > 1) {
        _saturationValues.removeRange(0, _saturationValues.length - 1);
      }

      await _processImageWithOptions(contrast, brightness, saturation)
          .then((value) {
        _isProcessing = false;

        setState(() {
          _imageBytes = value;
        });

        // Run process image again
        _processImage();
      });
    }
  }

  Future<Uint8List?> _processImageWithOptions(
      double contrast, double brightness, double saturation) async {
    final ImageEditorOption option = ImageEditorOption();
    option.addOption(ColorOption.brightness(_calColorOptionValue(brightness)));
    option.addOption(ColorOption.contrast(_calColorOptionValue(contrast)));
    option.addOption(ColorOption.saturation(_calColorOptionValue(saturation)));
    return ImageEditor.editImage(
        image: _orgImageBytes!, imageEditorOption: option);
  }

  double _calColorOptionValue(double value) {
    return (value / 10.0) + 1.0;
  }

  Widget _buildContrastAdjustControl(BuildContext context) {
    const textStyle = TextStyle(color: Colors.white, fontSize: 10);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(_configs.textContrast, style: textStyle),
          const Spacer(),
          Text(_contrast.toString(), style: textStyle)
        ]),
        SliderTheme(
          data: SliderThemeData(
            trackShape: CustomTrackShape(),
          ),
          child: Slider(
            min: -10,
            max: 10,
            divisions: 40,
            value: _contrast,
            activeColor: Colors.white,
            inactiveColor: Colors.grey,
            onChanged: (value) async {
              if (_contrast != value) {
                setState(() {
                  _contrast = value;
                });
                _contrastValues.add(value);
                await _processImage();
              }
            },
          ),
        )
      ]),
    );
  }

  Widget _buildBrightnessAdjustControl(BuildContext context) {
    const textStyle = TextStyle(color: Colors.white, fontSize: 10);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(_configs.textBrightness, style: textStyle),
          const Spacer(),
          Text(_brightness.toString(), style: textStyle)
        ]),
        SliderTheme(
          data: SliderThemeData(
            trackShape: CustomTrackShape(),
          ),
          child: Slider(
            min: -10,
            max: 10,
            divisions: 40,
            value: _brightness,
            activeColor: Colors.white,
            inactiveColor: Colors.grey,
            onChanged: (value) async {
              if (_brightness != value) {
                setState(() {
                  _brightness = value;
                });
                _brightnessValues.add(value);
                await _processImage();
              }
            },
          ),
        )
      ]),
    );
  }

  Widget _buildSaturationAdjustControl(BuildContext context) {
    const textStyle = TextStyle(color: Colors.white, fontSize: 10);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(_configs.textSaturation, style: textStyle),
          const Spacer(),
          Text(_saturation.toString(), style: textStyle)
        ]),
        SliderTheme(
          data: SliderThemeData(
            trackShape: CustomTrackShape(),
          ),
          child: Slider(
            min: -10,
            max: 10,
            divisions: 40,
            value: _saturation,
            activeColor: Colors.white,
            inactiveColor: Colors.grey,
            onChanged: (value) async {
              if (_saturation != value) {
                setState(() {
                  _saturation = value;
                });
                _saturationValues.add(value);
                await _processImage();
              }
            },
          ),
        )
      ]),
    );
  }
}
