import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../configs/image_picker_configs.dart';
import '../../models/image_object.dart';
import '../../utils/image_utils.dart';
import '../common/portrait_mode_mixin.dart';
import '../editors/editor_params.dart';
import '../editors/image_edit.dart';
import '../editors/image_filter.dart';
import '../editors/image_sticker.dart';

/// Image viewer for selected images
class ImageViewer extends StatefulWidget {
  /// Initial index in image list
  final int initialIndex;

  /// Page controller
  final PageController pageController;

  /// Title
  final String? title;

  /// Selected images
  final List<ImageObject>? images;

  /// Configuration
  final ImagePickerConfigs? configs;

  /// Changed event
  final Function(dynamic)? onChanged;

  ImageViewer(
      {this.initialIndex = 0,
      this.title,
      this.images,
      this.configs,
      this.onChanged})
      : pageController = PageController(initialPage: initialIndex);

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with PortraitStatefulModeMixin<ImageViewer> {
  /// Current index of image in list
  int? _currentIndex;

  /// Selected images
  List<ImageObject> _images = [];

  /// Configuration
  ImagePickerConfigs _configs = ImagePickerConfigs();

  @override
  void initState() {
    super.initState();

    // Add images
    _images = []..addAll(widget.images!);
    if (widget.configs != null) _configs = widget.configs!;

    // Setup current selected index
    _currentIndex = widget.initialIndex;
    onPageChanged(_currentIndex);
  }

  /// Build image editor controls
  List<Widget> _buildImageEditorControls(BuildContext context, Color toolbarColor, Color toolbarWidgetColor) {
    Map<String, EditorParams> imageEditors = {};

    // Add preset image editors
    if (_configs.cropFeatureEnabled)
      imageEditors[_configs.textImageCropTitle] = EditorParams(
          title: _configs.textImageCropTitle,
          icon: Icons.crop_rotate,
          onEditorEvent: (
                  {required BuildContext context,
                  required File file,
                  required String title,
                  int maxWidth = 1080,
                  int maxHeight = 1920,
                  int compressQuality = 90,
                  ImagePickerConfigs? configs}) async => await ImageCropper.cropImage(
                  sourcePath: file.path,
                  compressQuality: compressQuality,
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                  aspectRatioPresets: [
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9
                  ],
                  androidUiSettings: AndroidUiSettings(
                      toolbarTitle: title,
                      toolbarColor: toolbarColor,
                      toolbarWidgetColor: toolbarWidgetColor,
                      initAspectRatio: CropAspectRatioPreset.original,
                      lockAspectRatio: false),
                  iosUiSettings: const IOSUiSettings(
                    minimumAspectRatio: 1.0,
                  ))
      );
    if (_configs.adjustFeatureEnabled)
      imageEditors[_configs.textImageEditTitle] = EditorParams(
          title: _configs.textImageEditTitle,
          icon: Icons.wb_sunny_outlined,
          onEditorEvent: (
                  {required BuildContext context,
                  required File file,
                  required String title,
                  int maxWidth = 1080,
                  int maxHeight = 1920,
                  int compressQuality = 90,
                  ImagePickerConfigs? configs}) async => await Navigator.of(context).push(MaterialPageRoute<File>(
                  fullscreenDialog: true,
                  builder: (context) => ImageEdit(file: file, title: title, maxWidth: maxWidth, maxHeight: maxHeight, configs: _configs)))
      );
    if (_configs.filterFeatureEnabled)
      imageEditors[_configs.textImageFilterTitle] = EditorParams(
          title: _configs.textImageFilterTitle,
          icon: Icons.auto_awesome,
          onEditorEvent: (
                  {required BuildContext context,
                  required File file,
                  required String title,
                  int maxWidth = 1080,
                  int maxHeight = 1920,
                  int compressQuality = 90,
                  ImagePickerConfigs? configs}) async => await Navigator.of(context).push(MaterialPageRoute<File>(
                  fullscreenDialog: true,
                  builder: (context) => ImageFilter(file: file, title: title, maxWidth: maxWidth, maxHeight: maxHeight, configs: _configs)))
      );
    if (_configs.stickerFeatureEnabled)
      imageEditors[_configs.textImageStickerTitle] = EditorParams(
          title: _configs.textImageStickerTitle,
          icon: Icons.insert_emoticon_rounded,
          onEditorEvent: (
                  {required BuildContext context,
                  required File file,
                  required String title,
                  int maxWidth = 1080,
                  int maxHeight = 1920,
                  int compressQuality = 90,
                  ImagePickerConfigs? configs}) async => await Navigator.of(context).push(MaterialPageRoute<File>(
                  fullscreenDialog: true,
                  builder: (context) => ImageSticker(file: file, title: title, maxWidth: maxWidth, maxHeight: maxHeight, configs: _configs)))
      );

    // Add custom image editors
    imageEditors.addAll(_configs.externalImageEditors);

    // Create image editor icons
    return imageEditors.values
        .map((e) => GestureDetector(
              child: Icon(e.icon, size: 32, color: Colors.white),
              onTap: () async {
                var image = await this
                    ._imagePreProcessing(_images[_currentIndex!].modifiedPath);
                File? outputFile = await e.onEditorEvent(context: context, file: image, title: e.title, maxWidth: _configs.maxWidth, maxHeight: _configs.maxHeight, configs: _configs);
                if (outputFile != null) {
                  setState(() {
                    this._images[this._currentIndex!].modifiedPath =
                        outputFile.path;
                    widget.onChanged?.call(this._images);
                  });
                }
              },
            ))
        .toList();
  }

  /// Pre-processing function
  Future<File> _imagePreProcessing(String? path) async {
    if (_configs.imagePreProcessingBeforeEditingEnabled)
      return await ImageUtils.compressResizeImage(path!,
          maxWidth: _configs.maxWidth,
          maxHeight: _configs.maxHeight,
          quality: _configs.compressQuality);
    return File(path!);
  }

  /// On changed event
  void onPageChanged(int? index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    var hasImages = (this._images.length > 0);

    // Use theme based AppBar colors if config values are not defined.
    // The logic is based on same approach that is used in AppBar SDK source.
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppBarTheme appBarTheme = AppBarTheme.of(context);
    // TODO: Track AppBar heme backwards compatibility in Flutter SDK.
    // This AppBar theme backwards compatibility will be deprecated in Flutter
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
            title: Text("${widget.title} (${this._currentIndex! + 1} "
                "/ ${this._images.length})"),
            backgroundColor: _appBarBackgroundColor,
            foregroundColor: _appBarTextColor,
            actions: [
              GestureDetector(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.delete,
                      size: 32,
                      color:
                          hasImages ? _configs.appBarTextColor : Colors.grey),
                ),
                onTap: hasImages
                    ? () async {
                        showDialog<void>(
                          context: context,
                          builder: (BuildContext context) {
                            // return object of type Dialog
                            return AlertDialog(
                              title: new Text(_configs.textConfirm),
                              content: new Text(_configs.textConfirmDelete),
                              actions: <Widget>[
                                TextButton(
                                  child: new Text(_configs.textNo),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: new Text(_configs.textYes),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    setState(() {
                                      var deleteIndex = this._currentIndex!;
                                      if (this._images.length > 1)
                                        this._currentIndex =
                                            max(this._currentIndex! - 1, 0);
                                      else
                                        this._currentIndex = -1;
                                      this._images.removeAt(deleteIndex);
                                      widget.onChanged?.call(this._images);
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    : null,
              ),
            ]),
        body: SafeArea(
          child: hasImages
              ? Column(children: [
                  _buildPhotoViewGallery(context),
                  _buildReorderableSelectedImageList(context),
                  _buildEditorControls(
                    context,
                    _appBarBackgroundColor,
                    _appBarTextColor,
                  ),
                ])
              : Center(
                  child: Text(_configs.textNoImages,
                      style: const TextStyle(color: Colors.grey))),
        ));
  }

  /// Image viewer as gallery for selected image
  Widget _buildPhotoViewGallery(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: _buildItem,
              itemCount: _images.length,
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              pageController: widget.pageController,
              onPageChanged: onPageChanged,
            ),
          ),
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildCurrentImageInfoView(context)),
        ],
      ),
    );
  }

  /// Build an image viewer
  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final item = _images[index];
    return PhotoViewGalleryPageOptions(
        imageProvider: FileImage(File(item.modifiedPath)),
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 0.5,
        maxScale: PhotoViewComputedScale.covered * 1.1);
  }

  /// Reorder selected image list
  bool? _reorderSelectedImageList(int oldIndex, int newIndex) {
    if (oldIndex < 0 || newIndex < 0) return false;

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final items = _images.removeAt(oldIndex);
      _images.insert(newIndex, items);
      widget.onChanged?.call(this._images);
      return;
    });
  }

  /// Build reorderable selected image list
  Widget _buildReorderableSelectedImageList(BuildContext context) {
    var makeThumbnail = (String? path) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(File(path!),
              fit: BoxFit.cover,
              width: _configs.thumbWidth.toDouble(),
              height: _configs.thumbHeight.toDouble()));
    };

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        height: (_configs.thumbHeight + 8).toDouble(),
        child: Theme(
          data: ThemeData(
              canvasColor: Colors.transparent, shadowColor: Colors.red),
          child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: <Widget>[
                for (var i = 0; i < _images.length; i++)
                  Container(
                      key: ValueKey(i.toString()),
                      margin: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        border: Border.all(
                            color: (i == this._currentIndex)
                                ? Colors.blue
                                : Colors.white,
                            width: 3.0),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            this._currentIndex = i;
                          });

                          if (widget.pageController.hasClients)
                            await widget.pageController.animateToPage(
                                this._currentIndex!,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeIn);
                        },
                        child: makeThumbnail(_images[i].modifiedPath),
                      ))
              ],
              onReorder: _reorderSelectedImageList),
        ));
  }

  /// Image viewer for current image
  Widget _buildCurrentImageInfoView(BuildContext context) {
    var image = this._images[this._currentIndex!];

    Future<ImageObject> imageProc = ImageUtils.getImageInfo(image);

    return FutureBuilder<ImageObject>(
        future: imageProc,
        builder: (BuildContext context, AsyncSnapshot<ImageObject> snapshot) {
          if (snapshot.hasData) {
            var image = snapshot.data!;
            return Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(4.0),
                  color: Colors.black.withOpacity(0.5),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${image.modifiedWidth}x${image.modifiedHeight}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ]),
                ),
              ],
            );
          } else
            return const CupertinoActivityIndicator();
        });
  }

  /// Build editor controls
  Widget _buildEditorControls(
      BuildContext context, Color toolbarColor, Color toolbarWidgetColor) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        ..._buildImageEditorControls(context, toolbarColor, toolbarWidgetColor),
        _buildEditorResetButton(context),
      ]),
    );
  }

  Widget _buildEditorResetButton(BuildContext context) {
    var imageChanged = (_images[_currentIndex!].modifiedPath !=
        _images[_currentIndex!].originalPath);
    return GestureDetector(
          child: Icon(Icons.replay,
              size: 32, color: imageChanged ? Colors.white : Colors.grey),
          onTap: imageChanged
              ? () async {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      // return object of type Dialog
                      return AlertDialog(
                        title: new Text(_configs.textConfirm),
                        content: new Text(_configs.textConfirmResetChanges),
                        actions: <Widget>[
                          TextButton(
                            child: new Text(_configs.textNo),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: new Text(_configs.textYes),
                            onPressed: () {
                              Navigator.of(context).pop();
                              setState(() {
                                this._images[this._currentIndex!].modifiedPath =
                                    this
                                        ._images[this._currentIndex!]
                                        .originalPath;
                                widget.onChanged?.call(this._images);
                              });
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              : null,
        );
  }
}
