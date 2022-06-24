import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:omorals/Application/Binding/homepage_binding.dart';
import 'package:omorals/Presentation/dashBoard/homepageView.dart';
import 'package:omorals/Presentation/forgotPassword/forgotPassword.dart';
import 'package:omorals/Presentation/login/loginScreenView.dart';
import 'package:omorals/Presentation/signup/signupView.dart';
import 'package:omorals/Presentation/splashScreen/splashScreen.dart';

part 'app_route.dart';

class AppPages {
  static const INITIAL = Routes.splash;
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
  ];
}
