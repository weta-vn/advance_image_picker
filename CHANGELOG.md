## [0.1.7+1]

* **Update:**
  * Fix required dart version

## [0.1.7]

* **Update:**
  * Upgrade packages
  * Support for flutter 3.x

## [0.1.6+1]

* **Update:**
  * Update readme

## [0.1.6]

* **Update:**
  * Camera, photo manager packages

## [0.1.5+5]

* **Fixbugs:**
  * Check permission for camera & photo gallery
  * Fixbug about OCR text editting

## [0.1.5+1]

* **New features:**
  * Add custom stickers (by @matthewmizzi suggestion)

## [0.1.5]

* **New features:**
  * Object detection & OCR extraction interface for image

## [0.1.4]d

* **New `ImagePickerConfigs` features:**
  * Camera flash mode `flashMode`, the starting flash mode for the camera
    can be set to other values than `FlashMode.auto`. The default is 
    `FlashMode.auto` as in previous version where it could not be modified. 
  * Option to remove the flash mode toggle button. If you do not want to
    allow users to change the flash mode, you can set `showFlashMode` to false.
    It defaults to true. If `showFlashMode` is false, the flash mode will use
    what is set by `flashMode`, since user cannot toggle it.
  * Config option to show and hide the lens direction icon button.
    If you want to show only one camera, you may also want to hide the
    button than enables users switch camera. You can then set 
    `showLensDirection` to false. If you show just one `cameraLensDirection` and 
    `showLensDirection` is true, then the lens direction button is still 
    shown, but disabled as in previous versions.
  * Only add the text line for `textSelectedImagesGuide` if it is not empty.
    If no drag reorder guidance label is specified in translation by returning
    empty string '' for `textSelectedImagesGuide`, then the extra line that 
    holds the text will also be removed, resulting in more camera view space.
  * For label `textSelectedImagesTitle` only show it, the colon and space 
    after it, if it is not empty. If you return a translated string that is 
    empty '', you can get only the selected "image / max" count shown, with no
    label and colon.
  * Use an `IconButton` as done button, instead of the default `OutlinedButton`.
    Set `doneButtonStyle` to `[DoneButtonStyle.iconButton]` for this option.
    Defaults to `DoneButtonStyle.outlinedButton`, that is the same as only 
    option in previous versions. You can also change the button icon by
    defining custom IconData for the `doneButtonIcon`.
  * Hide done action button when no images have been selected. This is optional
    new behavior that can be used instead of default, that disables it.
    Select the style with `doneButtonDisabledBehavior`.
  * Optional alert when removing selected images. If you set 
    `showRemoveImageAlert` to false, there is no alert dialog to confirm the 
    remove/delete of an image, when user clicks on the delete icon to 
    remove photos and images from the list of images to be used, they are 
    just removed immediately. Defaults to true, showing the alert dialog, 
    which is same behavior as in previous version.
   
* Update all dependencies to their latest versions, most notably image_editor to 
  version 1.0.1 that now uses Android embedding V2.
* Clean up remaining lint warnings. 

## [0.1.3]

* Improve code lintings.

## [0.1.2]

* Add feature to allow user add their owned image editors with ease (from mr.minhthuanit)

## [0.1.1]

* Optimize code by applying lint option from mr.rydmike
* Update camera plugin

## [0.1.0]

* Rewrite image sticker feature
* Update camera plugin to v0.9.1
* Improve UI customization

## [0.0.5+3]

* Fixbug repo

## [0.0.5+2]

* Fixbug UI

## [0.0.5+1]

* Fixbug CameraPreview error while get camera permission

## [0.0.5]

* Fixbug when removing selected images from list
* Fixbug when capture image rotated 270 degree

## [0.0.4+1]

* Update setting instructions for android

## [0.0.4]

* Fixbug image rotated in some android device
* Modified max width / max height default setting for capture images

## [0.0.3]

* Add ON/OFF camera/album feature
* Add lens direction setting feature

## [0.0.2+2]

* Fixbug camera number.

## [0.0.2+1]

* Lock capture orientation.

## [0.0.2]

* Migrated to null safety.

## [0.0.2-nullsafety.1]

* Migrate to null safety.

## [0.0.1+1]

* Format code.

## [0.0.1]

* Initial release.
