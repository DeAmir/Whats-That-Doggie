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

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  void showToast(msg){
    Fluttertoast.showToast(msg: msg,timeInSecForIos: 5,gravity: ToastGravity.CENTER);
  }

  Future<String> takePicture() async {
    print("taking picture...");

    try {
      // make sure the controller is initialized
      await _initializeControllerFuture;

      // get path to store the image
      // get temp directory, and add the name currenttime.png
      final path =
          join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');

      await _controller.takePicture(path);
      print("Picture taken and saved at ${path}");

      return path;
    } catch (e) {
      print("Error: ${e}");
    }
  }

  Future<String> predictPicture(path) async {
    var completer = Completer<String>();
    try {
      File imageFile = File.fromUri(Uri(path: path));

      var stream =
          new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
      // get file length
      var length = await imageFile.length();

      // string to uri
      var uri = Uri.parse("http://10.100.102.16/");

      // create multipart request
      var request = new http.MultipartRequest("POST", uri);

      // multipart that takes file
      var multipartFile = new http.MultipartFile('file', stream, length,
          filename: basename(imageFile.path));

      // add file to multipart
      request.files.add(multipartFile);

      // send
      var response = await request.send();
      // listen for response
      response.stream.transform(utf8.decoder).listen((value) {
        completer.complete(value.toString());
      });
    } catch (e) {
      print("Error in predictPicture: ${e}");
      completer.complete('');
    }
    return completer.future;
  }

  void moveScreen(category) {}

  void doWork() async {
    String path = await takePicture();
    if (path != null) {
      print("Finding category...");
      showToast("Detecting picture...");
      String category = await predictPicture(path);
      print("Category: ${category}");
      showToast(category);

      if (category == '') {
        print("Error with category prediction");
      }
    } else {
      print("Path is null at doWork");
    }
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
          if (snapshot.connectionState == ConnectionState.done) {
            // when ok display feed with initialized controller
            print("Starting camera preview...");
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: doWork,
        child: Icon(Icons.camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
