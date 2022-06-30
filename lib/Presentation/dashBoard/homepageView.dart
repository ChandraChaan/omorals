import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:omorals/Config/app_pages.dart';
import 'package:omorals/Presentation/dashBoard/slideShowView.dart';

class HomePageView extends StatefulWidget {
  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SideOffer(),
            SizedBox(
              height: 50,
            ),
            Text(
              'Well Come ' + (GetStorage().read('userName') ?? ''),
              style: Theme.of(context).textTheme.headline1,
            ),
            GetStorage().read('userName') == null
                ? TextButton(
                    onPressed: () {
                      Get.toNamed(Routes.login);
                    },
                    child: Text('Login'))
                : Container()
          ],
        ),
      ),
    );
  }
}
