import 'dart:convert';

class localimages {

  static final String flutterWallpaper = "assets/images/splashScreen_flutter.jpg";
  static final String blue_rose = "assets/images/blue_rose.jpg";
  static final String pink_flower = "assets/images/pink_flower.jpg";
  static final String pink_rose = "assets/images/pink_rose.jpg";
  static final String white_flower = "assets/images/white_flower.jpg";
  static final String img_google_logos = "assets/images/google-logos.png";

  String convertToBase64(String credentials) {
    final Codec<String, String> stringToBase64 = utf8.fuse(base64);
    return stringToBase64.encode(credentials);
  }

  String base64ToString(String credentials) {
    final Codec<String, String> base64ToString = utf8.fuse(base64);
    return base64ToString.decode(credentials);
  }
}

