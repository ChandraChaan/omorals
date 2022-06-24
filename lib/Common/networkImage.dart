import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NetimageWidget extends StatelessWidget {
  final String img;
  final BoxFit Fit;

  NetimageWidget({required this.img, required this.Fit});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildNetworkImage(img, fit: Fit),
    );
  }

  Widget _buildNetworkImage(String url, {required BoxFit fit}) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) => Container(
        margin: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Container(
          height: 16.0,
          width: 16.0,
          alignment: Alignment.center,
          child: const CupertinoActivityIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Image.asset(
        'assets/images/splashScreen_flutter.jpg',
        fit: BoxFit.fill,
      ),
    );
  }
}