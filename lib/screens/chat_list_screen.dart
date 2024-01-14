// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_chat/components/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_chat/screens/message_screen.dart';
import 'package:firebase_chat/screens/group_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  static const String id = 'chat_list_screen';

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late String loggedInUser = '';
  late List<String> userList = [];
  int usersIndex = -1;
  bool userOpened = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final user = await fetchCurrentUser();
      final users = await fetchUsers(user);

      setState(() {
        loggedInUser = user['username'];
        userList = users;
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        throw Exception('User data not found');
      }
    }
    if (kDebugMode) {
      print('user is $user');
    }
    throw Exception('User not found');
  }

  Future<List<String>> fetchUsers(Map<String, dynamic> currentUser) async {
    final usersSnapshot = await _firestore.collection('users').get();
    final users = usersSnapshot.docs
        .map((doc) => doc['username'] as String)
        .where((username) => username != currentUser['username'])
        .toList();
    return users.cast<String>();
  }

  String generateChatId(String userId1, String userId2) {
    final capitalizedUserId1 = userId1.substring(0, 1).toUpperCase() +
        userId1.substring(1).toLowerCase();
    final capitalizedUserId2 = userId2.substring(0, 1).toUpperCase() +
        userId2.substring(1).toLowerCase();

    if (capitalizedUserId1.compareTo(capitalizedUserId2) > 0) {
      return '$capitalizedUserId1$capitalizedUserId2';
    } else {
      return '$capitalizedUserId2$capitalizedUserId1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(
          Icons.search,
          size: 23.sp,
          color: kWhiteColor,
        ),
        title: Text(
          'Chats',
          style: kTextStyle3,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, size: 23.sp, color: kWhiteColor),
            onPressed: () {
              _auth.signOut();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                userOpened = !userOpened;
              });
              Future.delayed(const Duration(milliseconds: 500), () {
                setState(() {
                  userOpened = !userOpened;
                });
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const GroupScreen(participantsUserName: ''),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.all(15.r),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color:
                    userOpened ? kOrangeColor.withOpacity(1) : kBlueColor,
              ),
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: Text(
                  'Users Group Chat',
                  style: TextStyle(color: kWhiteColor, fontSize: 20.sp),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? _buildLoadingIndicator() // Show loading indicator if data is loading
                : loggedInUser == null
                    ? _buildErrorWidget()
                    : ListView.builder(
                        itemCount: userList.length,
                        itemBuilder: (context, index) {
                          final userName = userList[index];
                          final capitalizedUsername =
                              userName.substring(0, 1).toUpperCase() +
                                  userName.substring(1).toLowerCase();

                          return GestureDetector(
                            onTap: () async {
                              setState(() {
                                usersIndex = index;
                              });
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                setState(() {
                                  usersIndex = -1;
                                });
                              });
                              String chatId = generateChatId(
                                  loggedInUser, capitalizedUsername);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MessageScreen(
                                    receiverUserName: capitalizedUsername,
                                    generateChatId: chatId,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(top: 15.r),
                              child: ListTile(
                                tileColor: usersIndex == index
                                    ? Colors.grey.withOpacity(0.2)
                                    : null,
                                leading: Container(
                                  width: 40.w,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kBlueColor,
                                  ),
                                  child: Center(
                                    child: Text(
                                      userList[index][0].toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 20.sp, color: kOrangeColor),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  capitalizedUsername,
                                  style: TextStyle(
                                      fontSize: 20.sp, color: kBlueColor),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return const Center(
      child: Text('Error fetching data. Please try again.'),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
