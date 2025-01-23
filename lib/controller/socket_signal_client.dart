import 'dart:developer';

import 'package:chat_app_secure/constants.dart';
import 'package:chat_app_secure/controller/user_controller.dart';
import 'package:chat_app_secure/widgets/channel_appbar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';

class SocketSignalClient {
  Ref ref;
  SocketSignalClient(this.ref);
  static Socket socketSignal = IO.io(
      'http://$hostname:$port',
      OptionBuilder()
          .setTransports(['websocket'])
          .setReconnectionAttempts(4) // for Flutter or Dart VM
          .build());

  init() {
    socketSignal.onConnectError((e) => print('connection error: $e'));
    socketSignal.onConnect((_) => print('Connected'));
    socketSignal.onDisconnect((_) => print('Disconnected'));
    socketSignal.on('event', (data) => print(data));
    socketSignal.on('receive_message', (data) {
      ref.read(userController.notifier).addMessage(
            data['roomId'],
            Message(message: data["content"], senderName: data['sender_name']),
          );
    });
  }

  void joinChannel(String channel) {
    log('join channel : $channel');
    socketSignal.emit('join_channel', channel);
  }

  void leaveChannel(String channel) {
    socketSignal.emit('leave_channel', channel);
  }

  void sendMessage(Map<String, String> message) => socketSignal.emit('send_message', message);
}

final socketClientProvider = Provider((ref) {
  return SocketSignalClient(ref);
});
