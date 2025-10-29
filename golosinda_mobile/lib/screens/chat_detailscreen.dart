import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:golosinda_advmobprog/widgets/custom_text.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  late Future<String> _currentUserIdFuture;
  bool _isSending = false;
  Timestamp? _sendingStartedAt;
  static const _postSendDelay = Duration(milliseconds: 600);

  // Messenger blue
  static const Color _outgoingBlue = Color(0xFF0084FF);

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    final userData = await userService.value.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });
    _sendingStartedAt = Timestamp.now();

    try {
      await chatService.sendMessage(receiverId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }

      await Future.delayed(_postSendDelay);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingStartedAt = null;
        });
      }
    }
  }

  PreferredSizeWidget _buildAppBar(String tappedUserName, String tappedEmail) {
    final avatarLetter = (tappedUserName.isNotEmpty)
        ? tappedUserName[0].toUpperCase()
        : (tappedEmail.isNotEmpty ? tappedEmail[0].toUpperCase() : 'U');

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: Colors.grey.shade200,
            child: CustomText(
              text: avatarLetter,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: tappedUserName.isNotEmpty ? tappedUserName : 'Unknown',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 2.h),
                CustomText(
                  text: tappedEmail,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required bool isMe,
    required String text,
    required bool isDelivered,
    required bool isSeen,
  }) {
    final bubbleColor = isMe ? _outgoingBlue : Colors.white;
    final textColor = isMe ? Colors.white : Colors.black87;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: text,
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
            color: textColor,
          ),
          if (isMe) ...[
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSeen
                      ? Icons
                            .done_all // Seen → double check
                      : isDelivered
                      ? Icons
                            .done_all // Delivered → double check (different color)
                      : Icons.done, // Sent → single check
                  size: 14,
                  color: isSeen
                      ? Colors.lightBlueAccent
                      : isDelivered
                      ? Colors.white70
                      : Colors.white70,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName =
        (widget.tappedUser['displayName'] ??
                widget.tappedUser['firstName'] ??
                '')
            .toString();
    final tappedUserEmail = (widget.tappedUser['email'] ?? '').toString();

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: _buildAppBar(tappedUserName, tappedUserEmail),
          backgroundColor: const Color(0xFFF6F7FB), // BG color
          body: Column(
            children: [
              // Message
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                        ),
                      );
                    }

                    List<QueryDocumentSnapshot> docs =
                        snapshot.data?.docs ?? [];

                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final senderId = (data['senderId'] ?? '').toString();
                      final isSeen = (data['isSeen'] ?? false) as bool;

                      if (senderId != currentUserId && !isSeen) {
                        doc.reference.update({'isSeen': true});
                      }
                    }

                    if (_isSending && _sendingStartedAt != null) {
                      docs = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final senderId = (data['senderId'] ?? '').toString();
                        final ts = data['timestamp'];

                        if (senderId != currentUserId) return true;

                        if (ts is Timestamp) {
                          return ts.compareTo(_sendingStartedAt!) < 0;
                        }
                        return true;
                      }).toList();
                    }

                    if (docs.isEmpty) {
                      return Center(
                        child: CustomText(
                          text: 'No messages yet',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final msgText = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;

                        final isDelivered =
                            (data['isDelivered'] ?? false) as bool;
                        final isSeen = (data['isSeen'] ?? false) as bool;

                        if (!isMe && !isDelivered) {
                          docs[index].reference.update({'isDelivered': true});
                        }

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: _buildMessageBubble(
                            isMe: isMe,
                            text: msgText,
                            isDelivered: isDelivered,
                            isSeen: isSeen,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // chat na
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 12.w,
                    right: 12.w,
                    bottom: 10.h,
                    top: 8.h,
                  ),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _msgCtrl,
                                  focusNode: _msgFocus,
                                  enabled: !_isSending,
                                  textInputAction: TextInputAction.send,
                                  minLines: 1,
                                  maxLines: 4,
                                  onSubmitted: (_) => !_isSending
                                      ? _send(currentUserId, tappedUserId)
                                      : null,
                                  decoration: InputDecoration(
                                    hintText: 'Type a message...',
                                    hintStyle: TextStyle(fontSize: 14.sp),
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: _isSending
                                    ? null
                                    : () => _send(currentUserId, tappedUserId),
                                child: CircleAvatar(
                                  radius: 20.r,
                                  backgroundColor: _isSending
                                      ? Colors.grey
                                      : _outgoingBlue,
                                  child: _isSending
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
