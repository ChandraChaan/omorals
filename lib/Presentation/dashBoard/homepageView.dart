import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:omorals/Config/app_pages.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import '../editorPage/editorPage.dart';

class HomePageView extends StatefulWidget {
  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  List<dynamic> videosList = [];
  List<dynamic> filteredVideosList = [];
  String Wmsg = 'Fetching videos...';
  bool isLoading = true;

  Future<void> fetchVideos() async {
    try {
      var url = Uri.parse(
          'https://www.googleapis.com/youtube/v3/search?order=date&part=snippet&channelId=UCdBiq4YsDqFGBrX1s1JCc4w&maxResults=100&key=REMOVED_API_KEY');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          videosList = data['items']
              .where((item) => item['id']['kind'] == 'youtube#video')
              .toList();
          filteredVideosList = videosList;
          Wmsg = videosList.isEmpty ? 'No videos available at the moment.' : '';
        });
      } else if (response.statusCode == 403) {
        setState(() {
          Wmsg = 'Unable to fetch videos. Please contact Chandra.';
        });
      } else {
        setState(() {
          Wmsg = 'An error occurred. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        Wmsg = 'An error occurred. Please check your connection.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  void filterVideos(String query) {
    setState(() {
      filteredVideosList = videosList
          .where((video) =>
          video['snippet']['title'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: TextField(
            decoration: const InputDecoration(
              hintText: 'Search videos...',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.black),
            ),
            onChanged: filterVideos,
          ),
        ),
        drawer: _buildDrawer(),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredVideosList.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    Wmsg,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: const Color(0xff271a83)),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : _buildVideoList(),
            ),
          ],
        ),
      ),
    );
  }

  Drawer? _buildDrawer() {
    return GetStorage().read('userName') == null
        ? null
        : Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: ListView(
            children: <Widget>[
              if (GetStorage().read('role') == 'Author')
                _buildDrawerItem('Create Story', Routes.autherPage)
              else if (GetStorage().read('role') == 'Editor')
                _buildDrawerItem('Upload a Video', Routes.voicePage)
              else
                _buildDrawerItem('Upload Voice', Routes.voicePage),
              _buildDrawerItem('Upload Voice', Routes.voicePage),
              _buildDrawerItem('Logout', Routes.homePageView, logout: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, String route, {bool logout = false}) {
    return ListTile(
      onTap: () {
        if (logout) {
          GetStorage().erase();
          Navigator.pop(context);
          Get.toNamed(route);
        } else {
          Get.toNamed(route);
        }
      },
      title: Text(title),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: GetStorage().read('userName') == null
            ? _buildRoleSelectionButtons()
            : Text('Welcome ${GetStorage().read('userName')}'),
      ),
    );
  }

  Widget _buildRoleSelectionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildRoleButton('Author', Routes.autherPage),
        _buildRoleButton('Voice', Routes.voicePage),
        _buildRoleButton('Editor', const EditorPage()),
      ],
    );
  }

  Widget _buildRoleButton(String role, dynamic route) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: const Color(0xff271a83),
        backgroundColor: const Color(0xff9ef9fe),
      ),
      onPressed: () {
        if (route is String) {
          Get.toNamed(route);
        } else {
          Get.to(route);
        }
      },
      child: Text(role),
    );
  }

  Widget _buildVideoList() {
    return ListView.builder(
      itemCount: filteredVideosList.length,
      itemBuilder: (BuildContext context, int index) {
        var video = filteredVideosList[index];
        var title = video['snippet']['title'];
        var thumbnailUrl = video['snippet']['thumbnails']['high']['url'];
        var videoUrl = "https://www.youtube.com/watch?v=${video['id']['videoId']}";

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: const Color(0xff271a83)),
                  ),
                  subtitle: Text('Published on ${video['snippet']['publishedAt']}'),
                ),
                InkWell(
                  onTap: () async {
                    await launchUrl(
                      Uri.parse(videoUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(thumbnailUrl),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}