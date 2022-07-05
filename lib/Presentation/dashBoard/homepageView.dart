import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:omorals/Config/app_pages.dart';
import 'package:omorals/Presentation/dashBoard/slideShowView.dart';
import 'package:omorals/utils/constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class HomePageView extends StatefulWidget {
  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  List<dynamic> videosList = [];
  String Wmsg = '';

  Future<http.Response> postRequest() async {
    videosList.clear();
    var url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?order=date&part=snippet&channelId=UCdBiq4YsDqFGBrX1s1JCc4w&maxResults=100&key=AIzaSyBAw7J9C4imYEzJ8iWP4dtF6cFZ2ujArJ4');
    var response = await http.get(url);
    var dat = json.decode(response.body);
    print(response.statusCode);
    print(response.body);
    if (response.statusCode == 200) {
      for (int a = 0; a < dat['items'].length; a++) {
        if (dat['items'][a]['id']['kind'] != 'youtube#playlist')
          videosList.add(dat['items'][a]);
      }
      setState(() {});
    }
    if (response.statusCode == 403) {
      Wmsg = 'Unable fetch Videos, \nContact to Chandra';
    }
    return response;
  }

  @override
  void initState() {
    postRequest();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                child: GetStorage().read('userName') == null
                    ? Padding(
                        padding: EdgeInsets.only(
                            top: 12,
                            bottom: 12,
                            right: double.parse(
                                (MediaQuery.of(context).size.width / 5)
                                    .toString())),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                    const EdgeInsets.all(0)),
                                elevation: MaterialStateProperty.all(8),
                                // shape: MaterialStateProperty.all(
                                //     RoundedRectangleBorder(
                                //         borderRadius: BorderRadius.circular(50))),
                                backgroundColor: MaterialStateProperty.all(
                                    Color(0xff9ef9fe)),
                                shadowColor: MaterialStateProperty.all(
                                    Theme.of(context).colorScheme.onSurface),
                              ),
                              onPressed: () {
                                Get.toNamed(Routes.login);
                              },
                              child: Text(
                                'Sign in',
                                style: TextStyle(color: Color(0xff271a83)),
                              )),
                        ),
                      )
                    : Text('WellCome'),
              ),
            ),
            Expanded(
              flex: 9,
              child: videosList.length <= 0
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(58.0),
                        child: Text(
                          Wmsg,
                          style: Theme.of(context)
                              .textTheme
                              .headline2
                              ?.copyWith(color: Color(0xff271a83)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: videosList.length,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.all(58.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                videosList[index]['snippet']['title'],
                                style: Theme.of(context)
                                    .textTheme
                                    .headline4
                                    ?.copyWith(color: Color(0xff271a83)),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 300,
                                decoration: BoxDecoration(
                                    color: Color(0xff9ef9fe),
                                    border: Border.all(
                                      color: Color(0xff9ef9fe),
                                    ),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20))),
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: YoutubePlayerIFrame(
                                    controller: YoutubePlayerController(
                                      initialVideoId:
                                          '${videosList[index]['id']['videoId']}',
                                      params: const YoutubePlayerParams(
                                        autoPlay: false,
                                        strictRelatedVideos: true,
                                        showControls: true,
                                        showFullscreenButton: true,
                                      ),
                                    ),
                                    aspectRatio: 16 / 9,
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      }),
            ),
          ],
        ),
      ),
    );
  }

  Widget OldBuild(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 30,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Center(
                  child: GetStorage().read('userName') ??
                      TextButton(
                          onPressed: () {
                            Get.toNamed(Routes.login);
                          },
                          child: Text('Login')),
                )
              ]),
            ),
            SideOffer(),
            SizedBox(
              height: 50,
            ),
            Container(
              height: getHeight(context),
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                        height: MediaQuery.of(context).size.height / 2,
                        decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.red,
                            ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20))),
                        child: Center(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Title",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0, right: 8.0),
                              child: TextField(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter the Title',
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: MediaQuery.of(context).size.height / 5,
                                color: Colors.green,
                                child: const Center(
                                  child: Text("Video"),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "Description",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: TextField(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter the description',
                                ),
                              ),
                            )
                          ],
                        ))),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
