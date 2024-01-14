import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_chat/components/constants.dart';

class ReusableButton extends StatelessWidget {
  const ReusableButton(
      {super.key,
      required this.onPress,
      required this.color,
      required this.label});

  final String label;
  final Color color;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: TextButton(
        onPressed: onPress,
        child: Text(
          label,
          style: TextStyle(fontSize: 23.sp, color: kWhiteColor),
        ),
      ),
    );
  }
}

class TextFormFieldWidgets extends StatelessWidget {
  const TextFormFieldWidgets({
    super.key,
    required this.label,
    required this.onChange,
    this.isObscureText = false,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final Function(String)? onChange;
  final bool isObscureText;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: isObscureText,
      keyboardType: keyboardType,
      onChanged: onChange,
      cursorColor: kWhiteColor,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: kOrangeColor, fontSize: 12.sp),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: kOrangeColor, width: 2.0),
        ),
      ),
      style: TextStyle(color: kWhiteColor, fontSize: 15.sp),
    );
  }
}
