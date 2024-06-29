import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:omorals/Config/app_pages.dart';

import '../../Utils/colors.dart';
import '../../Utils/constant.dart';
import '../../Utils/imagesConstants.dart';


class ForgotPage extends StatefulWidget {
  const ForgotPage({Key? key}) : super(key: key);

  @override
  _ForgotPageState createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final emailcontro = TextEditingController(text: '');
  final newpwcontroller = TextEditingController(text: '');
  final confimPwcontroller = TextEditingController(text: '');
  final emailcontroller = TextEditingController(text: '');
  final otpcontro = TextEditingController(text: '');
  bool _showPassword1 = true;
  bool _showPassword2 = true;

  bool email = false;
  String notp = "";

  @override
  Widget build(BuildContext context) {
    double width1 = getWidth(context);
    return Scaffold(
      body: width1 < 800
          ? SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                width: getWidth(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: getWidth(context),
                      height: 147,
                      child: Stack(
                        children: [
                          Container(
                            width: getWidth(context),
                            height: getHeight(context),
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(LocalImages.pinkFlower),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Get.toNamed(Routes.homePageView);
                            },
                            child: Container(
                              width: width1 / 5,
                              height: 30,
                              margin: const EdgeInsets.only(top: 18, left: 15),
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                LocalImages.flutterWallpaper,
                                scale: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: getWidth(context),
                      padding: const EdgeInsets.only(
                          left: 16, top: 21, right: 16, bottom: 37),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Create new password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              RichText(
                                text: const TextSpan(children: [
                                  TextSpan(
                                      text: 'Email',
                                      style: TextStyle(
                                          fontSize: textSizeSmallMedium,
                                          fontWeight: fontSemibold,
                                          color: Colors.black)),
                                  TextSpan(
                                      text: ' *',
                                      style: TextStyle(
                                          fontSize: textSizeSmallMedium,
                                          fontWeight: fontSemibold,
                                          color: Colors.red))
                                ]),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Container(
                                width: width1,
                                height: 45,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.black12),
                                  color: Colors.white,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30, top: 15, bottom: 14),
                                  child: TextFormField(
                                      controller: emailcontroller,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        fillColor: Colors.white,
                                        hintStyle: TextStyle(
                                          fontSize: textSizeSmallMedium,
                                          // color: hint_text_color
                                        ),
                                        hintText: "Email",
                                      )),
                                ),
                              ),
                              const SizedBox(
                                height: 30,
                              ),
                              email == true
                                  ? RichText(
                                      text: const TextSpan(children: [
                                        TextSpan(
                                            text: 'Enter OTP',
                                            style: TextStyle(
                                                fontSize: textSizeSmallMedium,
                                                fontWeight: fontSemibold,
                                                color: Colors.black)),
                                        TextSpan(
                                            text: ' *',
                                            style: TextStyle(
                                                fontSize: textSizeSmallMedium,
                                                fontWeight: fontSemibold,
                                                color: Colors.red))
                                      ]),
                                    )
                                  : ElevatedButton(
                                      onPressed: () {
                                        print(notp);
                                        if (emailcontroller.text.isNotEmpty) {
                                          int min =
                                              1000; //min and max values act as your 6 digit range
                                          int max = 9999;
                                          var randomizer = new Random();
                                          var rNum = min +
                                              randomizer.nextInt(max - min);
                                          // here we can write verify mail
                                          // emailVerifyController.callAPI(
                                          //   email: emailcontroller.text,
                                          //   otp: rNum,
                                          // );
                                          setState(() {
                                            email = true;
                                            notp = rNum.toString();
                                          });
                                          print(rNum.toString());
                                          // Get.toNamed(Routes.resetpassword);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('Please enter Email'),
                                          ));
                                        }
                                      },
                                      // color: text_blueColor,
                                      style: ElevatedButton.styleFrom(
                                          elevation: 12.0,
                                          textStyle: const TextStyle(
                                              color: text_blueColor)),
                                      child: const Text("Send OTP",
                                          style: TextStyle(color: c_White))),
                              email == true
                                  ? const SizedBox(
                                      height: 10,
                                    )
                                  : Container(),
                              email == true
                                  ? Container(
                                      width: width1,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        border:
                                            Border.all(color: Colors.black12),
                                        color: Colors.white,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 30, top: 15, bottom: 14),
                                        child: TextFormField(
                                            controller: otpcontro,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              fillColor: Colors.white,
                                              hintStyle: TextStyle(
                                                fontSize: textSizeSmallMedium,
                                                // color: hint_text_color
                                              ),
                                              hintText: "OTP",
                                            )),
                                      ),
                                    )
                                  : Container(),
                              const SizedBox(
                                height: 30,
                              ),
                              RichText(
                                text: const TextSpan(children: [
                                  TextSpan(
                                      text: 'New Password',
                                      style: TextStyle(
                                          fontSize: textSizeSmallMedium,
                                          fontWeight: fontSemibold,
                                          color: Colors.black)),
                                  TextSpan(
                                      text: ' *',
                                      style: TextStyle(
                                          fontSize: textSizeSmallMedium,
                                          fontWeight: fontSemibold,
                                          color: Colors.red))
                                ]),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Container(
                                width: width1,
                                height: 45,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.black12),
                                  color: Colors.white,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30, top: 15, bottom: 14),
                                  child: TextFormField(
                                      obscureText: _showPassword1,
                                      controller: newpwcontroller,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        suffixIcon: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _showPassword1 = !_showPassword1;
                                            });
                                          },
                                          child: Icon(
                                            _showPassword1
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                        ),
                                        border: InputBorder.none,
                                        fillColor: c_White,
                                        hintStyle: const TextStyle(
                                            fontSize: textSizeSmallMedium,
                                            color: hint_text_color),
                                        hintText: "password",
                                      )),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              const Text('Must be atleast 8 characters'),
                              const SizedBox(
                                height: 30,
                              ),
                              RichText(
                                text: const TextSpan(children: [
                                  TextSpan(
                                      text: 'Confirm Password',
                                      style: TextStyle(
                                          fontSize: textSizeSmallMedium,
                                          fontWeight: fontSemibold,
                                          color: Colors.black)),
                                  TextSpan(
                                      text: ' *',
                                      style: TextStyle(
                                          fontSize: textSizeSmallMedium,
                                          fontWeight: fontSemibold,
                                          color: Colors.red))
                                ]),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Container(
                                width: width1,
                                height: 45,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.black12),
                                  color: Colors.white,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30, top: 15, bottom: 14),
                                  child: TextFormField(
                                      obscureText: _showPassword2,
                                      controller: confimPwcontroller,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        suffixIcon: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _showPassword2 = !_showPassword2;
                                            });
                                          },
                                          child: Icon(
                                            _showPassword2
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                        ),
                                        border: InputBorder.none,
                                        fillColor: c_White,
                                        hintStyle: const TextStyle(
                                            fontSize: textSizeSmallMedium,
                                            color: hint_text_color),
                                        hintText: "password",
                                      )),
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          elevation: 12.0,
                                          textStyle: const TextStyle(
                                              color: Colors.white)),
                                      // color: Colors.white,
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.blue),
                                      )),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          elevation: 12.0,
                                          textStyle: const TextStyle(
                                              color: Colors.blue)),
                                      // color: Colors.blue,
                                      onPressed: () {
                                        if (emailcontroller.text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('Please fill EMail'),
                                          ));
                                        } else if (otpcontro.text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('Please fill OTP'),
                                          ));
                                        } else if (newpwcontroller
                                            .text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            content: Text(
                                                'Please fill new password'),
                                          ));
                                        } else if (confimPwcontroller
                                            .text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            content: Text(
                                                'Please fill confirm password'),
                                          ));
                                        } else if (confimPwcontroller
                                                .text.isNotEmpty &&
                                            newpwcontroller.text.isNotEmpty &&
                                            (notp == otpcontro.text) &&
                                            (confimPwcontroller.text ==
                                                newpwcontroller.text)) {
                                          // otpVelidateController.callAPI(
                                          //   email: emailcontroller.text,
                                          //   otp: int.parse(otpcontro.text),
                                          //   newPassword: newpwcontroller.text,
                                          //   confirmPassword:
                                          //   confimPwcontroller.text,
                                          // );
                                          // Get.Named();
                                          //Get.toNamed(Routes.loginScreen);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('Please fill EMail'),
                                          ));
                                        }
                                      },
                                      child: const Text(
                                        'Save',
                                        style: TextStyle(color: Colors.white),
                                      )),
                                ],
                              ),
                              const SizedBox(
                                height: 110,
                              ),
                              SizedBox(
                                width: getWidth(context),
                                height: 20,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: InkWell(
                                          onTap: () {
                                            print('termsAndCondition');
                                            // Get.toNamed(
                                            //     Routes.termsAndCondition);
                                          },
                                          child: const Text(
                                            "Terms",
                                            style: TextStyle(
                                                fontSize: textSizeSmallMedium,
                                                fontWeight: fontSemibold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Text(
                                          "|",
                                          style: TextStyle(
                                              fontSize: textSizeSmallMedium,
                                              fontWeight: fontSemibold,
                                              color: colorBlack),
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: InkWell(
                                        onTap: () {
                                          print('privacyPolicy');
                                          // Get.toNamed(Routes.privacyPolicy);
                                        },
                                        child: const Text(
                                          "Privacy policy",
                                          style: TextStyle(
                                              fontSize: textSizeSmallMedium,
                                              fontWeight: fontSemibold),
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Text(
                                          "|",
                                          style: TextStyle(
                                              fontSize: textSizeSmallMedium,
                                              fontWeight: fontSemibold,
                                              color: colorBlack),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: InkWell(
                                          onTap: () {},
                                          child: const Text(
                                            "Support",
                                            style: TextStyle(
                                                fontSize: textSizeSmallMedium,
                                                fontWeight: fontSemibold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          : SizedBox(
              width: getWidth(context),
              height: getHeight(context),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    Container(
                      child: Row(
                        children: [
                          Expanded(
                              flex: 1,
                              child: Stack(
                                children: [
                                  SizedBox(
                                    height: getHeight(context),
                                    child: Image.asset(
                                      LocalImages.white_flower,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Get.toNamed(Routes.homePageView);
                                    },
                                    child: Container(
                                      width: width1 / 5,
                                      height: 30,
                                      margin:
                                          const EdgeInsets.only(top: 57, left: 30),
                                      alignment: Alignment.centerLeft,
                                      child: Image.asset(
                                        LocalImages.flutterWallpaper,
                                        scale: 5,
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                          Expanded(
                              flex: 1,
                              child: Container(
                                color: c_White,
                                padding: const EdgeInsets.only(
                                    left: 80, top: 30, right: 155, bottom: 30),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Create new password',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    RichText(
                                      text: const TextSpan(children: [
                                        TextSpan(
                                            text: 'Email',
                                            style: TextStyle(
                                                fontSize: textSizeSMedium,
                                                fontWeight: fontSemibold,
                                                color: Colors.black)),
                                        TextSpan(
                                            text: ' *',
                                            style: TextStyle(
                                                fontSize: textSizeSMedium,
                                                fontWeight: fontSemibold,
                                                color: Colors.red))
                                      ]),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Container(
                                      width: width1,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        border:
                                            Border.all(color: Colors.black12),
                                        color: Colors.white,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 30, top: 15, bottom: 14),
                                        child: TextFormField(
                                            controller: emailcontroller,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              fillColor: Colors.white,
                                              hintStyle: TextStyle(
                                                fontSize: textSizeSmallMedium,
                                                // color: hint_text_color
                                              ),
                                              hintText: "Email",
                                            )),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 30,
                                    ),
                                    email == true
                                        ? RichText(
                                            text: const TextSpan(children: [
                                              TextSpan(
                                                  text: 'Enter OTP',
                                                  style: TextStyle(
                                                      fontSize: textSizeSMedium,
                                                      fontWeight: fontSemibold,
                                                      color: Colors.black)),
                                              TextSpan(
                                                  text: ' *',
                                                  style: TextStyle(
                                                      fontSize: textSizeSMedium,
                                                      fontWeight: fontSemibold,
                                                      color: Colors.red))
                                            ]),
                                          )
                                        : ElevatedButton(
                                            onPressed: () {
                                              print(notp);
                                              if (emailcontroller
                                                  .text.isNotEmpty) {
                                                int min =
                                                    1000; //min and max values act as your 6 digit range
                                                int max = 9999;
                                                var randomizer = new Random();
                                                var rNum = min +
                                                    randomizer
                                                        .nextInt(max - min);
                                                print('verify mail');
                                                // emailVerifyController.callAPI(
                                                //   email: emailcontroller.text,
                                                //   otp: rNum,
                                                // );
                                                setState(() {
                                                  email = true;
                                                  notp = rNum.toString();
                                                });
                                                print(rNum.toString());
                                                // Get.toNamed(Routes.resetpassword);
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  content: Text(
                                                      'Please enter Email'),
                                                ));
                                              }
                                            },
                                            // color: text_blueColor,
                                            style: ElevatedButton.styleFrom(
                                                elevation: 12.0,
                                                textStyle: const TextStyle(
                                                    color: text_blueColor)),
                                            child: const Text("Send OTP")),
                                    email == true
                                        ? const SizedBox(
                                            height: 10,
                                          )
                                        : Container(),
                                    email == true
                                        ? Container(
                                            width: width1,
                                            height: 45,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              border: Border.all(
                                                  color: Colors.black12),
                                              color: Colors.white,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 30,
                                                  top: 15,
                                                  bottom: 14),
                                              child: TextFormField(
                                                  controller: otpcontro,
                                                  keyboardType: TextInputType
                                                      .emailAddress,
                                                  decoration: const InputDecoration(
                                                    border: InputBorder.none,
                                                    fillColor: Colors.white,
                                                    hintStyle: TextStyle(
                                                      fontSize:
                                                          textSizeSmallMedium,
                                                      // color: hint_text_color
                                                    ),
                                                    hintText: "OTP",
                                                  )),
                                            ),
                                          )
                                        : Container(),
                                    const SizedBox(
                                      height: 30,
                                    ),
                                    RichText(
                                      text: const TextSpan(children: [
                                        TextSpan(
                                            text: 'New Password',
                                            style: TextStyle(
                                                fontSize: textSizeSMedium,
                                                fontWeight: fontSemibold,
                                                color: Colors.black)),
                                        TextSpan(
                                            text: ' *',
                                            style: TextStyle(
                                                fontSize: textSizeSMedium,
                                                fontWeight: fontSemibold,
                                                color: Colors.red))
                                      ]),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Container(
                                      width: width1,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        border:
                                            Border.all(color: Colors.black12),
                                        color: Colors.white,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 30, top: 15, bottom: 14),
                                        child: TextFormField(
                                            obscureText: _showPassword1,
                                            controller: newpwcontroller,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: InputDecoration(
                                              suffixIcon: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _showPassword1 =
                                                        !_showPassword1;
                                                  });
                                                },
                                                child: Icon(
                                                  _showPassword1
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                ),
                                              ),
                                              border: InputBorder.none,
                                              fillColor: c_White,
                                              hintStyle: const TextStyle(
                                                  fontSize: textSizeSmallMedium,
                                                  color: hint_text_color),
                                              hintText: "password",
                                            )),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    const Text('Must be atleast 8 characters'),
                                    const SizedBox(
                                      height: 30,
                                    ),
                                    RichText(
                                      text: const TextSpan(children: [
                                        TextSpan(
                                            text: 'Confirm Password',
                                            style: TextStyle(
                                                fontSize: textSizeSMedium,
                                                fontWeight: fontSemibold,
                                                color: Colors.black)),
                                        TextSpan(
                                            text: ' *',
                                            style: TextStyle(
                                                fontSize: textSizeSMedium,
                                                fontWeight: fontSemibold,
                                                color: Colors.red))
                                      ]),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Container(
                                      width: width1,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        border:
                                            Border.all(color: Colors.black12),
                                        color: Colors.white,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 30, top: 15, bottom: 14),
                                        child: TextFormField(
                                            obscureText: _showPassword2,
                                            controller: confimPwcontroller,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: InputDecoration(
                                              suffixIcon: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _showPassword2 =
                                                        !_showPassword2;
                                                  });
                                                },
                                                child: Icon(
                                                  _showPassword2
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                ),
                                              ),
                                              border: InputBorder.none,
                                              fillColor: c_White,
                                              hintStyle: const TextStyle(
                                                  fontSize: textSizeSmallMedium,
                                                  color: hint_text_color),
                                              hintText: "password",
                                            )),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 40,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                            // color: Colors.white,
                                            style: ElevatedButton.styleFrom(
                                                elevation: 12.0,
                                                textStyle: const TextStyle(
                                                    color: Colors.white)),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                              'Cancel',
                                              style:
                                                  TextStyle(color: Colors.blue),
                                            )),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        ElevatedButton(
                                            // color: Colors.blue,
                                            style: ElevatedButton.styleFrom(
                                                elevation: 12.0,
                                                textStyle: const TextStyle(
                                                    color: Colors.blue)),
                                            onPressed: () {
                                              if (emailcontroller
                                                  .text.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  content:
                                                      Text('Please fill EMail'),
                                                ));
                                              } else if (otpcontro
                                                  .text.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  content:
                                                      Text('Please fill OTP'),
                                                ));
                                              } else if (newpwcontroller
                                                  .text.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  content: Text(
                                                      'Please fill new password'),
                                                ));
                                              } else if (confimPwcontroller
                                                  .text.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  content: Text(
                                                      'Please fill confirm password'),
                                                ));
                                              } else if (confimPwcontroller
                                                      .text !=
                                                  newpwcontroller.text) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  content: Text(
                                                      'Please Check password'),
                                                ));
                                              } else if (confimPwcontroller
                                                      .text.isNotEmpty &&
                                                  newpwcontroller
                                                      .text.isNotEmpty &&
                                                  (notp == otpcontro.text) &&
                                                  (confimPwcontroller.text ==
                                                      newpwcontroller.text)) {
                                                print('hit api here');
                                                // otpVelidateController.callAPI(
                                                //   email: emailcontroller.text,
                                                //   otp:
                                                //   int.parse(otpcontro.text),
                                                //   newPassword:
                                                //   newpwcontroller.text,
                                                //   confirmPassword:
                                                //   confimPwcontroller.text,
                                                // );
                                                // Get.Named();
                                                //Get.toNamed(Routes.loginScreen);
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  content:
                                                      Text('Please fill EMail'),
                                                ));
                                              }
                                            },
                                            child: const Text(
                                              'Save',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            )),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 110,
                                    ),
                                    SizedBox(
                                      width: getWidth(context),
                                      height: 20,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: InkWell(
                                                onTap: () {
                                                  print('termsAndCondition');
                                                  // Get.toNamed(
                                                  //     Routes.termsAndCondition);
                                                },
                                                child: const Text(
                                                  "Terms",
                                                  style: TextStyle(
                                                      fontSize: textSizeSMedium,
                                                      fontWeight: fontSemibold),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: Text(
                                                "|",
                                                style: TextStyle(
                                                    fontSize: textSizeSMedium,
                                                    fontWeight: fontSemibold,
                                                    color: colorBlack),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: InkWell(
                                                onTap: () {
                                                  print('privacyPolicy');
                                                  // Get.toNamed(
                                                  //     Routes.privacyPolicy);
                                                },
                                                child: const Text(
                                                  "Privacy policy",
                                                  style: TextStyle(
                                                      fontSize: textSizeSMedium,
                                                      fontWeight: fontSemibold),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: Text(
                                                "|",
                                                style: TextStyle(
                                                    fontSize: textSizeSMedium,
                                                    fontWeight: fontSemibold,
                                                    color: colorBlack),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Center(
                                              child: InkWell(
                                                onTap: () {},
                                                child: const Text(
                                                  "Support",
                                                  style: TextStyle(
                                                      fontSize: textSizeSMedium,
                                                      fontWeight: fontSemibold),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
