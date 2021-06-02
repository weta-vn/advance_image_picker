import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../configs/image_picker_configs.dart';
import '../models/image_object.dart';
import '../utils/image_utils.dart';
import 'image_addtext.dart';
import 'image_edit.dart';
import 'image_filter.dart';
import 'image_sticker.dart';

class ImageViewer extends StatefulWidget {
  final int initialIndex;
  final PageController pageController;
  final String title;
  final List<ImageObject> images;
  final ImagePickerConfigs configs;

  final Function(dynamic) onChanged;

  ImageViewer({this.initialIndex = 0, this.title, this.images, this.configs, this.onChanged})
      : pageController = PageController(initialPage: initialIndex);

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  int _currentIndex;
  List<ImageObject> _images = [];
  ImagePickerConfigs _configs = ImagePickerConfigs();
  TextEditingController _textFieldController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _images = []..addAll(widget.images);
    if (widget.configs != null) _configs = widget.configs;

    _currentIndex = widget.initialIndex;
    onPageChanged(_currentIndex);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<File> _imagePreProcessing(String path) async {
    if (_configs.imagePreProcessingBeforeEditingEnabled)
      return await ImageUtils.compressResizeImage(path,
          maxWidth: _configs.maxWidth, maxHeight: _configs.maxHeight, quality: _configs.compressQuality);
    return File(path);
  }

  void onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var hasImages = (this._images.length > 0);
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: Text("${widget.title} (${this._currentIndex + 1} / ${this._images.length})"), actions: [
          GestureDetector(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.delete, size: 32, color: hasImages ? _configs.appBarTextColor : Colors.grey),
            ),
            onTap: hasImages
                ? () async {
                    showDialog(
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
                                  var deleteIndex = this._currentIndex;
                                  if (this._images.length > 1)
                                    this._currentIndex = max(this._currentIndex - 1, 0);
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
                  _buildEditorControls(context),
                ])
              : Center(child: Text(_configs.textNoImages, style: TextStyle(color: Colors.grey))),
        ));
  }

  _buildPhotoViewGallery(BuildContext context) {
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
          Positioned(top: 0, left: 0, right: 0, child: _buildCurrentImageInfoView(context)),
        ],
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final item = _images[index];
    return PhotoViewGalleryPageOptions(
        imageProvider: FileImage(File(item.modifiedPath)),
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 0.5,
        maxScale: PhotoViewComputedScale.covered * 1.1);
  }

  _reorderSelectedImageList(int oldIndex, int newIndex) {
    if (oldIndex < 0 || newIndex < 0) return false;

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final items = _images.removeAt(oldIndex);
      _images.insert(newIndex, items);
      widget.onChanged?.call(this._images);
      return true;
    });
  }

  _buildReorderableSelectedImageList(BuildContext context) {
    var makeThumbnail = (String path) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(File(path),
              fit: BoxFit.cover, width: _configs.thumbWidth.toDouble(), height: _configs.thumbHeight.toDouble()));
    };

    return Container(
        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        height: (_configs.thumbHeight + 8).toDouble(),
        child: Theme(
          data: ThemeData(canvasColor: Colors.transparent, shadowColor: Colors.red),
          child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: <Widget>[
                for (var i = 0; i < _images.length; i++)
                  Container(
                      key: ValueKey(i.toString()),
                      margin: EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        border: Border.all(color: (i == this._currentIndex) ? Colors.blue : Colors.white, width: 3.0),
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            this._currentIndex = i;
                          });

                          if (widget.pageController.hasClients)
                            await widget.pageController.animateToPage(this._currentIndex,
                                duration: Duration(milliseconds: 500), curve: Curves.easeIn);
                        },
                        child: makeThumbnail(_images[i].modifiedPath),
                      ))
              ],
              onReorder: _reorderSelectedImageList),
        ));
  }

  _buildCurrentImageInfoView(BuildContext context) {
    var image = this._images[this._currentIndex];

    Future<ImageObject> imageProc = ImageUtils.getImageInfo(image);

    return FutureBuilder<ImageObject>(
        future: imageProc,
        builder: (BuildContext context, AsyncSnapshot<ImageObject> snapshot) {
          if (snapshot.hasData) {
            var image = snapshot.data;
            return Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(4.0),
                  color: Colors.black.withOpacity(0.5),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("${image.modifiedWidth}x${image.modifiedHeight}",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),                    
                  ]),
                ),
              ],
            );
          } else
            return CupertinoActivityIndicator();
        });
  }

  _buildEditorControls(BuildContext context) {
    var imageChanged = (_images[_currentIndex].modifiedPath != _images[_currentIndex].originalPath);

    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        if (_configs.cropFeatureEnabled)
          GestureDetector(
            child: Icon(Icons.crop_rotate, size: 32, color: Colors.white),
            onTap: () async {
              var image = await this._imagePreProcessing(_images[_currentIndex].modifiedPath);
              File croppedFile = await ImageCropper.cropImage(
                  sourcePath: image.path,
                  compressQuality: _configs.compressQuality,
                  maxWidth: _configs.maxWidth,
                  maxHeight: _configs.maxHeight,
                  aspectRatioPresets: [
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9
                  ],
                  androidUiSettings: AndroidUiSettings(
                      toolbarTitle: _configs.textImageCropTitle,
                      toolbarColor: Colors.blue,
                      toolbarWidgetColor: Colors.white,
                      initAspectRatio: CropAspectRatioPreset.original,
                      lockAspectRatio: false),
                  iosUiSettings: IOSUiSettings(
                    minimumAspectRatio: 1.0,
                  ));
              if (croppedFile != null) {
                setState(() {
                  this._images[this._currentIndex].modifiedPath = croppedFile.path;
                  widget.onChanged?.call(this._images);
                });
              }
            },
          ),
        if (_configs.filterFeatureEnabled)
          GestureDetector(
            child: Icon(Icons.auto_awesome, size: 32, color: Colors.white),
            onTap: () async {
              var image = await this._imagePreProcessing(_images[_currentIndex].modifiedPath);
              File filteredFile = await Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => new ImageFilter(title: _configs.textImageFilterTitle, file: image),
                ),
              );
              if (filteredFile != null) {
                setState(() {
                  this._images[this._currentIndex].modifiedPath = filteredFile.path;
                  widget.onChanged?.call(this._images);
                });
              }
            },
          ),
        if (_configs.adjustFeatureEnabled)
          GestureDetector(
            child: Icon(Icons.wb_sunny_outlined, size: 32, color: Colors.white),
            onTap: () async {
              var image = await this._imagePreProcessing(_images[_currentIndex].modifiedPath);
              var edittedFile = await Navigator.of(context).push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => ImageEdit(file: image, title: _configs.textImageEditTitle)));
              if (edittedFile != null) {
                setState(() {
                  this._images[this._currentIndex].modifiedPath = edittedFile.path;
                  widget.onChanged?.call(this._images);
                });
              }
            },
          ),
        if (_configs.stickerFeatureEnabled)
          GestureDetector(
            child: Icon(Icons.insert_emoticon_rounded, size: 32, color: Colors.white),
            onTap: () async {
              var image = await this._imagePreProcessing(_images[_currentIndex].modifiedPath);
              var edittedFile = await Navigator.of(context).push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => ImageSticker(file: image, title: _configs.textImageStickerTitle)));
              if (edittedFile != null) {
                setState(() {
                  this._images[this._currentIndex].modifiedPath = edittedFile.path;
                  widget.onChanged?.call(this._images);
                });
              }
            },
          ),
        if (_configs.addTextFeatureEnabled)
          GestureDetector(
            child: Icon(Icons.text_format_rounded, size: 32, color: Colors.white),
            onTap: () async {
              var image = await this._imagePreProcessing(_images[_currentIndex].modifiedPath);
              var edittedFile = await Navigator.of(context).push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => ImageAddText(file: image, title: _configs.textImageAddTextTitle)));
              if (edittedFile != null) {
                setState(() {
                  this._images[this._currentIndex].modifiedPath = edittedFile.path;
                  widget.onChanged?.call(this._images);
                });
              }
            },
          ),
        GestureDetector(
          child: Icon(Icons.replay, size: 32, color: imageChanged ? Colors.white : Colors.grey),
          onTap: imageChanged
              ? () async {
                  showDialog(
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
                                this._images[this._currentIndex].modifiedPath =
                                    this._images[this._currentIndex].originalPath;
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
    );
  }
}
