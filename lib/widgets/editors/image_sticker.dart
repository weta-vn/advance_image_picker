import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../../configs/image_picker_configs.dart';
import '../../utils/image_utils.dart';
import '../../utils/time_utils.dart';
import '../common/custom_track_shape.dart';
import '../common/portrait_mode_mixin.dart';

/// Used to add image based sticker icons on library images and photos.
class ImageSticker extends StatefulWidget {
  /// Default constructor for ImageSticker, used to add image based sticker
  /// icons on library images and photos.
  const ImageSticker(
      {final Key? key,
      required this.file,
      required this.title,
      this.configs,
      this.maxWidth = 1080,
      this.maxHeight = 1920})
      : super(key: key);

  /// Input file object.
  final File file;

  /// Title for image edit widget.
  final String title;

  /// Max width.
  final int maxWidth;

  /// Max height.
  final int maxHeight;

  /// Configuration of the image picker.
  final ImagePickerConfigs? configs;

  @override
  _ImageStickerState createState() => _ImageStickerState();
}

class _ImageStickerState extends State<ImageSticker>
    with PortraitStatefulModeMixin<ImageSticker> {
  GlobalKey? _boundaryKey;
  Uint8List? _imageBytes;
  final TransformationController _controller = TransformationController();
  ImagePickerConfigs _configs = ImagePickerConfigs();

  late List<StickerView> _attachedList;
  late List<Image> _stickerList;

  final double _minScale = 0.5;
  final double _maxScale = 2.5;

  StickerView? _selectedStickerView;

  @override
  void initState() {
    super.initState();

    if (widget.configs != null) _configs = widget.configs!;

    _attachedList = [];
    _stickerList = List<int>.generate(34, (index) => index + 1)
        .map((e) => Image.asset(
              'assets/icon/$e.png',
              package: 'advance_image_picker',
            ))
        .toList();

    if (_configs.customStickers.isNotEmpty) {
      if (_configs.customStickerOnly) _stickerList.clear();
      _stickerList.addAll(_configs.customStickers.map((e) => Image.asset(e)));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Read image bytes from file.
  Future<Uint8List?>? _readImage() async {
    return _imageBytes ??= await widget.file.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    _boundaryKey = GlobalKey();

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
      body: Stack(fit: StackFit.passthrough, children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: (_imageBytes == null)
                  ? FutureBuilder(
                      future: _readImage(),
                      builder: (BuildContext context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return _buildImageStack(context);
                        } else {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        }
                      })
                  : _buildImageStack(context),
            ),
            _buildStickerList(context)
          ],
        ),
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
                child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_configs.textImageStickerGuide,
                  style: const TextStyle(color: Colors.white)),
            ))),
        Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: _buildScalingControl(context))
      ]),
    );
  }

  /// Done process button.
  Widget _buildDoneButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.done),
      onPressed: (_selectedStickerView == null)
          ? () async {
              // Save current image editing
              final Uint8List? image =
                  await _exportWidgetToImage(_boundaryKey!);
              if (image != null) {
                // Output to file
                final dir = await path_provider.getTemporaryDirectory();
                final targetPath =
                    "${dir.absolute.path}/temp_${TimeUtils.getTimeString(DateTime.now())}.jpg";
                File file = File(targetPath);
                await file.writeAsBytes(image);

                // Compress & resize result image
                file = await ImageUtils.compressResizeImage(targetPath,
                    maxWidth: widget.maxWidth, maxHeight: widget.maxHeight);
                if (!mounted) return;
                Navigator.of(context).pop(file);
              }
            }
          : null,
    );
  }

  /// Build sticker list panel.
  Widget _buildStickerList(BuildContext context) {
    return Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        height: 120,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          itemCount: _stickerList.length,
          itemBuilder: (BuildContext context, int i) {
            return Padding(
                padding: const EdgeInsets.all(1),
                child: Container(
                  color: Colors.white,
                  child: GestureDetector(
                      onTap: () {
                        _attachSticker(_stickerList[i]);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _stickerList[i],
                      )),
                ));
          },
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2),
        ));
  }

  /// Build image & stickers stack panel.
  Widget _buildImageStack(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return RepaintBoundary(
      key: _boundaryKey,
      child: Listener(
        onPointerDown: (v) async {
          setState(() {
            _selectedStickerView = _getSelectedSticker(v);
          });
        },
        onPointerMove: (v) async {
          setState(() {
            if (_selectedStickerView != null) {
              _selectedStickerView!.top = v.localPosition.dy -
                  (_selectedStickerView!.height *
                          _selectedStickerView!.currentScale) /
                      2;
              _selectedStickerView!.left = v.localPosition.dx -
                  (_selectedStickerView!.width *
                          _selectedStickerView!.currentScale) /
                      2;
            }
          });
        },
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            Container(
              width: size.width,
              height: size.height - 300,
              decoration: BoxDecoration(
                  color: Colors.black,
                  image: DecorationImage(
                      fit: BoxFit.contain, image: MemoryImage(_imageBytes!))),
            ),
            ..._attachedList.map((e) => Positioned(
                top: e.top,
                left: e.left,
                child: e..isFocus = (e == _selectedStickerView))),
          ],
        ),
      ),
    );
  }

  /// Build control to scale selected sticker icon.
  Widget _buildScalingControl(BuildContext context) {
    if (_selectedStickerView == null) return const SizedBox();

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SliderTheme(
        data: SliderThemeData(
          trackShape: CustomTrackShape(),
        ),
        child: Slider(
          min: _minScale,
          max: _maxScale,
          divisions: 40,
          value: _selectedStickerView!.currentScale,
          activeColor: Colors.white,
          inactiveColor: Colors.grey,
          onChanged: (value) async {
            setState(() {
              _selectedStickerView!.currentScale = value;
            });
          },
        ),
      ),
    );
  }

  /// Determine which sticker is selecting.
  StickerView? _getSelectedSticker(PointerEvent event) {
    final result = BoxHitTestResult();

    for (final StickerView s in _attachedList) {
      final RenderBox? box = (s.key! as GlobalKey)
          .currentContext
          ?.findRenderObject() as RenderBox?;
      if (box == null) return null;
      final Offset localBox = box.globalToLocal(event.position);
      if (box.hitTest(result, position: localBox)) {
        return s;
      }
    }
    return null;
  }

  /// Add new sticker to stack.
  void _attachSticker(Image image) {
    setState(() {
      _attachedList.add(StickerView(
        image,
        key: GlobalKey(),
        width: 80,
        height: 80,
        top: 20,
        left: 20,
        onTapRemove: (StickerView sticker) {
          setState(() {
            if (_selectedStickerView != null &&
                _selectedStickerView!.key == sticker.key) {
              _selectedStickerView = null;
            }
            _attachedList.removeWhere((s) => s.key == sticker.key);
          });
        },
      ));
    });
  }

  /// Export image & sticker stack to image bytes.
  Future<Uint8List?>? _exportWidgetToImage(GlobalKey key) async {
    final RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();
    return pngBytes;
  }
}

/// Sticker view.
// TODO(Rydmike): This Widget is not following Flutter recommendations.
//   That is the reason why we must ignore the lint rule. We should consider
//   reviewing the mutable usage here, and make an another implementation.
// ignore: must_be_immutable
class StickerView extends StatefulWidget {
  /// Default constructor for the StickerView.
  StickerView(this.image,
      {Key? key,
      required this.width,
      required this.height,
      this.top = 0.0,
      this.left = 0.0,
      this.currentScale = 1.0,
      this.isFocus = false,
      this.onTapRemove})
      : super(key: key);

  /// The sticker image.
  final Image image;

  /// Sticker width.
  final double width;

  /// Sticker height.
  final double height;

  /// Sticker top location.
  double top;

  /// Sticker left location.
  double left;

  /// Sticker scale.
  double currentScale;

  /// Sticker has focus.
  bool isFocus;

  /// Callback called when the sticker is removed.
  final Function(StickerView sticker)? onTapRemove;

  @override
  _StickerViewState createState() => _StickerViewState();
}

class _StickerViewState extends State<StickerView> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          widget.onTapRemove?.call(widget);
        });
      },
      child: Container(
          decoration: BoxDecoration(
            border: widget.isFocus
                ? Border.all(color: Colors.pinkAccent, width: 3)
                : null,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          width: widget.width * widget.currentScale,
          height: widget.height * widget.currentScale,
          child: widget.image),
    );
  }
}
