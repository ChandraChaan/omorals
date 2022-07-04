import 'package:flutter/material.dart';
import 'package:omorals/Utils/colors.dart';

class formText extends StatefulWidget {
  final String label;
  final bool readonlyye;
  final String normal;
  final String hint;
  final TextEditingController controllercc;

  formText(
      this.hint, this.label, this.controllercc, this.normal, this.readonlyye);

  @override
  _formTextState createState() => _formTextState();
}

class _formTextState extends State<formText> {
  TextStyle _labelStyle_l = TextStyle(color: Colors.black54);

  TextStyle _hintStyle_l = TextStyle(color: Colors.white);
  bool _showPassword1 = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: TextStyle(color: Colors.white),
      obscureText: widget.label == 'Password' ? _showPassword1 : false,
      readOnly: widget.readonlyye,
      controller: widget.controllercc,
      decoration: InputDecoration(
        suffixIcon: widget.label == 'Password'
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _showPassword1 = !_showPassword1;
                  });
                },
                child: Icon(
                  _showPassword1 ? Icons.visibility : Icons.visibility_off,
                ),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF00796B)),
        ),
        floatingLabelBehavior:
            widget.normal == 'n' ? null : FloatingLabelBehavior.always,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(7))),
        labelStyle: widget.normal == 'n' ? null : _labelStyle_l,
        hintStyle: widget.normal == 'n' ? null : _hintStyle_l,
        labelText: widget.normal == 'n' ? null : widget.label,
        hintText: widget.normal == 'n' ? null : widget.hint,
      ),
      autofocus: false,
    );
  }
}

class UiFormText extends StatefulWidget {
  final String label;
  final bool readonlyye;
  final bool normalFeild;
  final String? hint;
  final TextEditingController? controllercc;

  UiFormText(
      {required this.label,
      this.hint,
      this.controllercc,
      this.normalFeild = false,
      required this.readonlyye});

  @override
  _UiFormTextState createState() => _UiFormTextState();
}

class _UiFormTextState extends State<UiFormText> {
  TextStyle _labelStyle_l = TextStyle(color: Colors.black54);

  TextStyle _hintStyle_l = TextStyle(color: CentralizeColor.colorWhite);
  bool _showPassword1 = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      // cursorColor:Colors.white,
      style: TextStyle(color: Colors.white),
      obscureText: widget.label == 'Password' ? _showPassword1 : false,
      readOnly: widget.readonlyye,
      controller: widget.controllercc,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white30,
        suffixIcon: widget.label == 'Password'
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _showPassword1 = !_showPassword1;
                  });
                },
                child: Icon(
                    _showPassword1 ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: widget.label == 'r'
              ? BorderRadius.all(Radius.circular(33))
              : BorderRadius.all(Radius.circular(11)),
          borderSide: BorderSide(color: Colors.white30),
        ),
        floatingLabelBehavior:
            widget.normalFeild == true ? null : FloatingLabelBehavior.always,
        border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white30),
            borderRadius: widget.label == 'r'
                ? BorderRadius.all(Radius.circular(33))
                : BorderRadius.all(Radius.circular(11))),
        labelStyle: widget.normalFeild == true ? null : _labelStyle_l,
        hintStyle: _hintStyle_l,
        labelText: widget.normalFeild == true ? null : widget.label,
        hintText: widget.hint,
      ),
      autofocus: false,
    );
  }
}

class TextReuse extends StatelessWidget {
  final String hint;
  final IconData? icon;
  final TextEditingController? controller;

  const TextReuse({required this.hint, this.icon, this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: " $hint",
          prefixIcon: Icon(
            icon,
            color: Colors.white,
          ),
          hintStyle: TextStyle(color: Colors.white),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        controller: controller,
      ),
    );
  }
}
