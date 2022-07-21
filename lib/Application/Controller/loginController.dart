import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:omorals/Common/Loader.dart';
import 'package:omorals/Config/app_pages.dart';
import 'package:omorals/Infrastructure/login_param.dart';
import 'package:omorals/Provider/LoadingAdapter.dart';

class LoginController extends GetxController {
  LoginController({required this.yujRepository});

  /// inject repo abstraction dependency
  final ILoadingRepository yujRepository;
  String userNameValue = '';
  String profilePic = '';
  String role = '';
  final LocalDb = GetStorage();

  @override
  void onInit() {
    super.onInit();
    // callAPI();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  callAPI(String username, String password, {required BuildContext Bcontext}) {
    Loader.show(context: Bcontext);
    yujRepository
        .dynamic(LoginAPIModal(username: username, pasword: password))
        .then((data) {
      Get.back();
      LocalDb.write('userName', data.results['userName'].toString());
      LocalDb.write('role',
          '${data.results['userRole'].toString() == '0' ? 'Author' : (data.results['userRole'].toString() == '1' ? 'Editor' : ('Voice-artist'))}');

      Get.toNamed(Routes.homePageView);
    }, onError: (err) {
      Get.back();
      Get.snackbar(
        "Check Credential\'s once",
        " and try again",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    });
  }
}
