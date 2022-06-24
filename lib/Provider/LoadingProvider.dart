
import 'package:omorals/Network/LoadingNetwork.dart';

abstract class ILoadingProvider {
  dynamic(dynamic);
}

class LoadingProvider implements ILoadingProvider {
  @override
  dynamic(dynamic) => loadingNetwork.getAPIResponse(dynamic);
}
