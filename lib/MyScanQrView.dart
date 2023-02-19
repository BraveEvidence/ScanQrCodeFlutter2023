import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyScanQrView extends StatefulWidget {
  const MyScanQrView({required this.width, required this.height, super.key});

  final double width;
  final double height;

  @override
  State<MyScanQrView> createState() => _MyScanQrViewState();
}

class _MyScanQrViewState extends State<MyScanQrView> {
  final Map<String, dynamic> creationParams = <String, dynamic>{};
  final channel = const MethodChannel('scanQrView');

  @override
  void initState() {
    super.initState();
    creationParams["width"] = widget.width;
    creationParams["height"] = widget.height;
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid
        ? AndroidView(
            viewType: 'scanQrView',
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onPlatformViewCreated,
          )
        : UiKitView(
            viewType: 'scanQrView',
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onPlatformViewCreated,
          );
  }

  void _onPlatformViewCreated(int id) {
    channel.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'sendFromNative':
        String text = call.arguments as String;
        debugPrint("text is " + text);
    }
  }
}
