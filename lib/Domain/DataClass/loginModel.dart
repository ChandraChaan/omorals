class LoginModal {
  var error;
  String? responseOther;
  var results;

  LoginModal({this.results, this.error, this.responseOther});

  static LoginModal fromJson(json) => LoginModal(
      results: json['data'] == null ? null : json['data'],
      responseOther:
      json['message'] == null ? null : json['message'].toString(),
      error: json['message']);

  static LoginModal withError(error) =>
      LoginModal(results: null, responseOther: null, error: error);

  static LoginModal fromJsonError(json) => LoginModal(
      results: null,
      responseOther:
      json['message'] == null ? null : json['message'].toString(),
      error: json['message']);
}
