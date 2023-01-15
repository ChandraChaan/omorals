import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:location/location.dart';

class WebHandler extends StatefulWidget {
  final Widget child;

  const WebHandler({Key? key, required this.child}) : super(key: key);

  @override
  State<WebHandler> createState() => _WebHandlerState();
}

class _WebHandlerState extends State<WebHandler> {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  late WebBrowserInfo webBrowserInfo;

  Location location = new Location();

  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  late LocationData _locationData;

  locationWeb() async {
    _serviceEnabled = await location.serviceEnabled();

    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();

    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
  }

  deviceDataWeb() async {
    webBrowserInfo = await deviceInfo.webBrowserInfo;
    setState(() {});
  }

  @override
  void initState() {
    deviceDataWeb();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(webBrowserInfo.browserName.toString() == 'null'
            ? ''
            : webBrowserInfo.browserName.toString().split(".").last),
      ),
      body: widget.child,
    );
  }
}
