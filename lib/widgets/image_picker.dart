import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart';

import '../configs/image_picker_configs.dart';
import '../models/image_object.dart';
import '../utils/image_utils.dart';
import 'image_viewer.dart';

class PickerMode {
  static const int Camera = 0;
  static const int Album = 1;
}

const int kBottomControlPanelHeight = 265;

class ImagePicker extends StatefulWidget {
  final int maxCount;
  final bool isFullscreenImage;
  final ImagePickerConfigs? configs;
  final bool isCaptureFirst;

  const ImagePicker(
      {this.maxCount = 10,
      this.isFullscreenImage = false,
      this.isCaptureFirst = true,
      this.configs});

  @override
  _ImagePickerState createState() => _ImagePickerState();
}

class _ImagePickerState extends State<ImagePicker>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // Camera
  List<CameraDescription> _cameras = [];
  int? _mode = PickerMode.Camera;
  CameraController? _controller;
  final _scrollController = ScrollController();
  Future<void>? _initializeControllerFuture;
  List<ImageObject> _selectedImages = [];
  bool _isCapturing = false;
  bool _isOutputCreating = false;
  bool _isFullscreenImage = false;
  bool _isImageSelectedDone = false;
  ImagePickerConfigs? _configs = ImagePickerConfigs();

  // Photo manager
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  List<Uint8List?> _albumThumbnails = [];
  GlobalKey<_MediaAlbumWidgetState> _currentAlbumKey = GlobalKey();

  // Capture
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;

  late AnimationController _exposureModeControlRowAnimationController;
  late Animation<double> _exposureModeControlRowAnimation;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);

    if (widget.configs != null) _configs = widget.configs;
    _isFullscreenImage = widget.isFullscreenImage;

    _exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureModeControlRowAnimation = CurvedAnimation(
      parent: _exposureModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );

    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      // Init camera
      if (widget.isCaptureFirst)
        await _initPhotoCapture();
      else
        await _initPhotoGallery();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _exposureModeControlRowAnimationController.dispose();
    _controller!.dispose();
    _controller = null;
    _cameras.clear();
    _albums.clear();
    _albumThumbnails.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onNewCameraSelected(cameraController.description);
    }
  }

  Future<void> _initPhotoCapture() async {
    _cameras = await availableCameras();
    _onNewCameraSelected(_cameras.first);
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    final CameraController cameraController = CameraController(
      cameraDescription,
      _configs!.resolutionPreset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) setState(() {});
      if (cameraController.value.hasError) {
        print('Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      _initializeControllerFuture =
          cameraController.initialize().then((value) async {
        Future.wait([
          cameraController
              .getMinExposureOffset()
              .then((value) => _minAvailableExposureOffset = value),
          cameraController
              .getMaxExposureOffset()
              .then((value) => _maxAvailableExposureOffset = value),
          cameraController
              .getMaxZoomLevel()
              .then((value) => _maxAvailableZoom = value),
          cameraController
              .getMinZoomLevel()
              .then((value) => _minAvailableZoom = value),
        ]);

        if (mounted) {
          setState(() {});
        }
      });
    } on CameraException catch (e) {
      print('Camera error ${e.code}, ${e.description}');
    }
  }

  Future<void> _initPhotoGallery() async {
    // Init photo manager
    var result = await PhotoManager.requestPermission();
    if (result) {
      // Get albums
      _albums = await PhotoManager.getAssetPathList(
          type: RequestType.image, onlyAll: false);
      if (_albums.length > 0) {
        var isAllAlbum = _albums.firstWhereOrNull((element) => element.isAll);
        setState(() {
          _currentAlbum = isAllAlbum ?? _albums[0];
        });
      }
    }
  }

  Future<File> _imagePreProcessing(String path, {Map? croppingParams}) async {
    if (_configs!.imagePreProcessingEnabled) {
      var file = await ImageUtils.compressResizeImage(path,
          maxWidth: _configs!.maxWidth,
          maxHeight: _configs!.maxHeight,
          quality: _configs!.compressQuality);
      if (croppingParams != null) {
        file = (await ImageUtils.cropImage(file.path,
            originX: croppingParams["originX"],
            originY: croppingParams["originY"],
            widthPercent: croppingParams["widthPercent"],
            heightPercent: croppingParams["heightPercent"]));
      }
      return file;
    }
    return File(path);
  }

  Future<File> _imagePostProcessing(String? path) async {
    if (!_configs!.imagePreProcessingEnabled)
      return await ImageUtils.compressResizeImage(path!,
          maxWidth: _configs!.maxWidth,
          maxHeight: _configs!.maxHeight,
          quality: _configs!.compressQuality);
    return File(path!);
  }

  Future<bool> _onWillPop() async {
    if (!_configs!.showNonSelectedAlert ||
        _isImageSelectedDone ||
        this._selectedImages.length == 0) return true;

    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text(_configs!.textConfirm),
            content: new Text(_configs!.textConfirmExitWithoutSelectingImages),
            actions: <Widget>[
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: new Text(_configs!.textNo),
              ),
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: new Text(_configs!.textYes),
              ),
            ],
          ),
        ) as FutureOr<bool>? ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: _configs!.backgroundColor,
          appBar: AppBar(
            title: _buildAppBarTitle(context),
            centerTitle: false,
            actions: <Widget>[_buildDoneButton(context)],
          ),
          body: SafeArea(child: _buildBodyView(context))),
    );
  }

  _buildAppBarTitle(BuildContext context) {
    return GestureDetector(
        onTap: (_mode == PickerMode.Album)
            ? () {
                Navigator.of(context, rootNavigator: true)
                    .push(PageRouteBuilder(
                        pageBuilder: (context, animation, __) {
                          return Scaffold(
                              appBar: AppBar(
                                  title: _buildAlbumSelectButton(context,
                                      isPop: true)),
                              body: Material(
                                  color: Colors.black,
                                  child: SafeArea(
                                    child: _buildAlbumList(_albums, context,
                                        (val) {
                                      Navigator.of(context).pop();
                                      setState(() {
                                        _currentAlbum = val;
                                      });
                                      _currentAlbumKey.currentState
                                          ?.updateStateFromExternal(
                                              album: _currentAlbum);
                                    }),
                                  )));
                        },
                        fullscreenDialog: true));
              }
            : null,
        child: _buildAlbumSelectButton(context,
            isCameraMode: (_mode == PickerMode.Camera)));
  }

  _buildDoneButton(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(8.0),
        child: OutlinedButton(
          onPressed: (this._selectedImages.length > 0)
              ? () async {
                  setState(() {
                    _isOutputCreating = true;
                  });

                  // Compress selected images then return
                  for (final f in this._selectedImages) {
                    f.modifiedPath =
                        (await this._imagePostProcessing(f.modifiedPath)).path;
                  }

                  _isImageSelectedDone = true;
                  Navigator.of(context).pop(this._selectedImages);
                }
              : null,
          style: ButtonStyle(
            elevation: MaterialStateProperty.all(5),
            backgroundColor: MaterialStateProperty.all(
                this._selectedImages.length > 0
                    ? _configs!.appBarDoneButtonColor
                    : Colors.grey),
            shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0))),
          ),
          child: Row(children: [
            Text(_configs!.textSelectButtonTitle,
                style: TextStyle(
                    color: this._selectedImages.length > 0
                        ? ((_configs!.appBarDoneButtonColor == Colors.white)
                            ? Colors.black
                            : Colors.white)
                        : Colors.black)),
            if (_isOutputCreating)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: CupertinoActivityIndicator(),
              )
          ]),
        ));
  }

  _buildBodyView(BuildContext context) {
    final size = MediaQuery.of(context).size;
    var bottomHeight = (widget.maxCount == 1)
        ? (kBottomControlPanelHeight - 40)
        : kBottomControlPanelHeight;

    return Stack(children: [
      Container(height: size.height, width: size.width),
      (_mode == PickerMode.Camera)
          ? Center(child: _buildCameraPreview(context))
          : _buildAlbumPreview(context),
      if (_mode == PickerMode.Camera) ...[
        Positioned(
            bottom: bottomHeight.toDouble(),
            left: 5,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _exposureModeControlRowWidget(),
              _buildExposureButton(context),
            ])),
        Positioned(
            bottom: bottomHeight.toDouble(),
            left: 0,
            right: 0,
            child: Center(child: _buildZoomRatioButton(context))),
        Positioned(
            bottom: bottomHeight.toDouble(),
            right: 5,
            child: _buildImageFullOption(context))
      ],
      Positioned(
          bottom: 0, left: 0, right: 0, child: _buildBottomPanel(context))
    ]);
  }

  _buildZoomRatioButton(BuildContext context) {
    return FlatButton(
        onPressed: null,
        shape: CircleBorder(),
        color: Colors.black12,
        child: Container(
          width: 48,
          height: 48,
          child: Center(
            child: Text("${_currentScale.toStringAsFixed(1).toString()}x",
                style: TextStyle(color: Colors.white)),
          ),
        ));
  }

  _buildExposureButton(BuildContext context) {
    return FlatButton(
      shape: CircleBorder(),
      color: Colors.black12,
      padding: EdgeInsets.all(4.0),
      child: Icon(Icons.exposure, color: Colors.white, size: 40),
      onPressed: _controller != null ? _onExposureModeButtonPressed : null,
    );
  }

  void _onExposureModeButtonPressed() {
    if (_exposureModeControlRowAnimationController.value == 1) {
      _exposureModeControlRowAnimationController.reverse();
    } else {
      _exposureModeControlRowAnimationController.forward();
    }
  }

  _buildImageFullOption(BuildContext context) {
    return FlatButton(
        onPressed: () {
          setState(() {
            _isFullscreenImage = !_isFullscreenImage;
          });
        },
        shape: CircleBorder(),
        color: Colors.black12,
        child: Icon(
            _isFullscreenImage
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            color: Colors.white,
            size: 48));
  }

  _buildBottomPanel(BuildContext context) {
    return Container(
      color: ((_mode == PickerMode.Camera) && _isFullscreenImage)
          ? _configs!.bottomPanelColorInFullscreen
          : _configs!.bottomPanelColor,
      padding: const EdgeInsets.all(8.0),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.maxCount > 1) ...[
              Text(
                  "${_configs!.textSelectedImagesTitle}: ${this._selectedImages.length.toString()} / ${widget.maxCount.toString()}",
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              Text(_configs!.textSelectedImagesGuide,
                  style: TextStyle(color: Colors.grey, fontSize: 14))
            ],
            _buildReorderableSelectedImageList(context),
            _buildCameraControls(context),
            Padding(
                padding: EdgeInsets.all(8.0),
                child: _buildPickerModeList(context))
          ]),
    );
  }

  _buildAlbumSelectButton(BuildContext context,
      {bool isPop = false, bool isCameraMode = false}) {
    if (isCameraMode)
      return Text(_configs!.textCameraTitle,
          style: TextStyle(color: _configs!.appBarTextColor, fontSize: 16));

    var container = Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black.withOpacity(0.1)),
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_currentAlbum?.name ?? "",
                style:
                    TextStyle(color: _configs!.appBarTextColor, fontSize: 16)),
            Icon(
                isPop
                    ? Icons.arrow_upward_outlined
                    : Icons.arrow_downward_outlined,
                size: 16)
          ],
        ));
    return isPop
        ? GestureDetector(
            child: container,
            onTap: () async {
              Navigator.of(context).pop();
            },
          )
        : container;
  }

  _buildCameraPreview(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (_controller?.value == null)
      return Container(
          width: size.width,
          height: size.height,
          child: Center(child: CircularProgressIndicator()));

    return FutureBuilder<void>(
        key: ValueKey(-1),
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return (_controller?.value?.isInitialized ?? false)
                ? Container(
                    width: size.width,
                    height: size.height,
                    child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: Listener(
                            onPointerDown: (_) => _pointers++,
                            onPointerUp: (_) => _pointers--,
                            child: CameraPreview(_controller!, child:
                                LayoutBuilder(builder: (BuildContext context,
                                    BoxConstraints constraints) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onScaleStart: _handleScaleStart,
                                onScaleUpdate: _handleScaleUpdate,
                                onTapDown: (details) =>
                                    _onViewFinderTap(details, constraints),
                              );
                            })))))
                : Container();
          }
          return Center(child: CircularProgressIndicator());
        });
  }

  void _onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_controller == null) {
      return;
    }

    final CameraController cameraController = _controller!;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (_controller == null || _pointers != 2) {
      return;
    }

    double scale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await _controller!.setZoomLevel(scale);

    setState(() {
      _currentScale = scale;
    });
  }

  _buildAlbumPreview(BuildContext context) {
    var bottomHeight = (widget.maxCount == 1)
        ? (kBottomControlPanelHeight - 40)
        : kBottomControlPanelHeight;

    return Container(
      height: MediaQuery.of(context).size.height - bottomHeight,
      child: _currentAlbum != null
          ? MediaAlbumWidget(
              key: _currentAlbumKey,
              gridCount: _configs!.albumGridCount,
              maxCount: widget.maxCount,
              album: _currentAlbum,
              selectedImages: _selectedImages,
              preProcessing: this._imagePreProcessing,
              onImageSelected: (image) async {
                var idx = _selectedImages
                    .indexWhere((element) => element.assetId == image.assetId);
                setState(() {
                  if (idx >= 0)
                    _selectedImages.removeAt(idx);
                  else {
                    _scrollController.animateTo(
                      ((_selectedImages.length - 1) * _configs!.thumbWidth)
                          .toDouble(),
                      duration: Duration(seconds: 1),
                      curve: Curves.fastOutSlowIn,
                    );
                    _selectedImages.add(image);
                  }
                });
              })
          : const SizedBox(),
    );
  }

  _buildAlbumThumbnails() async {
    if (_albums.isNotEmpty && _albumThumbnails.isEmpty) {
      List<Uint8List?> ret = [];
      for (var a in _albums) {
        var f = await (await a.getAssetListRange(start: 0, end: 1))
            .first
            .thumbDataWithSize(
                _configs!.albumThumbWidth, _configs!.albumThumbHeight);
        ret.add(f);
      }
      _albumThumbnails = ret;
    }

    return _albumThumbnails;
  }

  _buildAlbumList(List<AssetPathEntity> albums, BuildContext context,
      Function(AssetPathEntity newValue) callback) {
    return FutureBuilder(
      future: _buildAlbumThumbnails(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ListView.builder(
              itemCount: _albums.length,
              itemBuilder: (context, i) {
                var album = _albums[i];
                var thumbnail = _albumThumbnails[i]!;
                return InkWell(
                  child: ListTile(
                      leading: Container(
                          width: 80,
                          height: 80,
                          child: Image.memory(thumbnail, fit: BoxFit.cover)),
                      title: Text(album.name,
                          style: TextStyle(color: Colors.white)),
                      subtitle: Text(album.assetCount.toString(),
                          style: TextStyle(color: Colors.grey)),
                      onTap: () async {
                        callback.call(album);
                      }),
                );
              });
        } else
          return Container(
              child: Center(
            child: CupertinoActivityIndicator(),
          ));
      },
    );
  }

  _reorderSelectedImageList(int oldIndex, int newIndex) {
    if (oldIndex >= this._selectedImages.length ||
        newIndex > this._selectedImages.length ||
        oldIndex < 0 ||
        newIndex < 0) return false;

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final items = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, items);
      return;
    });
  }

  _buildReorderableSelectedImageList(BuildContext context) {
    var makeThumbnailImage = (String? path) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(File(path!),
              fit: BoxFit.cover,
              width: _configs!.thumbWidth.toDouble(),
              height: _configs!.thumbHeight.toDouble()));
    };

    var makeThumbnailWidget = (String? path, int index) {
      if (!_configs!.showDeleteButtonOnSelectedList)
        return makeThumbnailImage(path);

      return Stack(fit: StackFit.passthrough, children: [
        makeThumbnailImage(path),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                height: 16,
                width: 16,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    // return object of type Dialog
                    return AlertDialog(
                      title: new Text(_configs!.textConfirm),
                      content: new Text(_configs!.textConfirmDelete),
                      actions: <Widget>[
                        TextButton(
                          child: new Text(_configs!.textNo),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: new Text(_configs!.textYes),
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              this._selectedImages.removeAt(index);
                            });
                          },
                        ),
                      ],
                    );
                  },
                );
              }),
        )
      ]);
    };

    return Container(
        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        height: (_configs!.thumbHeight + 8).toDouble(),
        child: Theme(
          data: ThemeData(
              canvasColor: Colors.transparent, shadowColor: Colors.red),
          child: ReorderableListView(
              scrollController: _scrollController,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: <Widget>[
                for (var i = 0; i < widget.maxCount; i++)
                  if (_selectedImages.length > i)
                    Container(
                        key: ValueKey(i.toString()),
                        margin: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          border: Border.all(color: Colors.white, width: 3.0),
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(PageRouteBuilder(
                                pageBuilder: (context, animation, __) {
                              _configs?.imagePreProcessingBeforeEditingEnabled =
                                  !_configs!.imagePreProcessingEnabled;

                              return ImageViewer(
                                  title: _configs!.textPreviewTitle,
                                  images: this._selectedImages,
                                  initialIndex: i,
                                  configs: _configs,
                                  onChanged: (value) {
                                    if (value is List<ImageObject>) {
                                      setState(() {
                                        this._selectedImages = value;
                                      });
                                      _currentAlbumKey.currentState
                                          ?.updateStateFromExternal(
                                              selectedImages:
                                                  this._selectedImages);
                                    }
                                  });
                            }));
                          },
                          child: makeThumbnailWidget(
                              _selectedImages[i].modifiedPath, i),
                        ))
                  else
                    Container(
                        key: ValueKey(i.toString()),
                        width: _configs!.thumbWidth.toDouble(),
                        height: _configs!.thumbHeight.toDouble(),
                        margin: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          border: Border.all(
                              color: (i == _selectedImages.length)
                                  ? Colors.blue
                                  : Colors.white,
                              width: 3.0),
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ))
              ],
              onReorder: _reorderSelectedImageList),
        ));
  }

  _buildCameraControls(BuildContext context) {
    var isMaxCount = this._selectedImages.length >= widget.maxCount;

    var flashMode = () {
      var value = _controller?.value?.flashMode ?? FlashMode.auto;
      if (value == FlashMode.always)
        return [FlashMode.auto, Icons.flash_on];
      else if (value == FlashMode.auto)
        return [FlashMode.off, Icons.flash_auto];
      else if (value == FlashMode.off)
        return [FlashMode.always, Icons.flash_off];
    }();

    return _mode == PickerMode.Camera
        ? Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: Icon(flashMode?[1] as IconData?,
                        size: 32, color: Colors.white),
                    onTap: () async {
                      // Ensure that the camera is initialized.
                      await _initializeControllerFuture;

                      _controller!
                          .setFlashMode(flashMode?[0] as FlashMode)
                          .then((value) => setState(() {}));
                    },
                  ),
                  GestureDetector(
                    onTapDown: !isMaxCount
                        ? (td) {
                            setState(() {
                              _isCapturing = true;
                            });
                          }
                        : null,
                    onTapUp: !isMaxCount
                        ? (td) {
                            setState(() {
                              _isCapturing = false;
                            });
                          }
                        : null,
                    child: Icon(Icons.camera,
                        size: (64 + (_isCapturing ? (-10) : 0)).toDouble(),
                        color: !isMaxCount ? Colors.white : Colors.grey),
                    onTap: (!isMaxCount &&
                            !(_controller?.value?.isTakingPicture ?? true))
                        ? () async {
                            // Ensure that the camera is initialized.
                            await _initializeControllerFuture;

                            if (!(_controller?.value?.isTakingPicture ??
                                true)) {
                              try {
                                var file = await _controller!.takePicture();
                                Map<String, dynamic>? croppingParams;
                                if (!_isFullscreenImage) {
                                  croppingParams = {};
                                  final size = MediaQuery.of(context).size;
                                  croppingParams["originX"] = 0;
                                  croppingParams["originY"] = 0;
                                  croppingParams["widthPercent"] = 1.0;
                                  croppingParams["heightPercent"] =
                                      (size.height -
                                              kBottomControlPanelHeight) /
                                          size.height;
                                }
                                var capturedFile = await this
                                    ._imagePreProcessing(file.path,
                                        croppingParams: croppingParams);
                                setState(() {
                                  _scrollController.animateTo(
                                    ((_selectedImages.length - 1) *
                                            _configs!.thumbWidth)
                                        .toDouble(),
                                    duration: Duration(seconds: 1),
                                    curve: Curves.fastOutSlowIn,
                                  );
                                  _selectedImages.add(ImageObject(
                                      originalPath: capturedFile.path,
                                      modifiedPath: capturedFile.path));
                                });
                              } on CameraException catch (e) {
                                print(e.description);
                              }
                            }
                          }
                        : null,
                  ),
                  GestureDetector(
                    child: Icon(Icons.switch_camera,
                        size: 32,
                        color:
                            (_cameras.length > 1) ? Colors.white : Colors.grey),
                    onTap: (_cameras.length > 1)
                        ? () async {
                            final lensDirection =
                                _controller!.description.lensDirection;
                            CameraDescription newDescription;
                            if (lensDirection == CameraLensDirection.front) {
                              newDescription = _cameras.firstWhere(
                                  (description) =>
                                      description.lensDirection ==
                                      CameraLensDirection.back);
                            } else {
                              newDescription = _cameras.firstWhere(
                                  (description) =>
                                      description.lensDirection ==
                                      CameraLensDirection.front);
                            }
                            if (newDescription != null) {
                              print("Start new camera: " +
                                  newDescription.toString());
                              _onNewCameraSelected(newDescription);
                            }
                          }
                        : null,
                  )
                ]),
          )
        : const SizedBox();
  }

  _buildPickerModeList(BuildContext context) {
    return CupertinoSlidingSegmentedControl(
        backgroundColor: Colors.transparent,
        thumbColor: Colors.transparent,
        children: {
          0: Text(_configs!.textCameraTitle,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: (_mode == PickerMode.Camera)
                      ? Colors.white
                      : Colors.grey)),
          1: Text(_configs!.textAlbumTitle,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: (_mode == PickerMode.Album)
                      ? Colors.white
                      : Colors.grey)),
        },
        groupValue: _mode,
        onValueChanged: (dynamic val) async {
          if (val == PickerMode.Camera && this._cameras.length == 0)
            _initPhotoCapture();
          else if (val == PickerMode.Album && this._albums.length == 0)
            _initPhotoGallery();

          setState(() {
            _mode = val;
          });
        });
  }

  Widget _exposureModeControlRowWidget() {
    if (_controller?.value == null) return const SizedBox();

    final ButtonStyle styleAuto = TextButton.styleFrom(
      primary: _controller?.value.exposureMode == ExposureMode.auto
          ? Colors.orange
          : Colors.white,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      primary: _controller?.value.exposureMode == ExposureMode.locked
          ? Colors.orange
          : Colors.white,
    );

    var textStyle = TextStyle(color: Colors.white);
    return SizeTransition(
      sizeFactor: _exposureModeControlRowAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        child: Container(
          color: Colors.black.withOpacity(0.7),
          padding: EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text("EXPOSURE", style: textStyle),
                  SizedBox(width: 8),
                  TextButton(
                    child: Text('auto'),
                    style: styleAuto,
                    onPressed: _controller != null
                        ? () =>
                            _onSetExposureModeButtonPressed(ExposureMode.auto)
                        : null,
                    onLongPress: () {
                      if (_controller != null) {
                        _controller!.setExposurePoint(null);
                      }
                    },
                  ),
                  TextButton(
                    child: Text('locked'),
                    style: styleLocked,
                    onPressed: _controller != null
                        ? () =>
                            _onSetExposureModeButtonPressed(ExposureMode.locked)
                        : null,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(_minAvailableExposureOffset.toString(),
                      style: textStyle),
                  Slider(
                    value: _currentExposureOffset,
                    min: _minAvailableExposureOffset,
                    max: _maxAvailableExposureOffset,
                    divisions: 16,
                    label: _currentExposureOffset.toString(),
                    activeColor: Colors.white,
                    inactiveColor: Colors.grey,
                    onChanged: _minAvailableExposureOffset ==
                            _maxAvailableExposureOffset
                        ? null
                        : _setExposureOffset,
                  ),
                  Text(_maxAvailableExposureOffset.toString(),
                      style: textStyle),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSetExposureModeButtonPressed(ExposureMode mode) {
    _setExposureMode(mode).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _setExposureMode(ExposureMode mode) async {
    if (_controller == null) {
      return;
    }

    try {
      await _controller!.setExposureMode(mode);
    } on CameraException catch (e) {
      rethrow;
    }
  }

  Future<void> _setExposureOffset(double offset) async {
    if (_controller == null) {
      return;
    }

    setState(() {
      _currentExposureOffset = offset;
    });
    try {
      offset = await _controller!.setExposureOffset(offset);
    } on CameraException catch (e) {
      rethrow;
    }
  }

  void _showInSnackBar(String message) {
    // ignore: deprecated_member_use
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class MediaAlbumWidget extends StatefulWidget {
  final int gridCount;
  final int? maxCount;
  final int maxWidth;
  final int maxHeight;
  final int albumThumbWidth;
  final int albumThumbHeight;
  final AssetPathEntity? album;
  final List<ImageObject>? selectedImages;
  final Function(String)? preProcessing;
  final Function(ImageObject)? onImageSelected;

  const MediaAlbumWidget(
      {Key? key,
      this.gridCount = 4,
      this.maxCount,
      this.album,
      this.maxWidth = 1280,
      this.maxHeight = 720,
      this.albumThumbWidth = 200,
      this.albumThumbHeight = 200,
      this.selectedImages,
      this.preProcessing,
      this.onImageSelected})
      : super(key: key);

  @override
  _MediaAlbumWidgetState createState() => _MediaAlbumWidgetState();
}

class _MediaAlbumWidgetState extends State<MediaAlbumWidget> {
  List<ImageObject> _selectedImages = [];
  List<AssetEntity> _assets = [];
  Map<String, Uint8List?> _thumbnailCache = {};
  String _loadingAsset = "";
  AssetPathEntity? _album;

  @override
  initState() {
    super.initState();
    _selectedImages.addAll(widget.selectedImages!);
    _album = widget.album;
    _fetchMedia(_album);
  }

  @override
  void dispose() {
    _assets.clear();
    _thumbnailCache.clear();
    super.dispose();
  }

  updateStateFromExternal(
      {AssetPathEntity? album, List<ImageObject>? selectedImages}) {
    if (selectedImages != null)
      this._selectedImages = []..addAll(selectedImages);
    if (album != null) {
      _assets.clear();
      _thumbnailCache.clear();
      _album = album;
      _fetchMedia(_album);
    }
  }

  Future<Uint8List?> _getAssetThumbnail(AssetEntity asset) async {
    if (_thumbnailCache.containsKey(asset.id))
      return _thumbnailCache[asset.id];
    else {
      var data = await asset.thumbDataWithSize(
          widget.albumThumbWidth, widget.albumThumbHeight,
          quality: 90);
      _thumbnailCache[asset.id] = data;
      return data;
    }
  }

  _fetchMedia(AssetPathEntity? currentAlbum) async {
    if (_assets.isEmpty) {
      var ret = await currentAlbum!.getAssetListRange(start: 0, end: 5000);

      List<AssetEntity> assets = [];
      for (var asset in ret) {
        if (asset.type == AssetType.image) assets.add(asset);
      }

      setState(() {
        _assets = assets;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var gridview = GridView.builder(
        shrinkWrap: true,
        itemCount: _assets.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.gridCount,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1),
        itemBuilder: (BuildContext context, int index) {
          var asset = _assets[index];
          var idx = this._selectedImages.indexWhere(
              (element) => ImageUtils.isTheSameAsset(asset, element));
          var isMaxCount = (this._selectedImages.length >= widget.maxCount!);
          var isSelectable = ((idx >= 0) || !isMaxCount);
          var data = (_thumbnailCache.containsKey(asset.id))
              ? _thumbnailCache[asset.id]
              : null;

          return GestureDetector(
            onTap: (isSelectable && _loadingAsset.isEmpty)
                ? () async {
                    setState(() {
                      _loadingAsset = asset.id;
                    });

                    var file = await asset.originFile;
                    if (idx < 0)
                      file =
                          await widget.preProcessing?.call(file!.path) ?? file;
                    var image = ImageObject(
                        originalPath: file!.path,
                        modifiedPath: file.path,
                        assetId: asset.id);

                    setState(() {
                      if (idx >= 0)
                        _selectedImages.removeAt(idx);
                      else
                        _selectedImages.add(image);
                      _loadingAsset = "";
                    });

                    this.widget.onImageSelected?.call(image);
                  }
                : null,
            child: Stack(fit: StackFit.passthrough, children: [
              Positioned.fill(
                  child: (data == null)
                      ? FutureBuilder(
                          future: _getAssetThumbnail(asset),
                          builder: (BuildContext context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return Image.memory(
                                snapshot.data as Uint8List,
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                                child: Center(
                                    child: CupertinoActivityIndicator()));
                          },
                        )
                      : Image.memory(data,
                          fit: BoxFit.cover, gaplessPlayback: true)),
              if (!isSelectable)
                Positioned.fill(
                    child: Container(
                        color: Colors.grey.shade200.withOpacity(0.8))),
              if (_loadingAsset == asset.id)
                Positioned.fill(child: CupertinoActivityIndicator()),
              if (idx >= 0)
                Positioned(
                    top: 10,
                    right: 10,
                    child: Icon(Icons.check_circle,
                        color: Colors.pinkAccent, size: 24))
            ]),
          );
        });

    return gridview;
  }
}
