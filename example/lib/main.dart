import 'dart:io';

import 'package:flutter/material.dart';
import 'package:advance_image_picker/advance_image_picker.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ErrorWidget(details.exception);
  };
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Setup image picker configs
    var configs = ImagePickerConfigs();
    // AppBar text color
    configs.appBarTextColor = Colors.white;
    // Disable select images from album
    configs.albumPickerModeEnabled = false;
    // Only use front camera for capturing
    configs.cameraLensDirection = 0;
    // Translate function
    configs.translateFunc = (name, value) => Intl.message(value, name: name);

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'advance_image_picker Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ImageObject> _imgObjs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            GridView.builder(
                shrinkWrap: true,
                itemCount: _imgObjs.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    childAspectRatio: 1),
                itemBuilder: (BuildContext context, int index) {
                  var image = _imgObjs[index];
                  return Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Image.file(File(image.modifiedPath),
                        height: 80, fit: BoxFit.cover),
                  );
                })
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Get max 5 images
          List<ImageObject>? objects = await Navigator.of(context)
              .push(PageRouteBuilder(pageBuilder: (context, animation, __) {
            return ImagePicker(maxCount: 5, isCaptureFirst: true);
          }));

          if ((objects?.length ?? 0) > 0) {
            setState(() {
              _imgObjs = objects!;
            });
          }
        },
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
