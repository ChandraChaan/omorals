import 'package:flutter/material.dart';

class themeButton extends StatelessWidget {
  final String name;
  final Color nameColor;
  final bool roundedBorder;
  final Color borderColor;
  final bool fillColor;
  final bool reverseColor;
  void Function() onClick;

  themeButton(
      {required this.name,
      required this.onClick,
      this.roundedBorder = false,
      this.reverseColor = false,
      this.fillColor = true,
      required this.nameColor,
      required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        decoration: BoxDecoration(
            gradient: fillColor == true
                ? LinearGradient(
                    begin: reverseColor == true
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    end: reverseColor == true
                        ? Alignment.topLeft
                        : Alignment.topRight,
                    colors: [Color(0xFF3E214B), Color(0xFF06E3A8)])
                : null,
            // color: fillColor == true ? Colors.teal[700] : null,
            border: borderColor == null
                ? null
                : Border.all(
                    color: borderColor,
                  ),
            borderRadius: roundedBorder == true
                ? BorderRadius.all(Radius.circular(25))
                : BorderRadius.all(Radius.circular(12))),
        height: 60,
        width: MediaQuery.of(context).size.width,
        child: Center(
            child: Text(
          '${name}',
          style: TextStyle(
              fontSize: 22,
              color: nameColor == null ? Colors.white : nameColor),
        )),
      ),
    );
  }
}
