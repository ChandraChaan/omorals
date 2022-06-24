import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Loader {
  static show({
    required BuildContext context,
  }) {
    AlertDialog alert = AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              height: 100.0,
              width: 100.0,
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              alignment: Alignment.center,
              child: CupertinoActivityIndicator(
                radius: 20,
              ))
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
