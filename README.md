# advance_image_picker

Flutter plugin for selecting **multiple images** from the Android and iOS image library, **taking new pictures with the camera**, and **edit** them before using such as rotating, cropping, adding sticker/filters.

*This is an advanced version of [image_picker](https://pub.dev/packages/image_picker) plugin.*


## Key Features

- Display live camera preview in a widget.
- Adjust exposure
- Zoom camera preview
- Capture photo without saving into device library
- Capture with preview size mode & full screen size mode
- Select photos from device library by browsing photo albums
- Preview selected images
- Support button label & text translation
- Easy image editing features, such as rotation, cropping, adding sticker/filters
- Object detector & OCR (implement in future)

## Apps using this package

**freemar.vn - Shopping app for Vietnamese**

<a href="https://play.google.com/store/apps/details?id=com.freemar.vn" class="download-btn"><i class="bx bxl-play-store"></i> Google Play</a>
<a href="https://apps.apple.com/vn/app/freemar/id1530667938?l=vi" class="download-btn"><i class="bx bxl-apple"></i> App Store</a>

**trainghiem.vn - Find places to have fun, find places to experience!**

<a target="_blank" data-animation="fadeInRight" data-delay="1.0s" href="https://play.google.com/store/apps/details?id=com.trainghiem.vn" class="btn" tabindex="0" style="animation-delay: 1s;">Google Play</a>
<a target="_blank" data-animation="fadeInLeft" data-delay="1.0s" href="https://apps.apple.com/vn/app/trainghiemvn/id1537519143?l=vi" class="btn" tabindex="0" style="animation-delay: 1s;">App Store</a>

## Demo & Screenshots

<img src="https://raw.githubusercontent.com/weta-vn/freemar_image_picker/master/screenshot/1.png" width="100%"/>
<img src="https://raw.githubusercontent.com/weta-vn/freemar_image_picker/master/screenshot/2.png" width="100%"/>

 ---
[*Youtube Demo Link*](https://youtu.be/pl0S72kd0mo)


## Installation

### iOS

Add these settings to the ios/Runner/Info.plist

~~~~
<key>NSCameraUsageDescription</key>
<string>Can I use the camera please?</string>
<key>NSMicrophoneUsageDescription</key>
<string>Can I use the mic please?</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>App need your agree, can visit your album</string>
~~~~

### Android

Change the minimum Android sdk version to 21 (or higher) in your `android/app/build.gradle` file.

~~~~
minSdkVersion 21
~~~~

Recommended add `android:requestLegacyExternalStorage="true"` to your `AndroidManifest.xml`, just like next.

```
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="vn.weta.freemarimagepickerexample">

    <application
        android:name="io.flutter.app.FlutterApplication"
        android:label="freemarimagepicker_example"
        android:requestLegacyExternalStorage="true"
        android:icon="@mipmap/ic_launcher">
    </application>
</manifest>
```

## Usages

Add to pubspec

```
dependencies:
  advance_image_picker: $latest_version
```

Import dart code

```
import 'package:advance_image_picker/advance_image_picker.dart';
```

Setting configs & text translate function

```
// Setup image picker configs (global settings for app)
var configs = ImagePickerConfigs();
configs.appBarTextColor = Colors.black;
configs.stickerFeatureEnabled = false; // ON/OFF features
configs.translateFunc = (name, value) => Intl.message(value, name: name); // Use intl function
```

Sample for usage

```
// Get max 5 images
List<ImageObject> objects =
    await Navigator.of(context).push(
        PageRouteBuilder(pageBuilder:
            (context, animation, __) {
  return ImagePicker(maxCount: 5);
}));

if (objects.length > 0) {
  setState(() {
    imageFiles.addAll(objects
        .map((e) => e.modifiedPath)
        .toList());
  });
}
```

## Credits

This software uses the following open source packages:

- camera
- photo_manager
- image_cropper
- photo_view
- flutter_native_image
- image_editor
- matrix_gesture_detector
- path_provider
- image
- intl

## Support

If this plugin was useful to you, helped you to deliver your app, saved you a lot of time, or you just want to support the project, I would be very grateful if you buy me a cup of coffee.

<a href="https://www.buymeacoffee.com/wetavn" target="_blank" rel="ugc"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee"></a>

