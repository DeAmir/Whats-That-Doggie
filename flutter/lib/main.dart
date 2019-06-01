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
  final first_camera = cameras.first;

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
    print("moving with categorybars=${category_bars}");
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

  List<int> three_maxes_indexes(List<double> source) {
    int top3 = 0, top2 = 0, top1 = 0;
    for (int idx = 0; idx < source.length; idx++) {
      if (source[idx] > source[top1]) {
        top3 = top2;
        top2 = top1;
        top1 = idx;
      } else if (source[idx] > source[top2]) {
        top3 = top2;
        top2 = idx;
      } else if (source[idx] > source[top3]) {
        top3 = idx;
      }
    }

    return [top1, top2, top3];
  }

  List<CategoryBar> format_categories(String unformatted) {
    var arr = unformatted.split(",");
    var formatted_arr = [
      for (String i in arr) double.parse(i) * 100
    ]; // times 100 for viewing on the chart more clearly
    var maxes = three_maxes_indexes(formatted_arr);
    print("maxes: ${maxes}");

    List<CategoryBar> ret = List();

    for (int idx = 0; idx < maxes.length; idx++) {
      int real_index = maxes[idx];
      String label = LABELS[real_index];
      double prob = formatted_arr[real_index];

      Color c = Colors.red;
      if (idx == 0) {
        c = Colors.blue;
      }

      var add = CategoryBar(label, prob, c);
      print("adding ${add}");
      ret.add(add);
    }
    print("returning: ${ret}");

    return ret;
  }

  void doWork(BuildContext context, bool take_camera) async {
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
      showLoader(true);
      String category_unformatted = await predictPicture(path);
      List<CategoryBar> formatted = format_categories(category_unformatted);
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Dog Breed Detector"),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              child: FlatButton(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "Take image",
                      style: TextStyle(fontSize: 20),
                    ),
                    Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 10),),
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
              height: 100,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
