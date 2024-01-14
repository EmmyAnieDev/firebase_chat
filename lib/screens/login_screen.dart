import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_chat/components/constants.dart';
import 'package:firebase_chat/components/reusable_widgets.dart';
import 'package:firebase_chat/screens/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:firebase_chat/screens/chat_list_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  bool showSpinner = false;
  late String userName;
  late String email;
  late String password;
  String errorMessage = '';
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void showInvalidEmailDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kBlueColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          contentPadding:
              EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
          content: Text(
            message,
            style: kDialogTextStyle,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: kDialogTextStyle,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlueColor,
      body: SafeArea(
        child: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(30.r),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Hero(
                        tag: 'logo',
                        child: SizedBox(
                          height: 200.h,
                          child: Image.asset('images/logo.png'),
                        ),
                      ),
                      TextFormFieldWidgets(
                        keyboardType: TextInputType.emailAddress,
                        label: 'Email',
                        onChange: (value) {
                          email = value;
                        },
                      ),
                      SizedBox(height: 15.sp),
                      TextFormFieldWidgets(
                        isObscureText: true,
                        label: 'Password',
                        onChange: (value) {
                          password = value;
                        },
                      ),
                      SizedBox(height: 20.sp),
                      ReusableButton(
                        label: 'Login',
                        color: Colors.orange,
                        onPress: () async {
                          setState(() {
                            showSpinner = true;
                          });

                          try {
                            final user = await _auth.signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            if (user != null) {
                              Navigator.pushNamed(context, ChatListScreen.id);
                            }
                            setState(() {
                              showSpinner = false;
                            });
                          } catch (e) {
                            setState(() {
                              errorMessage = 'Invalid email or password!';
                              showSpinner = false;
                            });
                            showInvalidEmailDialog(errorMessage);
                          }
                        },
                      ),
                      SizedBox(height: 18.sp),
                      Text('don\'t have an account?', style: kTextStyle1),
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
            ),
          ),
        ),
      ),
    );
  }
}
