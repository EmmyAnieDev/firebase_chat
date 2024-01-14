import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_chat/components/constants.dart';
import 'package:firebase_chat/components/reusable_widgets.dart';
import 'package:firebase_chat/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_chat/screens/chat_list_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const String id = 'register_screen';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool showSpinner = false;
  late String userName;
  late String email;
  late String password;
  late String confirmPassword;
  String errorMessage = '';
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool validateFields() {
    if (userName == null || userName.isEmpty) {
      setState(() {
        errorMessage = 'Please enter a username.';
      });
      return false;
    }
    return true;
  }

  Future<void> registerUser(
      String username, String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': username,
          'email': email,
        });


        Navigator.pushNamed(context, ChatListScreen.id);
      }
    } catch (e) {
      print('Error registering user: $e');
      // Handle registration failure
    }
  }

  void showErrorDialog(String message) {
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
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlueColor,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: SafeArea(
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
                          height: 100.h,
                          child: Image.asset('images/logo.png'),
                        ),
                      ),
                      TextFormFieldWidgets(
                        label: 'Username',
                        onChange: (value) {
                          userName = value;
                        },
                      ),
                      SizedBox(height: 15.sp),
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
                      SizedBox(height: 15.sp),
                      TextFormFieldWidgets(
                        isObscureText: true,
                        label: 'Confirm Password',
                        onChange: (value) {
                          confirmPassword = value;
                        },
                      ),
                      SizedBox(height: 20.sp),
                      ReusableButton(
                        label: 'Create Account',
                        color: Colors.orange,
                        onPress: () async {
                          setState(() {
                            showSpinner = true;
                          });
                          if (!validateFields()) {
                            setState(() {
                              showErrorDialog(errorMessage);
                              showSpinner = false;
                            });
                            return;
                          }
                          if (password != confirmPassword) {
                            setState(() {
                              errorMessage = 'Password do not match!';
                              showSpinner = false;
                            });
                            showErrorDialog(errorMessage);
                            return;
                          }
                          try {
                            await registerUser(userName, email, password);
                            setState(() {
                              showSpinner = false;
                            });
                          } catch (e) {
                            print('Error registering user: $e');
                            setState(() {
                              showSpinner = false;
                            });
                          }
                        },
                      ),
                      SizedBox(height: 18.sp),
                      Text('already have an account?', style: kTextStyle1),
                      SizedBox(height: 15.sp),
                      ReusableButton(
                        label: 'Login',
                        color: Colors.orange,
                        onPress: () {
                          Navigator.pushNamed(context, LoginScreen.id);
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
