import 'package:dio/dio.dart';

class NetworkDataClass {
  String baseUrl, extendedUrl, requestType;
  bool isCookie, needCookies;
  var param;
  Options options;

  NetworkDataClass(
      {required this.baseUrl,
      required this.extendedUrl,
      this.isCookie = false,
      this.param,
      required this.requestType,
      required this.options,
      this.needCookies = true});
}
