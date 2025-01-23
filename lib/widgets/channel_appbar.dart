import 'package:chat_app_secure/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChannelAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String thisChannelUsername;
  const ChannelAppBar({required this.thisChannelUsername, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      elevation: 0.5,
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      backgroundColor: Colors.white,
      flexibleSpace: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 70,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Image.asset('assets/images/ic_chevron_left.png', height: 20, width: 20, color: Colors.black),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(Radius.circular(30)),
                        border: Border.all(color: Colors.black.withOpacity(0.5))),
                    width: 60,
                    height: 60,
                    child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(30)),
                        child: Image.network(
                          AVATAR_URL,
                          fit: BoxFit.fill,
                        )),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    thisChannelUsername,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 10)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(72);
}

class ChatItem extends ConsumerWidget {
  final String message;
  final bool sendByMe;
  const ChatItem({required this.message, required this.sendByMe, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
            child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  bottomRight: sendByMe ? const Radius.circular(0) : const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: sendByMe ? const Radius.circular(24) : const Radius.circular(0)),
              color: sendByMe ? const Color.fromARGB(255, 234, 236, 240) : const Color.fromARGB(255, 211, 228, 243)),
          child: Text(
            message,
            style: const TextStyle(color: Colors.black, fontSize: 15.0, fontWeight: FontWeight.w500),
          ),
        )),
      ],
    );
  }
}

class Message {
  String message;
  String senderName;
  Message({required this.message, required this.senderName});
}
