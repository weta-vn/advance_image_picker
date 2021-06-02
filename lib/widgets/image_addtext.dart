import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart' as PathProvider;
import 'package:text_editor/text_editor.dart';

import '../configs/image_picker_configs.dart';
import '../utils/image_utils.dart';

class ImageAddText extends StatefulWidget {
  final File file;
  final String title;
  final int maxWidth;
  final int maxHeight;
  final ImagePickerConfigs configs;

  ImageAddText(
      {@required this.file,
      @required this.title,
      this.configs,
      this.maxWidth = 1920,
      this.maxHeight = 1080});

  @override
  _ImageAddTextState createState() => _ImageAddTextState();
}

class _ImageAddTextState extends State<ImageAddText> {
  Uint8List _imageBytes;
  final TextEditingController _controller = TextEditingController(text: 'ABC');

  final fonts = [
    'OpenSans',
    'Billabong',
    'GrandHotel',
    'Oswald',
    'Quicksand',
    'BeautifulPeople',
    'BeautyMountains',
    'BiteChocolate',
    'BlackberryJam',
    'BunchBlossoms',
    'CinderelaRegular',
    'Countryside',
    'Halimun',
    'LemonJelly',
    'QuiteMagicalRegular',
    'Tomatoes',
    'TropicalAsianDemoRegular',
    'VeganStyle',
  ].map((e) => "packages/freemar_image_picker/$e").toList();
  TextStyle _textStyle = TextStyle(
      fontSize: 50,
      color: Colors.white,
      fontFamily: 'Billabong',
      package: 'freemar_image_picker');
  String _text = 'ABC!';
  TextAlign _textAlign = TextAlign.center;
  GlobalKey _boundaryKey = GlobalKey();
  Offset _position;
  ImagePickerConfigs _configs = ImagePickerConfigs();

  @override
  void initState() {
    super.initState();
    if (widget.configs != null) _configs = widget.configs;
  }

  @override
  void dispose() {
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
    var size = MediaQuery.of(context).size;

    var textView = _buildTextView(context);

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[_buildDoneButton(context)],
        ),
        body: RepaintBoundary(
          key: _boundaryKey,
          child: Stack(
            children: [
              Container(
                  width: size.width,
                  height: size.height,
                  child: _buildImageViewer(context)),
              Positioned(
                  left: this._position.dx,
                  top: this._position.dy - 80,
                  child: Draggable(
                    child: textView,
                    feedback: textView,
                    onDragStarted: () {
                      print("onDragStarted");
                    },
                    onDragCompleted: () {
                      print("onDragCompleted");
                    },
                    onDraggableCanceled: (Velocity velocity, Offset offset) {
                      setState(() => this._position = offset);
                    },
                    childWhenDragging: const SizedBox(),
                  ))
            ],
          ),
        ));
  }

  _buildDoneButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.done),
      onPressed: () async {
        // Save current image editing
        Uint8List outputBytes = await _exportWidgetToImage(_boundaryKey);

        // Create output file from bytes
        final dir = await PathProvider.getTemporaryDirectory();
        final targetPath =
            "${dir.absolute.path}/temp_${DateFormat('yyMMdd_hhmmss').format(DateTime.now())}.jpg";
        File file = File(targetPath);
        await file.writeAsBytes(outputBytes);

        // Compress & resize result image
        file = await ImageUtils.compressResizeImage(targetPath,
            maxWidth: widget.maxWidth, maxHeight: widget.maxHeight);
        Navigator.of(context).pop(file);
      },
    );
  }

  _buildImageViewer(BuildContext context) {
    var view = () => Container(
        padding: EdgeInsets.all(12.0),
        color: Colors.black,
        child: Image.memory(
          _imageBytes,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ));

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

  _buildTextView(BuildContext context) {
    var size = MediaQuery.of(context).size;
    this._position ??= Offset(size.width / 2 - 100, size.height / 2 - 100);
    return GestureDetector(
      onTap: () => _tapHandler(_text, _textStyle, _textAlign),
      child: Text(
        _text,
        style: _textStyle,
        textAlign: _textAlign,
      ),
    );
  }

  _exportWidgetToImage(GlobalKey key) async {
    RenderRepaintBoundary boundary = key.currentContext.findRenderObject();
    var image = await boundary.toImage(pixelRatio: 3.0);
    var byteData = await image.toByteData(format: ImageByteFormat.png);
    var pngBytes = byteData.buffer.asUint8List();
    return pngBytes;
  }

  void _tapHandler(text, textStyle, textAlign) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration(
        milliseconds: 400,
      ), // how long it takes to popup dialog after button click
      pageBuilder: (_, __, ___) {
        // your widget implementation
        return Container(
          color: Colors.black.withOpacity(0.4),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              // top: false,
              child: Container(
                child: TextEditor(
                  fonts: fonts,
                  text: text,
                  textStyle: textStyle,
                  textAlingment: textAlign,
                  paletteColors: [
                    Colors.black,
                    Colors.white,
                    Colors.blue,
                    Colors.red,
                    Colors.green,
                    Colors.yellow,
                    Colors.pink,
                    Colors.cyanAccent,
                  ],
                  decoration: EditorDecoration(
                    doneButton: Icon(Icons.done, color: Colors.white),
                    fontFamily: Icon(Icons.title, color: Colors.white),
                    colorPalette: Icon(Icons.palette, color: Colors.white),
                  ),
                  onEditCompleted: (style, align, text) {
                    setState(() {
                      _text = text;
                      _textStyle = style;
                      _textAlign = align;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
