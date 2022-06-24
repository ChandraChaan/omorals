import 'package:url_launcher/url_launcher.dart';

class PhoneCommon {
  launchCaller() async {
    const url = "tel:1234567";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
