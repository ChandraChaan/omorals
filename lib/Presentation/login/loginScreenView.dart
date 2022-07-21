import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:omorals/Application/Controller/loginController.dart';
import 'package:omorals/Config/app_pages.dart';
import 'package:omorals/Utils/colors.dart';
import 'package:omorals/Utils/constant.dart';
import 'package:omorals/Utils/imagesConstants.dart';

class loginScreen extends StatefulWidget {
  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {
  final LoginController loginController = Get.find();

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   print('add something');
    // });
  }

  bool _showPassword1 = true;

  final pwcontroller = TextEditingController();

  final emailcontroller = TextEditingController();

  final forgotpeconteroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double width1 = getWidth(context);

    return Scaffold(
      body: SafeArea(
        child: width1 < 800
            ? SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(
                  width: getWidth(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: getWidth(context),
                        height: 147,
                        child: Stack(
                          children: [
                            Container(
                              width: getWidth(context),
                              height: getHeight(context),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(localimages.blue_rose),
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
                                margin: EdgeInsets.only(top: 18, left: 15),
                                alignment: Alignment.centerLeft,
                                child: Image.asset(
                                  localimages.flutterWallpaper,
                                  scale: 5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: getWidth(context),
                        padding: EdgeInsets.only(
                            left: 16, top: 21, right: 16, bottom: 37),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Log in",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            // SizedBox(
                            //   height: 15,
                            // ),
                            // InkWell(
                            //   onTap: () {},
                            //   child: Container(
                            //     width: getWidth(context),
                            //     height: 45,
                            //     color: ColorElement.white900,
                            //     child: Row(
                            //       mainAxisAlignment: MainAxisAlignment.center,
                            //       crossAxisAlignment: CrossAxisAlignment.center,
                            //       children: [
                            //         Container(
                            //             width: 20,
                            //             height: 45,
                            //             child: Image.asset(localimages
                            //                 .img_google_logos) //SvgPicture.asset(img_google_logo),
                            //             ),
                            //         SizedBox(
                            //           width: 10,
                            //         ),
                            //         Text(
                            //           "Use Google Account",
                            //           style: TextStyle(
                            //               fontSize: textSizeSmallMedium,
                            //               color: colorBlack,
                            //               fontWeight: FontWeight.w500),
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            // SizedBox(
                            //   height: 20,
                            // ),
                            // Row(
                            //   children: [
                            //     Expanded(
                            //       flex: 1,
                            //       child: Container(
                            //         width: getWidth(context),
                            //         height: 1,
                            //         color: colorBlack,
                            //       ),
                            //     ),
                            //     Padding(
                            //       padding: const EdgeInsets.only(
                            //           left: 10, right: 10),
                            //       child: Text(
                            //         "Or",
                            //         style: TextStyle(
                            //             fontSize: textSizeSmallMedium),
                            //       ),
                            //     ),
                            //     Expanded(
                            //       flex: 1,
                            //       child: Container(
                            //         width: getWidth(context),
                            //         height: 1,
                            //         color: colorBlack,
                            //       ),
                            //     )
                            //   ],
                            // ),
                            SizedBox(
                              height: 20,
                            ),
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                    text: 'Email address',
                                    style: TextStyle(
                                        fontSize: textSizeSmallMedium,
                                        fontWeight: fontSemibold,
                                        color: colorBlack)),
                                TextSpan(
                                    text: '*',
                                    style: TextStyle(
                                        color: c_red,
                                        fontSize: textSizeSMedium)),
                              ]),
                            ),
                            SizedBox(
                              height: 12,
                            ),
                            Container(
                              width: width1,
                              height: 45,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: colorBlack),
                                color: c_White,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 20, top: 13, bottom: 13),
                                child: TextFormField(
                                    controller: emailcontroller,
                                    keyboardType: TextInputType.emailAddress,
                                    textAlignVertical: TextAlignVertical.center,
                                    textAlign: TextAlign.left,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.all(10.0),
                                      border: InputBorder.none,
                                      fillColor: c_White,
                                      hintStyle: TextStyle(
                                          fontSize: textSizeSmall,
                                          color: hint_text_color),
                                      hintText: "Email address",
                                    )),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                    text: 'Password',
                                    style: TextStyle(
                                        fontSize: textSizeSmallMedium,
                                        fontWeight: fontSemibold,
                                        color: colorBlack)),
                                TextSpan(
                                    text: '*',
                                    style: TextStyle(
                                        color: c_red,
                                        fontSize: textSizeSMedium)),
                              ]),
                            ),
                            SizedBox(
                              height: 12,
                            ),
                            Container(
                              width: width1,
                              height: 45,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: colorBlack),
                                color: c_White,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 20, top: 13, bottom: 13),
                                child: TextFormField(
                                    controller: pwcontroller,
                                    obscureText: _showPassword1,
                                    keyboardType: TextInputType.visiblePassword,
                                    textAlignVertical: TextAlignVertical.center,
                                    textAlign: TextAlign.left,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.all(10.0),
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
                                      hintStyle: TextStyle(
                                          fontSize: textSizeSmallMedium,
                                          color: hint_text_color),
                                      hintText: "password",
                                      // border: InputBorder.none,
                                      // fillColor: c_White,
                                      // hintStyle: TextStyle(
                                      //     fontSize: textSizeSmall,
                                      //     color: hint_text_color),
                                      // hintText: "Password",
                                    )),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            InkWell(
                              onTap: () {
                                if (emailcontroller.text.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    backgroundColor: c_red,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text('Please fill EMail'),
                                  ));
                                } else if (pwcontroller.text.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    backgroundColor: c_red,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text('Please fill password'),
                                  ));
                                } else if (emailcontroller.text.isNotEmpty &&
                                    pwcontroller.text.isNotEmpty) {
                                  // Get.toNamed(Routes.homescreen);
                                  loginController.callAPI(
                                      emailcontroller.text, pwcontroller.text,
                                      Bcontext: context);
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    backgroundColor: c_red,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                        'Please fill details and try again'),
                                  ));
                                }
                                // Get.toNamed(Routes.homescreen);
                              },
                              child: Container(
                                width: getWidth(context),
                                height: 45,
                                color: container_borderBlueColor,
                                child: Center(
                                    child: Text(
                                  "Log in",
                                  style: TextStyle(
                                      color: c_White,
                                      fontSize: textSizeSmallMedium),
                                )),
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    fontSize: textSizeSMedium,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Get.toNamed(Routes.signUpScreen);
                                  },
                                  child: Container(
                                    width: 60,
                                    child: Text(
                                      " Sign Up",
                                      style: TextStyle(
                                          fontSize: textSizeSMedium,
                                          decoration: TextDecoration.underline,
                                          color: text_blueColor),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            InkWell(
                              onTap: () {
                                Get.toNamed(Routes.resetpassword);
                              },
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                      fontSize: textSizeSMedium,
                                      decoration: TextDecoration.underline,
                                      color: text_blueColor),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            // Align(
                            //     alignment: Alignment.center,
                            //     child: Text(
                            //       "Also Log in with",
                            //       style: TextStyle(fontSize: textSizeSMedium),
                            //     )),
                            // SizedBox(
                            //   height: 20,
                            // ),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children: [
                            //     CircleAvatar(
                            //       radius: 10,
                            //       backgroundColor: c_White,
                            //       child: Image.asset(localimages
                            //           .img_google_logos), //SvgPicture.asset(img_google_logo),
                            //     ),
                            //     SizedBox(
                            //       width: 10,
                            //     ),
                            //     CircleAvatar(
                            //       radius: 20,
                            //       backgroundColor: c_White,
                            //       child: Icon(
                            //         Icons.facebook,
                            //         color: button_blueColor,
                            //         size: 32,
                            //       ),
                            //     )
                            //   ],
                            // ),
                            // SizedBox(
                            //   height: 30,
                            // ),
                            // Container(
                            //   width: getWidth(context),
                            //   height: 20,
                            //   child: Row(
                            //     children: [
                            //       Expanded(
                            //         flex: 1,
                            //         child: Center(
                            //           child: InkWell(
                            //             onTap: () {
                            //               print('termsAndCondition');
                            //             },
                            //             child: Text(
                            //               "Terms",
                            //               style: TextStyle(
                            //                   fontSize: textSizeSmallMedium,
                            //                   fontWeight: fontSemibold),
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //       Expanded(
                            //         flex: 1,
                            //         child: Center(
                            //           child: Text(
                            //             "|",
                            //             style: TextStyle(
                            //                 fontSize: textSizeSmallMedium,
                            //                 fontWeight: fontSemibold,
                            //                 color: colorBlack),
                            //           ),
                            //         ),
                            //       ),
                            //       Center(
                            //         child: InkWell(
                            //           onTap: () {
                            //             print('privacyPolicy');
                            //           },
                            //           child: Text(
                            //             "Privacy policy",
                            //             style: TextStyle(
                            //                 fontSize: textSizeSmallMedium,
                            //                 fontWeight: fontSemibold),
                            //           ),
                            //         ),
                            //       ),
                            //       Expanded(
                            //         flex: 1,
                            //         child: Center(
                            //           child: Text(
                            //             "|",
                            //             style: TextStyle(
                            //                 fontSize: textSizeSmallMedium,
                            //                 fontWeight: fontSemibold,
                            //                 color: colorBlack),
                            //           ),
                            //         ),
                            //       ),
                            //       Expanded(
                            //         flex: 1,
                            //         child: Center(
                            //           child: InkWell(
                            //             onTap: () {},
                            //             child: Text(
                            //               "Support",
                            //               style: TextStyle(
                            //                   fontSize: textSizeSmallMedium,
                            //                   fontWeight: fontSemibold),
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            : Container(
                width: getWidth(context),
                height: getHeight(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Stack(
                        children: [
                          Container(
                            width: getWidth(context),
                            height: getHeight(context),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(localimages.blue_rose),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              //Get.toNamed(Routes.orderPage);
                              // Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //         builder: (_) => OrderCancelButton()));
                              // addressController.callAPI();
                              Get.toNamed(Routes.homePageView);
                            },
                            child: Container(
                              width: width1 / 5,
                              height: 30,
                              margin: EdgeInsets.only(top: 57, left: 30),
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                localimages.flutterWallpaper,
                                scale: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: getWidth(context),
                        height: getHeight(context),
                        padding: EdgeInsets.only(
                            left: 80, top: 30, right: 155, bottom: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 86,
                              ),
                            ),
                            Text(
                              "Log in",
                              style: TextStyle(
                                  fontSize: textSizeXXXLarge,
                                  fontWeight: fontBold),
                            ),
                            // Expanded(
                            //   flex: 1,
                            //   child: SizedBox(
                            //     height: 86,
                            //   ),
                            // ),
                            // InkWell(
                            //   onTap: () {},
                            //   child: Container(
                            //     width: getWidth(context),
                            //     height: 45,
                            //     color: c_White,
                            //     child: Row(
                            //       mainAxisAlignment: MainAxisAlignment.center,
                            //       crossAxisAlignment: CrossAxisAlignment.center,
                            //       children: [
                            //         Container(
                            //           width: 25,
                            //           height: 45,
                            //           child: Image.asset(
                            //               localimages.img_google_logos),
                            //
                            //           // SvgPicture.asset(
                            //           //   img_google_logo,
                            //           //   fit: BoxFit.contain,
                            //           // ),
                            //         ),
                            //         SizedBox(
                            //           width: 10,
                            //         ),
                            //         Text(
                            //           "Use Google Account",
                            //           style:
                            //               TextStyle(fontSize: textSizeSMedium),
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            // SizedBox(
                            //   height: 10,
                            // ),
                            // Row(
                            //   children: [
                            //     Expanded(
                            //       flex: 1,
                            //       child: Container(
                            //         width: getWidth(context),
                            //         height: 1,
                            //         color: colorBlack,
                            //       ),
                            //     ),
                            //     Padding(
                            //       padding: const EdgeInsets.only(
                            //           left: 10, right: 10),
                            //       child: Text(
                            //         "Or",
                            //         style: TextStyle(
                            //             fontSize: textSizeSmallMedium),
                            //       ),
                            //     ),
                            //     Expanded(
                            //       flex: 1,
                            //       child: Container(
                            //         width: getWidth(context),
                            //         height: 1,
                            //         color: colorBlack,
                            //       ),
                            //     )
                            //   ],
                            // ),
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 86,
                              ),
                            ),
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                    text: 'Email address',
                                    style: TextStyle(
                                        fontSize: textSizeSMedium,
                                        fontWeight: fontSemibold,
                                        color: colorBlack)),
                                TextSpan(
                                    text: '*',
                                    style: TextStyle(
                                        color: c_red,
                                        fontSize: textSizeSMedium)),
                              ]),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Container(
                              width: width1,
                              height: 45,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: colorBlack),
                                color: c_White,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 30, top: 15, bottom: 14),
                                child: TextFormField(
                                    controller: emailcontroller,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      fillColor: c_White,
                                      hintStyle: TextStyle(
                                          fontSize: textSizeSmallMedium,
                                          color: hint_text_color),
                                      hintText: "Email address",
                                    )),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 86,
                              ),
                            ),
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                    text: 'Password',
                                    style: TextStyle(
                                        fontSize: textSizeSMedium,
                                        fontWeight: fontSemibold,
                                        color: colorBlack)),
                                TextSpan(
                                    text: '*',
                                    style: TextStyle(
                                        color: c_red,
                                        fontSize: textSizeSMedium)),
                              ]),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Container(
                              width: width1,
                              height: 45,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: colorBlack),
                                color: c_White,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 30, top: 15, bottom: 14),
                                child: TextFormField(
                                    obscureText: _showPassword1,
                                    controller: pwcontroller,
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
                                      hintStyle: TextStyle(
                                          fontSize: textSizeSmallMedium,
                                          color: hint_text_color),
                                      hintText: "password",
                                    )),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 86,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (emailcontroller.text.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    backgroundColor: c_red,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text('Please fill EMail'),
                                  ));
                                } else if (pwcontroller.text.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    backgroundColor: c_red,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text('Please fill password'),
                                  ));
                                } else if (emailcontroller.text.isNotEmpty &&
                                    pwcontroller.text.isNotEmpty) {
                                  // Get.toNamed(Routes.homescreen);
                                  loginController.callAPI(
                                      emailcontroller.text, pwcontroller.text,
                                      Bcontext: context);
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    backgroundColor: c_red,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                        'Please fill details and try again'),
                                  ));
                                }
                              },
                              child: Container(
                                width: getWidth(context),
                                height: 45,
                                color: container_borderBlueColor,
                                child: Center(
                                    child: Text(
                                  "Log in",
                                  style: TextStyle(
                                      color: c_White,
                                      fontSize: textSizeSMedium),
                                )),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 86,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            "Don't have an account? ",
                                            style: TextStyle(
                                              fontSize: textSizeSMedium,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: InkWell(
                                          onTap: () {
                                            Get.toNamed(Routes.signUpScreen);
                                          },
                                          child: Container(
                                            width: 30,
                                            child: Text(
                                              "Sign Up",
                                              style: TextStyle(
                                                  fontSize: textSizeSMedium,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  color: text_blueColor),
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () {
                                      Get.toNamed(Routes.resetpassword);
                                    },
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                            fontSize: textSizeSMedium,
                                            decoration:
                                                TextDecoration.underline,
                                            color: text_blueColor),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 86,
                              ),
                            ),
                            // Align(
                            //     alignment: Alignment.center,
                            //     child: Text(
                            //       "Also Log in with",
                            //       style: TextStyle(fontSize: textSizeSMedium),
                            //     )),
                            // SizedBox(
                            //   height: 10,
                            // ),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children: [
                            //     CircleAvatar(
                            //       radius: 14,
                            //       backgroundColor: c_White,
                            //       child: Image.asset(localimages
                            //           .img_google_logos), //SvgPicture.asset(img_google_logo),
                            //     ),
                            //     SizedBox(
                            //       width: 10,
                            //     ),
                            //     CircleAvatar(
                            //       radius: 24,
                            //       backgroundColor: c_White,
                            //       child: Icon(
                            //         Icons.facebook,
                            //         color: button_blueColor,
                            //         size: 32,
                            //       ),
                            //     )
                            //   ],
                            // ),
                            // Expanded(
                            //   flex: 1,
                            //   child: SizedBox(
                            //     height: 86,
                            //   ),
                            // ),
                            // Expanded(
                            //   flex: 1,
                            //   child: SizedBox(
                            //     height: 86,
                            //   ),
                            // ),
                            // Container(
                            //   width: getWidth(context),
                            //   height: 20,
                            //   child: Row(
                            //     children: [
                            //       Expanded(
                            //         flex: 1,
                            //         child: Center(
                            //           child: InkWell(
                            //             onTap: () {
                            //               print('termsAndCondition');
                            //               // print('termsAndCondition');
                            //             },
                            //             child: Text(
                            //               "Terms",
                            //               style: TextStyle(
                            //                   fontSize: textSizeSMedium,
                            //                   fontWeight: fontSemibold),
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //       Expanded(
                            //         flex: 1,
                            //         child: Center(
                            //           child: Text(
                            //             "|",
                            //             style: TextStyle(
                            //                 fontSize: textSizeSMedium,
                            //                 fontWeight: fontSemibold,
                            //                 color: colorBlack),
                            //           ),
                            //         ),
                            //       ),
                            //       Expanded(
                            //         flex: 1,
                            //         child: Center(
                            //           child: InkWell(
                            //             onTap: () {
                            //               print('privacyPolicy');
                            //               // print('privacyPolicy');
                            //             },
                            //             child: Text(
                            //               "Privacy policy",
                            //               style: TextStyle(
                            //                   fontSize: textSizeSMedium,
                            //                   fontWeight: fontSemibold),
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //       Expanded(
                            //         flex: 1,
                            //         child: Center(
                            //           child: Text(
                            //             "|",
                            //             style: TextStyle(
                            //                 fontSize: textSizeSMedium,
                            //                 fontWeight: fontSemibold,
                            //                 color: colorBlack),
                            //           ),
                            //         ),
                            //       ),
                            //       Expanded(
                            //         flex: 1,
                            //         child: Center(
                            //           child: InkWell(
                            //             onTap: () {},
                            //             child: Text(
                            //               "Support",
                            //               style: TextStyle(
                            //                   fontSize: textSizeSMedium,
                            //                   fontWeight: fontSemibold),
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
