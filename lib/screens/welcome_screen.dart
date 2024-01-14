import 'package:firebase_chat/screens/register_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:firebase_chat/components/constants.dart';
import 'package:firebase_chat/components/reusable_widgets.dart';
import 'package:firebase_chat/screens/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  static const String id = 'welcome_screen';
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _animation = Tween<Offset>(
      begin: const Offset(0, -2.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    Future.delayed(const Duration(milliseconds: 100), () {
      _controller.forward();
    });

    Future.delayed(const Duration(microseconds: 200), () {
      setState(() {
        _isVisible = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlueColor,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(30.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SlideTransition(
                position: _animation,
                child: Hero(
                  tag: 'logo',
                  child: SizedBox(
                    height: 250.h,
                    child: Image.asset('images/logo.png'),
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(seconds: 2),
                opacity: _isVisible ? 1.0 : 0.0,
                curve: Curves.easeIn,
                child: _isVisible
                    ? Text(
                        'Firebase Chat',
                        style: kTextStyle2,
                      )
                    : const SizedBox(),
              ),
              SizedBox(height: 18.sp),
              ReusableButton(
                label: 'Login',
                color: Colors.orange,
                onPress: () {
                  Navigator.pushNamed(context, LoginScreen.id);
                },
              ),
              SizedBox(height: 18.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      height: 0.5.h,
                      color: kOrangeColor,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.h),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 0.5.h,
                      color: kOrangeColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.sp),
              ReusableButton(
                label: 'Create Account',
                color: Colors.orange,
                onPress: () {
                  Navigator.pushNamed(context, RegisterScreen.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
