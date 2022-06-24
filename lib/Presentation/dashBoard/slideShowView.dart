import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:omorals/Utils/constant.dart';

class SideOffer extends StatefulWidget {
  @override
  _SideOfferState createState() => _SideOfferState();
}

class _SideOfferState extends State<SideOffer> {

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  List<String> homeBannerList = [
    'assets/images/splashScreen_flutter.jpg'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
        width: getWidth(context),
        height: getHeight(context)/3,
        child: Stack(
          children: [
            ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: 2,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                      width: getWidth(context),
                      height: getHeight(context),
                      child:Container(color: Colors.white)
                  );
                }),
            Container(
              margin: EdgeInsets.only(top: 27, bottom: 27),
              child: CarouselSlider(
                options: CarouselOptions(
                  // aspectRatio: 16 / 9,
                  //  viewportFraction: 0.33,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: true,
                  autoPlayAnimationDuration:
                  Duration(milliseconds: 800),
                  autoPlayCurve: Curves.linear,
                  height: //239,
                  MediaQuery
                      .of(context)
                      .size
                      .height * 0.35,
                  autoPlay: true,
                  reverse: false,
                  autoPlayInterval: Duration(seconds: 4),
                  // pauseAutoPlayOnTouch: Duration(seconds: 10),
                  // autoPlayInterval:Duration(seconds: 1),
                ),
                items: [
                  for (int i = 0;
                  i <3;
                  i++)
                    'assets/images/splashScreen_flutter.jpg'
                        .toString(),
                ].map((i) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: //443,
                        MediaQuery
                            .of(context)
                            .size
                            .width,
                        margin: EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(color: Colors.white),
                        child: GestureDetector(
                          child: Image.network(i.toString(),
                              fit: BoxFit.fill),
                          onTap: () {
                            // Navigator.pushReplacement(
                            //   context,
                            //   MaterialPageRoute(
                            //       builder: (BuildContext context) => NewsPage()),
                            //   );
                          },
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        )
    );
  }
}
