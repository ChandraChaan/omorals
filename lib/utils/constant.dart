import 'package:flutter/cupertino.dart';

import 'colors.dart';

double getHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

double getWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

final double BigHeading = 45.0;
final double NormalHeading = 30.0;
/*fonts*/
const fontRegular = 'Regular';
const fontMedium = 'Medium';
const fontSemibold = FontWeight.w500;
const fontBold = FontWeight.bold;
/* font sizes*/
const textSizeSmall = 10.0;
const textSizeSmallMedium = 12.0;
const textSizeSMedium = 14.0;
const textSize17 = 17.0;
const textSizeMedium = 16.0;
const textSizeLargeMedium = 18.0;
const textSizeNormal = 20.0;
const textSizeLarge = 24.0;
const textSizeXLarge = 28.0;
const textSizeXXLarge = 30.0;
const textSizeXXXLarge = 32.0;
const textSizeXXXExtraLarge = 36.0;
const widget_gap_height_40 = 40.0;
const widget_gap_height_30 = 30.0;
//const widget_gap_heig

TextStyle UInormalStyle =
    TextStyle(color: CentralizeColor.colorWhite, fontSize: 16, fontWeight: FontWeight.bold);
TextStyle UIHeadingStyle =
    TextStyle(color: CentralizeColor.colorWhite, fontSize: 24, fontWeight: FontWeight.bold);

Widget kHorizontalSpace({width: 10.0}) => SizedBox(width: width);
