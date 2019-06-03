import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:async/async.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'CategoryInfo.dart';

// change this to your address
final String SERVER_URL = "http://10.100.102.16/";

Future<void> main() async {
  final cameras = await availableCameras();
  var first_camera;
  if (cameras.isNotEmpty) {
    if (Platform.isIOS) {
      print("Real device detected. Camera usage is supported.");
    }
    first_camera = cameras.first;
  } else {
    if (Platform.isIOS) {
      print("Running on emulator. Camera functionality won't work.");
    }
  }

  runApp(MaterialApp(
      home: MyHomePage(
    camera: first_camera,
    title: "Doggie detector",
  )));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, @required this.camera}) : super(key: key);
  final CameraDescription camera;

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool loading = false;
  double height, width;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
  }

  void showToast(msg) {
    Fluttertoast.showToast(
        msg: msg, timeInSecForIos: 5, gravity: ToastGravity.CENTER);
  }

  Future<String> predictPicture(path) async {
    var completer = Completer<String>();
    try {
      File imageFile = File.fromUri(Uri(path: path));

      var stream =
          new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
      var length = await imageFile.length();

      var uri = Uri.parse(SERVER_URL);

      var request = new http.MultipartRequest("POST", uri);

      var multipartFile = new http.MultipartFile('file', stream, length,
          filename: basename(imageFile.path));

      request.files.add(multipartFile);

      var response = await request.send();

      response.stream.transform(utf8.decoder).listen((value) {
        completer.complete(value.toString());
      });
    } catch (e) {
      print("Error in predictPicture: ${e}");
      completer.complete('');
    }
    return completer.future;
  }

  void moveScreen(category_bars, cont, path) {
    Navigator.push(
        cont,
        MaterialPageRoute(
            builder: (cont) => CategoryInfo(
                  path: path,
                  categoryBars: category_bars,
                )));
  }

  void showLoader(bool show) {
    setState(() {
      loading = show;
    });
  }

  List<int> range(lower_than) {
    var ret = List<int>();
    for (var num = 0; num < lower_than; num++) {
      ret.add(num);
    }
    return ret;
  }

  List<CategoryBar> format_categories(String unformatted) {
    var list = unformatted.split(",");
    var labels = [];
    var probs = [];

    var idx = 0;
    while (idx < list.length) {
      if (idx % 2 == 0) {
        labels.add(list[idx]);
      } else {
        probs.add(double.parse(list[idx]));
      }
      idx++;
    }

    final ret = [
      for (var i in range(probs.length))
        CategoryBar(labels[i], probs[i], Colors.lime)
    ];

    ret[0].setColor(Colors.green);

    return ret;
  }

  void doWork(BuildContext context, bool take_camera) async {
    showLoader(true);
    String path;
    if (take_camera) {
      File a = await ImagePicker.pickImage(source: ImageSource.camera);
      path = a.path;
    } else {
      // take from gallery
      File a = await ImagePicker.pickImage(source: ImageSource.gallery);
      path = a.path;
    }
    if (path != null) {
      String category_unformatted = await predictPicture(path);
      print("unformatted: ${category_unformatted}");
      List<CategoryBar> formatted = format_categories(category_unformatted);
      print("formatted: ${formatted}");
      if (category_unformatted == '') {
        showToast(
            "Error with category prediction. Maybe internet connectivity issue.");
      } else {
        moveScreen(formatted, context, path);
      }
    } else {
      print("Path is null at doWork");
    }
    showLoader(false);
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("Dog Breed Detector"),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: (loading)
              ? CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 100,
                      child: FlatButton(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text("Take image",
                                style: TextStyle(
                                  fontSize: 20,
                                )),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                            ),
                            Icon(
                              Icons.camera,
                              size: 40,
                            )
                          ],
                        ),
                        onPressed: () {
                          doWork(context, true);
                        },
                      ),
//                    width: width,
                    ),
                    SizedBox(
                      height: 100,
                      child: FlatButton(
                        onPressed: () {
                          doWork(context, false);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text("Import image from gallery",
                                style: TextStyle(fontSize: 20)),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                            ),
                            Icon(
                              Icons.file_upload,
                              size: 40,
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
