import 'package:flutter/material.dart';
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

          ],
        ),
      ),
    );
  }
}
