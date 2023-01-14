import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:omorals/Application/Binding/homepage_binding.dart';
import 'package:omorals/Presentation/dashBoard/homepageView.dart';
import 'package:omorals/Presentation/forgotPassword/forgotPassword.dart';
import 'package:omorals/Presentation/login/loginScreenView.dart';
import 'package:omorals/Presentation/signup/signupView.dart';
import 'package:omorals/Presentation/splashScreen/splashScreen.dart';

import '../Presentation/autherPage/autherPage.dart';
import '../Presentation/voice_page/voice_view.dart';

part 'app_route.dart';

class AppPages {
  static const INITIAL = Routes.homePageView;
  static final routes = [
    GetPage(
        name: Routes.splash,
        page: () => splashScreen(),
        binding: MainBinding()),
    GetPage(
        name: Routes.login, page: () => loginScreen(), binding: MainBinding()),
    GetPage(
        name: Routes.homePageView,
        page: () => HomePageView(),
        binding: MainBinding()),
    GetPage(
        name: Routes.resetpassword,
        page: () => ForgotPage(),
        binding: MainBinding()),
    GetPage(
        name: Routes.signUpScreen,
        page: () => SignUpScreen(),
        binding: MainBinding()),
    GetPage(
        name: Routes.voicePage,
        page: () => VoiceView(),
        binding: MainBinding()),
    GetPage(
        name: Routes.autherPage,
        page: () => AutherPage(),
        binding: MainBinding()),
  ];
}
