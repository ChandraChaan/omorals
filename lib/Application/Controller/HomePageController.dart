import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:omorals/Domain/DataClass/GetHomePageModel.dart';
import 'package:omorals/Infrastructure/GetHomePage_param.dart';
import 'package:omorals/Provider/LoadingAdapter.dart';

class GetHomePageController extends SuperController<GetHomePageModel> {
  GetHomePageController({required this.apiCallRepository});

  /// inject repo abstraction dependency
  final ILoadingRepository apiCallRepository;

  /// When the controller is initialized, make the http request
  TextEditingController name = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController complaint = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // callAPI();
  }

  @override
  void onReady() {
    print('The build method is done. '
        'Your controller is ready to call dialogs and snackbars');
    super.onReady();
  }

  @override
  void onClose() {
    print('onClose called');
    super.onClose();
  }

  callAPI() {
    change(null, status: RxStatus.loading());
    apiCallRepository.dynamic(GetHomePageAPIModel()).then((data) {
      change(data, status: RxStatus.success());
    }, onError: (err) {
      print(err);
      change(null, status: RxStatus.error(err.toString()));
    });
  }

  @override
  void onDetached() {
    // TODO: implement onDetached
  }

  @override
  void onInactive() {
    // TODO: implement onInactive
  }

  @override
  void onPaused() {
    // TODO: implement onPaused
  }

  @override
  void onResumed() {
    // TODO: implement onResumed
  }
}
