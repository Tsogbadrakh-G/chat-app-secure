import 'package:chat_app_secure/controller/socket_signal_client.dart';
import 'package:chat_app_secure/controller/user_controller.dart';
import 'package:chat_app_secure/widgets/channel_appbar.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChannelScreen extends ConsumerStatefulWidget {
  final String thisChannelUsername;
  final String? imageUrl;
  final String chatRoomId;
  final String? message;

  const ChannelScreen({
    super.key,
    required this.thisChannelUsername,
    required this.chatRoomId,
    this.imageUrl,
    this.message,
  });

  @override
  ConsumerState<ChannelScreen> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChannelScreen> {
  TextEditingController messagecontroller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    isUserInChatPage = true;
    if (widget.message != null) {
      ref.read(userController.notifier).addMessage(
            widget.chatRoomId,
            Message(message: widget.message!, senderName: widget.thisChannelUsername),
          );
    }
    ref.read(socketClientProvider).joinChannel(widget.chatRoomId);
    if (ref.read(userController.notifier).messages[widget.chatRoomId] == null) {
      ref.read(userController.notifier).messages.putIfAbsent(widget.chatRoomId, () => ValueNotifier([]));
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: ref.read(userController.notifier).fetchThisUserFCM(widget.chatRoomId),
        builder: (context, snapshot) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          return Scaffold(
            appBar: ChannelAppBar(thisChannelUsername: widget.thisChannelUsername),
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                ValueListenableBuilder<List<Message>>(
                    valueListenable: ref.read(userController.notifier).messages[widget.chatRoomId]!,
                    builder: (a, b, c) {
                      return SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: (ref.read(userController.notifier).messages[widget.chatRoomId]?.value ?? []).length,
                            itemBuilder: (context, index) => ChatItem(
                                  message: ref.read(userController.notifier).getMessage(widget.chatRoomId, index).message,
                                  sendByMe: ref.read(userController.notifier).getMessage(widget.chatRoomId, index).senderName ==
                                      ref.read(userController).myUserName,
                                )),
                      );
                    }),
                Container(
                  margin: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                  alignment: Alignment.bottomCenter,
                  child: Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                      child: TextField(
                        controller: messagecontroller,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Type a message",
                            hintStyle: const TextStyle(color: Colors.black45),
                            suffixIcon: GestureDetector(
                                onTap: () {
                                  ref.read(socketClientProvider).sendMessage({
                                    "type": "message",
                                    "roomId": widget.chatRoomId,
                                    "content": messagecontroller.text,
                                    "sender_name": ref.read(userController).myUserName,
                                    "fcm": snapshot.data ?? ""
                                  });

                                  messagecontroller.clear();
                                },
                                child: const Icon(Icons.send_rounded))),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  @override
  void deactivate() {
    ref.read(socketClientProvider).leaveChannel(widget.chatRoomId);
    super.deactivate();
  }

  @override
  void dispose() {
    isUserInChatPage = false;
    super.dispose();
  }
}
