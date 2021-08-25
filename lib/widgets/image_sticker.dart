import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:path_provider/path_provider.dart' as PathProvider;

import '../configs/image_picker_configs.dart';
import '../utils/image_utils.dart';
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

  ImageSticker(
      {required this.file,
      required this.title,
      this.maxWidth = 1080,
      this.maxHeight = 1920,
      this.configs});

  @override
  _ImageStickerState createState() => _ImageStickerState();
}

class _ImageStickerState extends State<ImageSticker>
    with PortraitStatefulModeMixin<ImageSticker> {
  GlobalKey? _boundaryKey;
  Uint8List? _imageBytes;
  TransformationController _controller = TransformationController();
  ImagePickerConfigs _configs = ImagePickerConfigs();

  @override
  void initState() {
    super.initState();
    if (widget.configs != null) _configs = widget.configs!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        actions: <Widget>[_buildHelpButton(context), _buildDoneButton(context)],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Expanded(child: _buildImageViewer(context))],
      ),
    );
  }

  _buildHelpButton(BuildContext context) {
    return IconButton(
        icon: Icon(Icons.help_outline),
        onPressed: () async {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_configs.textImageStickerGuide),
                    ),
                    Positioned(
                      top: -15,
                      right: -15,
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    )
                  ],
                ),
              );
            },
          );
        });
  }

  _buildDoneButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.done),
      onPressed: () async {
        // Save current image editing
        Uint8List image = await _exportWidgetToImage(_boundaryKey!);

        // Output to file
        final dir = await PathProvider.getTemporaryDirectory();
        final targetPath =
            "${dir.absolute.path}/temp_${DateFormat('yyMMdd_hhmmss').format(DateTime.now())}.jpg";
        File file = File(targetPath);
        await file.writeAsBytes(image);

        // Compress & resize result image
        file = await ImageUtils.compressResizeImage(targetPath,
            maxWidth: widget.maxWidth, maxHeight: widget.maxHeight);
        Navigator.of(context).pop(file);
      },
    );
  }

  _buildImageViewer(BuildContext context) {
    var view = () => StickerImageView(
        InteractiveViewer(
          maxScale: 2.0,
          minScale: 0.5,
          transformationController: _controller,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.black,
                image: DecorationImage(
                    fit: BoxFit.contain, image: MemoryImage(_imageBytes!))),
          ),
        ),
        List<int>.generate(33, (index) => index + 1)
            .map((e) => Image.asset(
                  "assets/icon/$e.png",
                  package: 'advance_image_picker',
                ))
            .toList(),
        panelHeight: 160,
        panelStickercrossAxisCount: 2,
        boundaryKey: _boundaryKey,
        panelBackgroundColor: Colors.black);

    if (_imageBytes == null)
      return FutureBuilder(
          future: _readImage(),
          builder: (BuildContext context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return view();
            } else
              return Container(
                  child: Center(
                child: CupertinoActivityIndicator(),
              ));
          });
    else
      return view();
  }

  _exportWidgetToImage(GlobalKey key) async {
    RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 3.0);
    var byteData = await image.toByteData(format: ImageByteFormat.png);
    var pngBytes = byteData?.buffer.asUint8List();
    return pngBytes;
  }
}

class StickerImageView extends StatefulWidget {
  StickerImageView(this.source, this.stickerList,
      {Key? key,
      this.stickerSize = 40.0,
      this.stickerMaxScale = 2.0,
      this.stickerMinScale = 0.5,
      this.panelHeight = 200.0,
      this.boundaryKey,
      this.panelBackgroundColor = Colors.black,
      this.panelStickerBackgroundColor = Colors.transparent,
      this.panelStickercrossAxisCount = 1,
      this.panelStickerAspectRatio = 1.0,
      this.onTransformed})
      : super(key: key);

  final Widget source;
  final List<Image> stickerList;

  final GlobalKey? boundaryKey;

  final double stickerSize;
  final double stickerMaxScale;
  final double stickerMinScale;

  final double panelHeight;
  final Color panelBackgroundColor;
  final Color panelStickerBackgroundColor;
  final int panelStickercrossAxisCount;
  final double panelStickerAspectRatio;

  final Function? onTransformed;

  final _StickerImageViewState _flutterSimpleStickerViewState =
      _StickerImageViewState();

  @override
  _StickerImageViewState createState() => _flutterSimpleStickerViewState;
}

class _StickerImageViewState extends State<StickerImageView> {
  Size? _viewport;
  List<StickerView> _attachedList = [];

  void attachSticker(Image image) {
    setState(() {
      _attachedList.add(StickerView(
        image,
        matrix: Matrix4.identity(),
        key: Key("sticker_${_attachedList.length}"),
        width: this.widget.stickerSize,
        height: this.widget.stickerSize,
        maxScale: this.widget.stickerMaxScale,
        minScale: this.widget.stickerMinScale,
        onTapRemove: (sticker) {
          setState(() {
            this._attachedList.removeWhere((s) => s.key == sticker.key);
          });
          if (widget.onTransformed != null) widget.onTransformed!();
        },
      ));
      if (widget.onTransformed != null) widget.onTransformed!();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: RepaintBoundary(
            key: widget.boundaryKey,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    _viewport = _viewport ??
                        Size(constraints.maxWidth, constraints.maxHeight);
                    return widget.source;
                  },
                ),
                Stack(
                  children: _attachedList,
                  fit: StackFit.expand,
                ),
              ],
            ),
          ),
        ),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: this.widget.panelBackgroundColor,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemCount: widget.stickerList.length,
              itemBuilder: (BuildContext context, int i) {
                return Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Container(
                      color: this.widget.panelStickerBackgroundColor,
                      child: TextButton(
                          style: TextButton.styleFrom(
                            primary: Colors.black87,
                            minimumSize: Size(88, 36),
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2.0)),
                            ),
                          ),
                          onPressed: () {
                            attachSticker(widget.stickerList[i]);
                          },
                          child: widget.stickerList[i]),
                    ));
              },
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: this.widget.panelStickercrossAxisCount,
                  childAspectRatio: this.widget.panelStickerAspectRatio),
            ),
            height: this.widget.panelHeight)
      ],
    );
  }
}

// ignore: must_be_immutable
class StickerView extends StatefulWidget {
  StickerView(
    this.image, {
    Key? key,
    this.width,
    this.height,
    this.minScale = 0.5,
    this.maxScale = 2.0,
    this.matrix,
    this.onTapRemove,
    this.onTransformed,
  }) : super(key: key);

  final Image image;
  final double? width;
  final double? height;

  final double minScale;
  final double maxScale;

  final Function? onTapRemove;
  final Function? onTransformed;

  Matrix4? matrix;

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
      child: MatrixGestureDetector(
        shouldRotate: false,
        onMatrixUpdate: (Matrix4 m, Matrix4 tm, Matrix4 sm, Matrix4 rm) {
          setState(() {
            widget.matrix = m;
          });
        },
        child: Transform(
          transform: widget.matrix!,
          child: Container(
              width: widget.width, height: widget.height, child: widget.image),
        ),
      ),
    );
  }
}
