import 'dart:convert';

class Helpers {
  static final String baseUrl = "https://original-morals.herokuapp.com/api/";
  static final String login = "user/login";

  String convertToBase64(String credentials) {
    final Codec<String, String> stringToBase64 = utf8.fuse(base64);
    return stringToBase64.encode(credentials);
  }

  String base64ToString(String credentials) {
    final Codec<String, String> base64ToString = utf8.fuse(base64);
    return base64ToString.decode(credentials);
  }
}
