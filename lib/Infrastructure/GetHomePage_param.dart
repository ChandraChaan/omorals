import 'package:dio/dio.dart';
import 'package:omorals/Common/helper.dart';
import 'package:omorals/Domain/DataClass/GetHomePageModel.dart';
import 'package:omorals/Network/NetworkDataClass.dart';
import 'package:omorals/Network/NetworkStrings.dart';

class GetHomePageAPIModel {
  FormData getFormData() {
    return FormData.fromMap(<String, dynamic>{
      "image": "null",
    });
  }

  NetworkDataClass getParam() {
    return NetworkDataClass(
        baseUrl: Helpers.baseUrl,
        extendedUrl: Helpers.login,
        options: Options(
          headers: {},
        ),
        // headers: {},
        isCookie: false,
        param: getFormData(),
        requestType: NetworkString.requestGet);
  }

  fromJson(val) => GetHomePageModel.fromJson(val);

  withError(error) => GetHomePageModel.withError(error);

  fromJsonError(valError) => GetHomePageModel.fromJsonError(valError);
}
