// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'dart:core';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_chat/components/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';

final _firestore = FirebaseFirestore.instance;

class MessageScreen extends StatefulWidget {
  static const String id = 'message_screen';
  final String receiverUserName;
  final String generateChatId;

  const MessageScreen({
    super.key,
    required this.receiverUserName,
    required this.generateChatId,
  });

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  late String messageText;
  late String currentUserId;
  late File imageFile;
  late String generateChatId;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    generateChatId = widget.generateChatId;
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

      await _firestore
          .collection('single_messages')
          .doc(generateChatId)
          .collection('messages')
          .add({
        'type': 'img',
        'senderId': currentUserId,
        'receiverId': widget.receiverUserName,
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
      _firestore
          .collection('single_messages')
          .doc(generateChatId)
          .collection('messages')
          .add({
        'text': messageText,
        'type': 'text',
        'senderId': currentUserId,
        'receiverId': widget.receiverUserName,
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
          widget.receiverUserName,
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
                  receiverUserName: widget.receiverUserName,
                  generateChatId: generateChatId,
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

class MessagesStream extends StatelessWidget {
  final String currentUserId;
  final String receiverUserName;
  final String generateChatId;

  const MessagesStream({
    super.key,
    required this.currentUserId,
    required this.receiverUserName,
    required this.generateChatId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('single_messages')
          .doc(generateChatId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
          final isMe = currentUserId == data['senderId'];
          final imageUrl = data['imageUrl'] as String?;

          final messageWidget = MessageBubble(
            key: ValueKey(message.id),
            text: messageText,
            isMe: isMe,
            receiverUserName: receiverUserName,
            imageUrl: imageUrl,
          );

          messageWidgets.add(messageWidget);
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
  final String receiverUserName;
  final String? imageUrl;
  @override
  final Key key;

  const MessageBubble({
    required this.key,
    required this.text,
    required this.isMe,
    required this.receiverUserName,
    this.imageUrl,
  }) : super(key: key);

  void _showFullScreenImage(BuildContext context) {
    if (imageUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImage(
            imageUrl: imageUrl!,
            isMe: isMe,
            receiverUserName: receiverUserName,
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
        padding: EdgeInsets.all(10.r),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            if (imageUrl != null)
              _ImageLoadingWidget(isMe: isMe, imageUrl: imageUrl!)
            else if (text.isNotEmpty)
              Material(
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
                elevation: 5.0,
                color: isMe ? kBlueColor : kOrangeColor,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 5.h, horizontal: 15.w),
                  child: Text(
                    text,
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
    properties.add(DiagnosticsProperty<Key>('key', key));
    properties.add(DiagnosticsProperty<Key>('key', key));
  }
}

//class for Loading images
class _ImageLoadingWidget extends StatefulWidget {
  final String imageUrl;
  final bool isMe;

  const _ImageLoadingWidget({required this.imageUrl, required this.isMe});

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

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String receiverUserName;
  final bool isMe;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    required this.receiverUserName,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await saveImageToGallery(context, imageUrl);
                    },
                    child: Text(
                      'Save to Gallery',
                      style: TextStyle(fontSize: 17.sp, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.6),
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              child: Text(
                isMe ? 'YOU' : capitalize(receiverUserName),
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

  Future<void> saveImageToGallery(BuildContext context, String imageUrl) async {
    try {
      // Save the image to the gallery
      var response = await http.get(Uri.parse(imageUrl));
      Directory? externalStorageDirectory = await getExternalStorageDirectory();
      File file = File(
          path.join(externalStorageDirectory!.path, path.basename(imageUrl)));
      await file.writeAsBytes(response.bodyBytes);

      print('File saved to: ${file.path}');

      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Image saved successfully!'),
          content: GestureDetector(
            onTap: () {
              OpenFile.open(file.path);
            },
            child: Image.file(File(file.path)),
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving image to gallery: $e');
      }
    }
  }
}
