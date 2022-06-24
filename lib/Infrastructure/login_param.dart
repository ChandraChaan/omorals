import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:omorals/Common/helper.dart';
import 'package:omorals/Domain/DataClass/loginModel.dart';
import 'package:omorals/Network/NetworkDataClass.dart';
import 'package:omorals/Network/NetworkStrings.dart';

class LoginAPIModal {
  final String username;
  final String pasword;

  LoginAPIModal({required this.pasword, required this.username});

  Map<String, dynamic> toJsonResources() {
    return {"email": username, "password": pasword};
  }

  NetworkDataClass getParam() {
    return NetworkDataClass(
        baseUrl: Helpers.baseUrl,
        extendedUrl: Helpers.login,

        options: Options(
          headers: {"content-type": "application/json"},
        ),
        isCookie: false,
        param: jsonEncode(toJsonResources()),
        requestType: NetworkString.requestPost);
  }

  fromJson(val) => LoginModal.fromJson(val);

  withError(error) => LoginModal.withError(error);

  fromJsonError(valError) => LoginModal.fromJsonError(valError);
}
