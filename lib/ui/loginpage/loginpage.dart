// ignore_for_file: deprecated_member_use

import "package:flutter/material.dart";
import 'package:omorals/utils/utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextStyle textcolor = TextStyle(color: Colors.grey[300], fontSize: 25);
  TextStyle textcolor1 = const TextStyle(color: Colors.white, fontSize: 30);
  TextStyle textcolor2 = const TextStyle(color: Colors.white54, fontSize: 16);
  bool _showPassword1 = true;
  final pwcontroller = TextEditingController();
  final emailcontroller = TextEditingController();
  final forgotpeconteroller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: getHeight(context),
        width: getWidth(context),
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
                    decoration: const BoxDecoration(),
                  ),
                  Container(
                    width: getWidth(context),
                    height: getHeight(context),
                    color: const Color.fromARGB(255, 89, 4, 128),
                    margin: const EdgeInsets.only(),
                    alignment: Alignment.topLeft,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                width: getWidth(context),
                height: getHeight(context),
                padding: const EdgeInsets.only(
                    left: 80, top: 30, right: 155, bottom: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 86,
                      ),
                    ),
                    const Text(
                      "Log in",
                      style: TextStyle(
                          fontSize: textSizeXXXLarge, fontWeight: fontBold),
                    ),
                    const Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 86,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 86,
                      ),
                    ),
                    RichText(
                      text: const TextSpan(children: [
                        TextSpan(
                            text: 'Email ID',
                            style: TextStyle(
                                fontSize: textSizeSMedium,
                                fontWeight: fontSemibold,
                                color: Colors.black)),
                      ]),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      width: getWidth(context),
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
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              fillColor: Colors.white,
                              hintStyle: TextStyle(
                                fontSize: textSizeSMedium,
                                // color: hint_text_color
                              ),
                              hintText: "name@domain.com",
                            )),
                      ),
                    ),
                    const Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 86,
                      ),
                    ),
                    RichText(
                      text: const TextSpan(children: [
                        TextSpan(
                            text: 'Password',
                            style: TextStyle(
                                fontSize: textSizeSMedium,
                                fontWeight: fontSemibold,
                                color: Colors.black)),
                      ]),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      width: getWidth(context),
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
                            controller: pwcontroller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showPassword1 = !_showPassword1;
                                  });
                                },
                                child: Icon(
                                  _showPassword1
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                              border: InputBorder.none,
                              fillColor: Colors.white,
                              hintStyle: const TextStyle(
                                fontSize: textSizeSMedium,
                                // color: hint_text_color
                              ),
                              hintText: "..............",
                            )),
                      ),
                    ),
                    const Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 86,
                      ),
                    ),
                    InkWell(
                      onTap: () {},
                      child: Container(
                        width: getWidth(context),
                        height: 45,
                        color: Colors.blue,
                        child: const Center(
                            child: Text(
                          "Login",
                          style: TextStyle(
                              color: Colors.white, fontSize: textSizeSMedium),
                        )),
                      ),
                    ),
                    const Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 86,
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          TextButton(
                            child: const Text(
                              "Create New account",
                              style: TextStyle(
                                  fontSize: textSizeSMedium, color: Colors.blue),
                              maxLines: 1,
                            ),
                            onPressed: () {},
                          ),
                          TextButton(
                            child: const Text(
                              "Forgot password",
                              style: TextStyle(
                                  fontSize: textSizeSMedium, color: Colors.blue),
                              maxLines: 1,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 86,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 86,
                      ),
                    ),
                    const Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 86,
                      ),
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
                                onTap: () {},
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
                                    color: Colors.black12),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: InkWell(
                                onTap: () {},
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
                                    color: Colors.black12),
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
              ),
            )
          ],
        ),
      ),
    );
  }
}
