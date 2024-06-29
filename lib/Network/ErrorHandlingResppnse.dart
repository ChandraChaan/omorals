import 'package:dio/dio.dart';

import 'Logger.dart';

class ErrorHandling {

  static dynamic responseError(DioError exception){
    try{
          switch(exception.type){
            case DioExceptionType.connectionTimeout:
              return "Connection  Timeout Occur";
              break;
            case DioExceptionType.sendTimeout:
              return "Connection  Timeout Occur";
              break;
            case DioExceptionType.receiveTimeout:
              return "Connection  Timeout Occur";
              break;
            case DioExceptionType.badCertificate:
              return "Connection  Timeout Occur";
              break;
            case DioExceptionType.connectionError:
              return "Connection  Timeout Occur";
              break;
            case DioExceptionType.badResponse:
              switch(exception.response?.statusCode){
                case 400:
                  return "The request cannot be fulfilled due to bad syntax";
                  break;
                case 401:
                  return exception.response?.data;
                  break;
                case 500:
                  return exception.response?.data;
                  break;
                default :
                  if(exception.response != null)
                      if(exception.response?.statusMessage != null)
                        return exception.response?.statusMessage.toString();
                      else
                        return exception.response.toString();
                  else
                    return exception.toString();
                  break;
              }
              break;
            case DioExceptionType.cancel:
              return "Request is cancelled";
              break;
            case DioExceptionType.unknown:
              Logger.writeLog(exception.response);
              return "Oops something went wrong please try after sometime";
              break;

          }
    }on Exception catch (error) {
      Logger.writeLog('errorOth: $error');
      return error.toString();
    }
  }
}
