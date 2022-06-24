import 'package:get/get.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:omorals/Application/Controller/HomePageController.dart';
import 'package:omorals/Application/Controller/loginController.dart';
import 'package:omorals/Provider/LoadingAdapter.dart';
import 'package:omorals/Provider/LoadingProvider.dart';
import 'package:omorals/Provider/LoadingRepository.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ILoadingProvider>(() => LoadingProvider());

    Get.lazyPut<ILoadingRepository>(
        () => LoadingRepository(provider: Get.find()));

    Get.lazyPut(() => GetHomePageController(apiCallRepository: Get.find()));
    Get.lazyPut(() => LoginController(yujRepository: Get.find()));

  }
}
