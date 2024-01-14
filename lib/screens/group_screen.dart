// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_chat/components/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

final _firestore = FirebaseFirestore.instance;
late User loggedInUser;

class GroupScreen extends StatefulWidget {
  static const String id = 'group_screen';
  final String participantsUserName;

  const GroupScreen({
    super.key,
    required this.participantsUserName,
  });

  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  late String messageText;
  late String currentUserId;
  late String participantsNames;
  late File imageFile;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          currentUserId = user.uid;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future getImage() async {
    ImagePicker picker = ImagePicker();

    await picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {
    String fileName = const Uuid().v1();

    var ref =
        FirebaseStorage.instance.ref().child('images').child('$fileName.jpg');

    try {
      var uploadTask = await ref.putFile(imageFile);
      var imageUrl = await uploadTask.ref.getDownloadURL();

      await _firestore.collection('group_chats').add({
        'type': 'img',
        'sender': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
    }
  }

  void sendMessage() {
    String messageText = messageTextController.text.trim();
    if (messageText.isNotEmpty) {
      _firestore.collection('group_chats').add({
        'type': 'text',
        'text': messageText,
        'sender': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      messageTextController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: kWhiteColor, size: 23.sp),
        title: Text(
          'Users Group Chat',
          style: kTextStyle4,
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: MessagesStream(
                  currentUserId: currentUserId,
                  participantsUserName: widget.participantsUserName,
                ),
              ),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: messageTextController,
                        onChanged: (value) {
                          messageText = value;
                        },
                        decoration: kMessageTextFieldDecoration,
                      ),
                    ),
                    IconButton(
                      onPressed: getImage,
                      icon: Icon(
                        Icons.photo,
                        color: kBlueColor,
                        size: 26.sp,
                      ),
                    ),
                    IconButton(
                      onPressed: sendMessage,
                      icon: Icon(
                        Icons.send,
                        color: kBlueColor,
                        size: 25.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesStream extends StatefulWidget {
  final String currentUserId;
  final String participantsUserName;

  const MessagesStream({
    super.key,
    required this.currentUserId,
    required this.participantsUserName,
  });

  @override
  _MessagesStreamState createState() => _MessagesStreamState();
}

class _MessagesStreamState extends State<MessagesStream> {
  late Map<String, String> participantsUserName;

  @override
  void initState() {
    super.initState();
    participantsUserName = {};
    messageSender();
  }

  //participant name that sent message
  void messageSender() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('users').get();

    for (var doc in snapshot.docs) {
      participantsUserName[doc.id] = doc['username'] ?? '';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore.collection('group_chats').orderBy('createdAt').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            participantsUserName.isEmpty) {
          return Container();
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No messages available',
              style: TextStyle(fontSize: 14.sp),
            ),
          );
        }

        final messages = snapshot.data!.docs;
        List<Widget> messageWidgets = [];

        for (var message in messages) {
          final data = message.data() as Map<String, dynamic>;
          final messageText = data['text'] as String? ?? '';
          final senderId = data['sender'] as String;
          final imageUrl = data['imageUrl'] as String?;
          final isMe = widget.currentUserId == senderId;

          messageWidgets.add(
            MessageBubble(
              key: ValueKey(message.id),
              text: messageText,
              isMe: isMe,
              imageUrl: imageUrl,
              participantsUserName: participantsUserName[senderId] ?? '',
            ),
          );
        }

        return ListView(
          reverse: true,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
          children: messageWidgets.reversed.toList(),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String participantsUserName;
  final String? imageUrl;
  @override
  final Key key;

  const MessageBubble({
    required this.key,
    required this.text,
    required this.isMe,
    required this.participantsUserName,
    this.imageUrl,
  }) : super(key: key);

  String capitalize(String input) {
    return input
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  void _showFullScreenImage(BuildContext context) {
    if (imageUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImage(
            isMe: isMe,
            imageUrl: imageUrl!,
            participantsUserName: participantsUserName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              _ImageLoadingWidget(
                isMe: isMe,
                imageUrl: imageUrl!,
                participantsUserName: participantsUserName,
              )
            else if (text.isNotEmpty)
              Material(
                elevation: 5.0,
                borderRadius: isMe
                    ? BorderRadius.only(
                        topLeft: Radius.circular(10.r),
                        topRight: Radius.circular(10.r),
                        bottomLeft: Radius.circular(10.r),
                      )
                    : BorderRadius.only(
                        topLeft: Radius.circular(10.r),
                        topRight: Radius.circular(10.r),
                        bottomRight: Radius.circular(10.r),
                      ),
                color: isMe ? kBlueColor : kOrangeColor,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
                  child: Text(
                    '${isMe ? '' : '~${capitalize(participantsUserName)}\n'}$text',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(StringProperty('ParticipantsUserName', participantsUserName));
    properties.add(DiagnosticsProperty<Key>('key', key));
  }
}

// class for Loading images
class _ImageLoadingWidget extends StatefulWidget {
  final String imageUrl;
  final bool isMe;
  final String participantsUserName;

  const _ImageLoadingWidget({
    required this.imageUrl,
    required this.isMe,
    required this.participantsUserName,
  });

  @override
  _ImageLoadingWidgetState createState() => _ImageLoadingWidgetState();
}

class _ImageLoadingWidgetState extends State<_ImageLoadingWidget> {
  late ImageStream _imageStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _imageStream.removeListener(ImageStreamListener(_updateImage));
    super.dispose();
  }

  void _loadImage() {
    final image = Image.network(
      widget.imageUrl,
      fit: BoxFit.cover,
    );
    final stream = image.image.resolve(const ImageConfiguration());
    _imageStream = stream;
    _imageStream.addListener(ImageStreamListener(_updateImage));
  }

  void _updateImage(ImageInfo info, bool synchronousCall) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String capitalize(String input) {
    return input
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      children: [
        Container(
          padding: EdgeInsets.all(5.r),
          decoration: BoxDecoration(
            borderRadius: widget.isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(10.r),
                    topRight: Radius.circular(10.r),
                    bottomLeft: Radius.circular(10.r),
                  )
                : BorderRadius.only(
                    topLeft: Radius.circular(10.r),
                    topRight: Radius.circular(10.r),
                    bottomRight: Radius.circular(10.r),
                  ),
            color: widget.isMe ? kBlueColor : kOrangeColor,
          ),
          child: AnimatedOpacity(
            opacity: _isLoading ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: SizedBox(
                width: 260.w,
                height: 150.h,
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        if (widget.participantsUserName.isNotEmpty && !_isLoading)
          Positioned(
            top: 10,
            left: 10,
            child: widget.isMe
                ? Container()
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.r),
                      color: kOrangeColor,
                    ),
                    padding: EdgeInsets.all(4.r),
                    child: Text(
                      widget.isMe
                          ? ''
                          : '~${capitalize(widget.participantsUserName)}',
                      style: TextStyle(
                        color: kBlueColor,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
          ),
        if (_isLoading)
          Container(
            width: 280.w,
            height: 180.h,
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: kBlueColor,
                strokeWidth: 3.w,
              ),
            ),
          ),
      ],
    );
  }
}

// Screen for full image when tap
class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String participantsUserName;
  final bool isMe;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    required this.participantsUserName,
    required this.isMe,
  });

  String capitalize(String input) {
    return input
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.6),
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              child: Text(
                isMe ? 'YOU' : capitalize(participantsUserName),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
