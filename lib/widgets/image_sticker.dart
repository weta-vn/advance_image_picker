import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart' as PathProvider;

import '../configs/image_picker_configs.dart';
import '../utils/image_utils.dart';
import 'custom_track_shape.dart';
import 'portrait_mode_mixin.dart';

/// Image sticker width allow adding sticker icon into image
class ImageSticker extends StatefulWidget {
  /// Image object
  final File file;

  /// Title for widget
  final String title;

  /// Max output width
  final int maxWidth;

  /// Max output height
  final int maxHeight;

  /// Configuration
  final ImagePickerConfigs? configs;

  ImageSticker({required this.file, required this.title, this.maxWidth = 1080, this.maxHeight = 1920, this.configs});

  @override
  _ImageStickerState createState() => _ImageStickerState();
}

class _ImageStickerState extends State<ImageSticker> with PortraitStatefulModeMixin<ImageSticker> {
  GlobalKey? _boundaryKey;
  Uint8List? _imageBytes;
  TransformationController _controller = TransformationController();
  ImagePickerConfigs _configs = ImagePickerConfigs();

  late List<StickerView> _attachedList;
  late List<Image> _stickerList;

  double _minScale = 0.5;
  double _maxScale = 2.5;

  StickerView? _selectedStickerView;

  @override
  void initState() {
    super.initState();

    _attachedList = [];
    _stickerList = List<int>.generate(34, (index) => index + 1)
        .map((e) => Image.asset(
              "assets/icon/$e.png",
              package: 'advance_image_picker',
            ))
        .toList();

    if (widget.configs != null) _configs = widget.configs!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Read image bytes from file
  _readImage() async {
    if (_imageBytes == null) {
      _imageBytes = await widget.file.readAsBytes();
    }
    return _imageBytes;
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
    // TODO: Track AppBar theme backwards compatibility in Flutter SDK.
    // The AppBar theme backwards compatibility will be deprecated in Flutter
    // SDK soon. When that happens it will be removed here too.
    final bool backwardsCompatibility =
        appBarTheme.backwardsCompatibility ?? false;
    final Color _appBarBackgroundColor = backwardsCompatibility
        ? _configs.appBarBackgroundColor ??
            appBarTheme.backgroundColor ??
            theme.primaryColor
        : _configs.appBarBackgroundColor ??
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
                        } else
                          return Container(
                              child: Center(
                            child: CupertinoActivityIndicator(),
                          ));
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
              padding: const EdgeInsets.all(8.0),
              child: Text(_configs.textImageStickerGuide, style: TextStyle(color: Colors.white)),
            ))),
        Positioned(bottom: 120, left: 0, right: 0, child: _buildScalingControl(context))
      ]),
    );
  }

  /// Done process button
  _buildDoneButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.done),
      onPressed: (_selectedStickerView == null)
          ? () async {
              // Save current image editing
              Uint8List image = await _exportWidgetToImage(_boundaryKey!);

              // Output to file
              final dir = await PathProvider.getTemporaryDirectory();
              final targetPath = "${dir.absolute.path}/temp_${DateFormat('yyMMdd_hhmmss').format(DateTime.now())}.jpg";
              File file = File(targetPath);
              await file.writeAsBytes(image);

              // Compress & resize result image
              file = await ImageUtils.compressResizeImage(targetPath,
                  maxWidth: widget.maxWidth, maxHeight: widget.maxHeight);
              Navigator.of(context).pop(file);
            }
          : null,
    );
  }

  /// Build sticker list panel
  _buildStickerList(BuildContext context) {
    return Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          itemCount: _stickerList.length,
          itemBuilder: (BuildContext context, int i) {
            return Padding(
                padding: const EdgeInsets.all(1.0),
                child: Container(
                  color: Colors.white,
                  child: GestureDetector(
                      onTap: () {
                        _attachSticker(_stickerList[i]);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _stickerList[i],
                      )),
                ));
          },
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.0),
        ),
        height: 120);
  }

  /// Build image & stickers stack panel
  _buildImageStack(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return RepaintBoundary(
      key: this._boundaryKey,
      child: Listener(
        onPointerDown: (v) async {
          _selectedStickerView = _getSelectedSticker(v);
        },
        onPointerMove: (v) async {
          setState(() {
            if (_selectedStickerView != null) {
              _selectedStickerView!.top =
                  v.localPosition.dy - (_selectedStickerView!.height * _selectedStickerView!.currentScale) / 2;
              _selectedStickerView!.left =
                  v.localPosition.dx - (_selectedStickerView!.width * _selectedStickerView!.currentScale) / 2;
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
                  color: Colors.black, image: DecorationImage(fit: BoxFit.contain, image: MemoryImage(_imageBytes!))),
            ),
            ..._attachedList
                .map((e) => Positioned(top: e.top, left: e.left, child: e..isFocus = (e == _selectedStickerView))),
          ],
        ),
      ),
    );
  }

  /// Build control to scale selected sticker icon
  _buildScalingControl(BuildContext context) {
    if (_selectedStickerView == null) return const SizedBox();

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
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

  /// Determine which sticker is selecting
  _getSelectedSticker(PointerEvent event) {
    final result = BoxHitTestResult();

    for (StickerView s in _attachedList) {
      final RenderBox box = (s.key! as GlobalKey).currentContext?.findRenderObject() as RenderBox;
      Offset localBox = box.globalToLocal(event.position);
      if (box.hitTest(result, position: localBox)) {
        return s;
      }
    }
  }

  /// Add new sticker to stack
  _attachSticker(Image image) {
    setState(() {
      _attachedList.add(StickerView(
        image,
        key: GlobalKey(),
        width: 80,
        height: 80,
        top: 20,
        left: 20,
        onTapRemove: (sticker) {
          setState(() {
            if (_selectedStickerView != null && _selectedStickerView!.key == sticker.key) _selectedStickerView = null;
            this._attachedList.removeWhere((s) => s.key == sticker.key);
          });
        },
      ));
    });
  }

  /// Export image & sticker stack to image bytes
  _exportWidgetToImage(GlobalKey key) async {
    RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 3.0);
    var byteData = await image.toByteData(format: ImageByteFormat.png);
    var pngBytes = byteData?.buffer.asUint8List();
    return pngBytes;
  }
}

/// Sticker view
// ignore: must_be_immutable
class StickerView extends StatefulWidget {
  final Image image;
  final double width;
  final double height;

  double top;
  double left;
  double currentScale;
  bool isFocus;

  final Function? onTapRemove;

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

  @override
  _StickerViewState createState() => _StickerViewState();
}

class _StickerViewState extends State<StickerView> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          if (this.widget.onTapRemove != null) {
            this.widget.onTapRemove!(this.widget);
          }
        });
      },
      child: Container(
          decoration: BoxDecoration(
            border: this.widget.isFocus ? Border.all(color: Colors.pinkAccent, width: 3.0) : null,
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          width: this.widget.width * this.widget.currentScale,
          height: this.widget.height * this.widget.currentScale,
          child: this.widget.image),
    );
  }
}
