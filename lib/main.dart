import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/message_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/group_screen.dart';
import 'components/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (BuildContext context, Widget? widget) {
        return MaterialApp(
          theme: ThemeData(
            appBarTheme: AppBarTheme(
              toolbarHeight: 60.h,
              centerTitle: true,
              backgroundColor: kBlueColor,
            ),
          ),
          debugShowCheckedModeBanner: false,
          initialRoute: WelcomeScreen.id,
          routes: {
            WelcomeScreen.id: (context) => const WelcomeScreen(),
            LoginScreen.id: (context) => const LoginScreen(),
            RegisterScreen.id: (context) => const RegisterScreen(),
            MessageScreen.id: (context) =>
                const MessageScreen(receiverUserName: '', generateChatId: ''),
            ChatListScreen.id: (context) => const ChatListScreen(),
            GroupScreen.id: (context) =>
                const GroupScreen(participantsUserName: ''),
          },
        );
      },
    );
  }
}
