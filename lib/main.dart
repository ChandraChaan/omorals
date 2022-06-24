import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'Config/app_pages.dart';
import 'Network/logger.dart';
import 'lang/translation_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    HttpClient httpClient = super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };
    return httpClient;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await GetStorage.init();
  runApp(MoralsApp());
}

class MoralsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Original Morals',
      logWriterCallback: Logger.write,
      getPages: AppPages.routes,
      initialRoute: AppPages.INITIAL,
      locale: const Locale('en', 'US'),
      fallbackLocale: TranslationService.fallbackLocale,
      translations: TranslationService(),
    );
  }
}
