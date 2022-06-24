
import 'package:omorals/Domain/domain_class/GetHomePage_domain.dart';

class GetHomePageModel {
  var error;
  String? responseOther;
  List<ViewAllHomePageLis>? results;

  GetHomePageModel({this.results, this.error, this.responseOther});

  static GetHomePageModel fromJson(json) => GetHomePageModel(
      results: json['data'] == null
          ? null
          : List<ViewAllHomePageLis>.from(
              json['data'].map((i) => ViewAllHomePageLis.fromJson(i))),
      responseOther: json['data'] == null ? null : json.toString(),
      error: json);

  static GetHomePageModel withError(error) =>
      GetHomePageModel(results: null, responseOther: null, error: error);

  static GetHomePageModel fromJsonError(json) => GetHomePageModel(
      results: null, responseOther: json.toString(), error: json);
}
