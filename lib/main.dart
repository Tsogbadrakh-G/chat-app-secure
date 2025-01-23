import 'package:chat_app_secure/controller/user_controller.dart';
import 'package:chat_app_secure/firebase.dart';
import 'package:chat_app_secure/firebase_options.dart';
import 'package:chat_app_secure/views/welcome_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(firebaseUtils).init();
    return MaterialApp(
      navigatorKey: navigatorKey,
      onGenerateRoute: RouteGenerator.generateRoute,
      home: const WelcomeScreen(),
    );
  }
}
