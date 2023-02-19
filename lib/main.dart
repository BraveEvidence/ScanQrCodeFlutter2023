import 'package:flutapp/MyScanQrView.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var isPermssionGranted = Platform.isAndroid ? false : true;
  static const cameraPermission = MethodChannel("camera_permission");

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _getCameraPermission();
    }
  }

  Future<void> _getCameraPermission() async {
    try {
      final bool result =
          await cameraPermission.invokeMethod('getCameraPermission');
      if (result) {
        setState(() {
          isPermssionGranted = true;
        });
      } else {
        debugPrint("Camera permission denied");
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get biometric: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      // backgroundColor: Colors.teal,
      body: isPermssionGranted
          ? MyScanQrView(
              width: width,
              height: height,
            )
          : SafeArea(child: Text("Give camera permission")),
    );
  }
}
