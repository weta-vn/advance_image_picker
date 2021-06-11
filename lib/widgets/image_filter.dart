import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider/path_provider.dart' as PathProvider;
import 'package:intl/intl.dart';

import '../configs/image_picker_configs.dart';
import '../utils/image_utils.dart';

class ImageFilter extends StatefulWidget {
  final String title;
  final File file;
  final int maxWidth;
  final int maxHeight;
  final ImagePickerConfigs configs;

  const ImageFilter(
      {Key key, @required this.title, @required this.file, this.configs, this.maxWidth = 1280, this.maxHeight = 720})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => new _ImageFilterState();
}

class _ImageFilterState extends State<ImageFilter> {
  Map<String, List<int>> _cachedFilters = {};
  ListQueue<MapEntry<String, Future<List<int>> Function()>> _queuedApplyFilterFuncList =
      ListQueue<MapEntry<String, Future<List<int>> Function()>>();
  int _runningCount = 0;
  Filter _filter;
  List<Filter> _filters;
  Uint8List _imageBytes;
  Uint8List _thumbnailImageBytes;
  bool _loading;
  String _filename;
  ImagePickerConfigs _configs = ImagePickerConfigs();

  @override
  void initState() {
    super.initState();
    if (widget.configs != null) _configs = widget.configs;

    _loading = true;
    _filters = _getPresetFilters();
    _filter = this._filters[0];
    _filename = basename(widget.file.path);

    Future.delayed(Duration(milliseconds: 500), () async {
      await _loadImageData();
    });
  }

  @override
  void dispose() {
    _filters.clear();
    _cachedFilters.clear();
    _queuedApplyFilterFuncList.clear();
    super.dispose();
  }

  _loadImageData() async {
    _imageBytes = await widget.file.readAsBytes();
    _thumbnailImageBytes =
        await (await ImageUtils.compressResizeImage(widget.file.path, maxWidth: 100, maxHeight: 100)).readAsBytes();

    setState(() {
      _loading = false;
    });
  }

  Future<List<int>> _getFilteredData(String key) async {
    if (_cachedFilters.containsKey(key))
      return _cachedFilters[key];
    else {
      return await Future.delayed(Duration(milliseconds: 500), () => _getFilteredData(key));
    }
  }

  _runApplyFilterProcess() async {
    while (_queuedApplyFilterFuncList.isNotEmpty) {
      if (!this.mounted) break;

      if (_runningCount > 2) {
        await Future.delayed(Duration(milliseconds: 100));
        continue;
      }
      print("_runningCount: " + _runningCount.toString());

      var func = _queuedApplyFilterFuncList.removeFirst();
      _runningCount++;
      var ret = await func.value.call();
      _cachedFilters[func.key] = ret;
      _runningCount--;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          _loading
              ? Container()
              : IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () async {
                    setState(() {
                      _loading = true;
                    });
                    var imageFile = await saveFilteredImage();
                    Navigator.pop(context, imageFile);
                  },
                )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: _loading
            ? CupertinoActivityIndicator()
            : Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      padding: EdgeInsets.all(8.0),
                      child: _buildFilteredWidget(_filter, _imageBytes),
                    ),
                  ),
                  Container(
                    height: 150,
                    padding: EdgeInsets.all(12.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          child: Container(
                            padding: EdgeInsets.all(5.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  width: 90,
                                  height: 75,
                                  child: _buildFilteredWidget(_filters[index], _thumbnailImageBytes, isThumbnail: true),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(_filters[index].name, style: TextStyle(color: Colors.white)),
                                )
                              ],
                            ),
                          ),
                          onTap: () => setState(() {
                            _filter = _filters[index];
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<File> saveFilteredImage() async {
    final dir = await PathProvider.getTemporaryDirectory();
    final targetPath = "${dir.absolute.path}/temp_${DateFormat('yyMMdd_hhmmss').format(DateTime.now())}.jpg";
    File imageFile = File(targetPath);

    // Run selected filter on output image
    var outputBytes = await this._filter.apply(_imageBytes);

    await imageFile.writeAsBytes(outputBytes);
    return imageFile;
  }

  Widget _buildFilteredWidget(Filter filter, Uint8List imgBytes, {bool isThumbnail = false}) {
    var key = (filter?.name ?? "_") + (isThumbnail ? "thumbnail" : "");
    var data = this._cachedFilters.containsKey(key) ? this._cachedFilters[key] : null;
    var isSelected = (filter.name == this._filter.name);

    var createWidget = (Uint8List bytes) {
      if (isThumbnail) {
        return Container(
          decoration: BoxDecoration(
              color: Colors.grey,
              border: Border.all(color: isSelected ? Colors.blue : Colors.white, width: 3.0),
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(bytes, fit: BoxFit.cover)),
        );
      } else
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );
    };

    if (data == null) {
      var calcFunc = () async {
        return await filter.apply(imgBytes);
      };
      this._queuedApplyFilterFuncList.add(MapEntry<String, Future<List<int>> Function()>(key, calcFunc));
      _runApplyFilterProcess();

      return FutureBuilder<List<int>>(
        future: _getFilteredData(key),
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              return createWidget(snapshot.data);
            default:
              return CupertinoActivityIndicator();
          }
        },
      );
    } else {
      return createWidget(data);
    }
  }

  _getPresetFilters() {
    return <Filter>[
      Filter(name: "no filter"),
      Filter(name: "lighten", matrix: <double>[1.5, 0, 0, 0, 0, 0, 1.5, 0, 0, 0, 0, 0, 1.5, 0, 0, 0, 0, 0, 1, 0]),
      Filter(name: "darken", matrix: <double>[.5, 0, 0, 0, 0, 0, .5, 0, 0, 0, 0, 0, .5, 0, 0, 0, 0, 0, 1, 0]),
      Filter(name: "gray on light", matrix: <double>[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0]),
      Filter(
          name: "old times", matrix: <double>[1, 0, 0, 0, 0, -0.4, 1.3, -0.4, .2, -0.1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]),
      Filter(name: "sepia", matrix: <double>[
        0.393,
        0.769,
        0.189,
        0,
        0,
        0.349,
        0.686,
        0.168,
        0,
        0,
        0.272,
        0.534,
        0.131,
        0,
        0,
        0,
        0,
        0,
        1,
        0
      ]),
      Filter(name: "greyscale", matrix: <double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0
      ]),
      Filter(name: "vintage", matrix: <double>[
        0.9,
        0.5,
        0.1,
        0.0,
        0.0,
        0.3,
        0.8,
        0.1,
        0.0,
        0.0,
        0.2,
        0.3,
        0.5,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0
      ]),
      Filter(name: "filter 1", matrix: <double>[
        0.4,
        0.4,
        -0.3,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.2,
        0.0,
        0.0,
        -1.2,
        0.6,
        0.7,
        1.0,
        0.0
      ]),
      Filter(name: "filter 2", matrix: <double>[
        1.0,
        0.0,
        0.2,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0
      ]),
      Filter(name: "filter 3", matrix: <double>[
        0.8,
        0.5,
        0.0,
        0.0,
        0.0,
        0.0,
        1.1,
        0.0,
        0.0,
        0.0,
        0.0,
        0.2,
        1.1,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0
      ]),
      Filter(name: "filter 4", matrix: <double>[
        1.1,
        0.0,
        0.0,
        0.0,
        0.0,
        0.2,
        1.0,
        -0.4,
        0.0,
        0.0,
        -0.1,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0
      ]),
      Filter(name: "filter 5", matrix: <double>[
        1.2,
        0.1,
        0.5,
        0.0,
        0.0,
        0.1,
        1.0,
        0.05,
        0.0,
        0.0,
        0.0,
        0.1,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0
      ]),
      Filter(name: "elim blue", matrix: <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, -2, 1, 0]),
      Filter(name: "no g red", matrix: <double>[1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]),
      Filter(name: "no g magenta", matrix: <double>[1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0]),
      Filter(name: "lime", matrix: <double>[1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, .5, 0, 0, 0, 0, 1, 0]),
      Filter(name: "purple", matrix: <double>[1, -0.2, 0, 0, 0, 0, 1, 0, -0.1, 0, 0, 1.2, 1, .1, 0, 0, 0, 1.7, 1, 0]),
      Filter(name: "yellow", matrix: <double>[1, 0, 0, 0, 0, -0.2, 1, .3, .1, 0, -0.1, 0, 1, 0, 0, 0, 0, 0, 1, 0]),
      Filter(name: "cyan", matrix: <double>[1, 0, 0, 1.9, -2.2, 0, 1, 0, 0, .3, 0, 0, 1, 0, .5, 0, 0, 0, 1, .2]),
      // Filter(name: "invert", matrix: <double>[-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]),
    ];
  }
}

class Filter extends Object {
  final String name;
  final List<double> matrix;
  Filter({this.name, this.matrix = defaultColorMatrix}) : assert(name != null);

  Future<Uint8List> apply(Uint8List pixels) async {
    final ImageEditorOption option = ImageEditorOption();
    option.addOption(ColorOption(matrix: this.matrix));
    return await ImageEditor.editImage(image: pixels, imageEditorOption: option);
  }
}

class ColorFilterGenerator {
  static List<double> hueAdjustMatrix({double value}) {
    value = value * pi;

    if (value == 0)
      return [
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ];

    double cosVal = cos(value);
    double sinVal = sin(value);
    double lumR = 0.213;
    double lumG = 0.715;
    double lumB = 0.072;

    return List<double>.from(<double>[
      (lumR + (cosVal * (1 - lumR))) + (sinVal * (-lumR)),
      (lumG + (cosVal * (-lumG))) + (sinVal * (-lumG)),
      (lumB + (cosVal * (-lumB))) + (sinVal * (1 - lumB)),
      0,
      0,
      (lumR + (cosVal * (-lumR))) + (sinVal * 0.143),
      (lumG + (cosVal * (1 - lumG))) + (sinVal * 0.14),
      (lumB + (cosVal * (-lumB))) + (sinVal * (-0.283)),
      0,
      0,
      (lumR + (cosVal * (-lumR))) + (sinVal * (-(1 - lumR))),
      (lumG + (cosVal * (-lumG))) + (sinVal * lumG),
      (lumB + (cosVal * (1 - lumB))) + (sinVal * lumB),
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]).map((i) => i.toDouble()).toList();
  }
}
