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
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp
    ]);
  }

  void showToast(msg) {
    Fluttertoast.showToast(
        msg: msg, timeInSecForIos: 5, gravity: ToastGravity.CENTER);
  }

  Future<String> takePicture() async {
    print("taking picture...");
    var completer = Completer<String>();

    try {
      // make sure the controller is initialized
      await _initializeControllerFuture;

      // get path to store the image
      // get temp directory, and add the name currenttime.png
      final path =
          join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');

      await _controller.takePicture(path);
      print("Picture taken and saved at ${path}");

      completer.complete(path);
    } catch (e) {
      print("Error: ${e}");
      completer.complete('');
    }

    return completer.future;
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

  Future<bool> validateImage(path, BuildContext cont) {
    File img = File.fromUri(Uri(path: path));
    var completer = Completer<bool>();

    Widget okButton = FlatButton(
        onPressed: () {
          Navigator.pop(cont);
          completer.complete(true);
        },
        child: Text('Ok'));

    Widget cancelButton = FlatButton(
        onPressed: () {
          Navigator.pop(cont);
          completer.complete(false);
        },
        child: Text("Retake image"));

    final image = Image.file(img);

    AlertDialog alertDialog = AlertDialog(
      title: Text("Is the image ok?"),
      content: image,
      actions: <Widget>[okButton, cancelButton],
    );

    showDialog(
        context: cont,
        builder: (BuildContext context) {
          return alertDialog;
        });

    return completer.future;
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
    var formatted_arr = [for (String i in arr) double.parse(i) * 100]; // times 100 for viewing on the chart more clearly
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

  void doWork(BuildContext context) async {
    String path = await takePicture();
    if (path != null) {
      bool imageOk = await validateImage(path, context);
      if (imageOk) {
        showLoader(true);
        String category_unformatted = await predictPicture(path);
        List<CategoryBar> formatted = format_categories(category_unformatted);
        if (category_unformatted == '') {
          showToast(
              "Error with category prediction. Maybe internet connectivity issue.");
        } else {
          moveScreen(formatted, context, path);
        }
      }
    } else {
      print("Path is null at doWork");
    }
    showLoader(false);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dog Breed Detector"),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              loading == false) {
            // when ok display feed with initialized controller
            print("Starting camera preview...");
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (loading == false) {
            doWork(context);
          }
        },
        child: Icon(Icons.camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
