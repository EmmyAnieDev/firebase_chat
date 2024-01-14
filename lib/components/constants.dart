import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const kBlueColor = Color(0xFF0071CE);
const kOrangeColor = Colors.orange;
const kWhiteColor = Colors.white;

final kTextStyle1 = TextStyle(
  fontSize: 15.sp,
  color: kOrangeColor,
);

final kTextStyle2 = TextStyle(
  fontSize: 35.sp,
  color: kWhiteColor,
  fontWeight: FontWeight.bold,
);

final kTextStyle3 = TextStyle(
  fontSize: 32.sp,
  color: kWhiteColor,
  fontWeight: FontWeight.w600,
);

final isMeStyle = TextStyle(
  color: Colors.black,
  fontSize: 15.sp,
);

final kTextStyle4 = TextStyle(color: kWhiteColor, fontSize: 25.sp);

final kDialogTextStyle = TextStyle(color: kWhiteColor, fontSize: 18.sp);

final kMessageTextFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
  hintText: 'Message...',
  hintStyle: TextStyle(fontSize: 14.sp),
  border: InputBorder.none,
);

final kMessageContainerDecoration = BoxDecoration(
  border: Border(
    top: BorderSide(color: kBlueColor, width: 2.w),
  ),
);
