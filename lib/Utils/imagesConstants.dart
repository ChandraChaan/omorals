import 'dart:convert';

class LocalImages {

  static const String flutterWallpaper = "assets/images/splashScreen_flutter.jpg";
  static const String blueRose = "assets/images/blue_rose.jpg";
  static const String pinkFlower = "assets/images/pink_flower.jpg";
  static const String pink_rose = "assets/images/pink_rose.jpg";
  static const String white_flower = "assets/images/white_flower.jpg";
  static const String img_google_logos = "assets/images/google-logos.png";

  String convertToBase64(String credentials) {
    final Codec<String, String> stringToBase64 = utf8.fuse(base64);
    return stringToBase64.encode(credentials);
  }

  String base64ToString(String credentials) {
    final Codec<String, String> base64ToString = utf8.fuse(base64);
    return base64ToString.decode(credentials);
  }
}

