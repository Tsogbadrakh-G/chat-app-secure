// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:chat_app_secure/alerts/alert.dart';
import 'package:chat_app_secure/constants.dart';
import 'package:chat_app_secure/controller/user_controller.dart';
import 'package:chat_app_secure/firebase.dart';
import 'package:chat_app_secure/views/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:email_validator/email_validator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LogInScreen extends StatefulHookConsumerWidget {
  const LogInScreen({super.key});

  @override
  ConsumerState<LogInScreen> createState() => _LogInState();
}

class _LogInState extends ConsumerState<LogInScreen> {
  late ValueNotifier<String> email, password;
  TextEditingController usermailcontroller = TextEditingController();
  TextEditingController userpasswordcontroller = TextEditingController();
  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();

  bool _isEmptyMail = false;
  bool _isEmptyPass = false;

  bool isValidPass = false;
  final _formkey = GlobalKey<FormState>();
  ValueNotifier<bool> isLogging = ValueNotifier<bool>(false);

  validator() {
    if (usermailcontroller.text.isEmpty) {
      _isEmptyMail = true;
      setState(() {});
    } else {
      _isEmptyMail = false;
    }
    if (userpasswordcontroller.text.isEmpty) {
      _isEmptyPass = true;
      setState(() {});
    } else {
      _isEmptyPass = false;
    }

    if (_isEmptyMail && _isEmptyPass) {
      Alerts.showMyDialog(context, 'Please enter your email and password!');
    } else if (_isEmptyMail) {
      Alerts.showMyDialog(context, 'Please enter your email!');
    } else if (_isEmptyPass) {
      Alerts.showMyDialog(context, 'Please enter your password!');
    }
  }

  login() async {
    try {
      isLogging.value = true;
      email.value = email.value.toLowerCase();
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.value, password: password.value);

      int atIndex = email.value.indexOf('@');
      String username = email.value.substring(0, atIndex);

      ref.read(userController.notifier).saveUser(email.value, username);
      final rooms = await FirebaseFirestore.instance.collection("chatrooms").get();
      for (var room in rooms.docs) {
        log('room: ${room.id}');
        await FirebaseFirestore.instance.collection("chatrooms").doc(room.id).delete();
      }
      isLogging.value = false;
      Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));

      Map<String, dynamic> userInfoMap = {
        "Photo": AVATAR_URL,
        "email": ref.read(userController).email,
        'username': username,
      };
      final user = FirebaseAuth.instance.currentUser;
      String? ui = user?.uid;

      await ref.read(userController.notifier).saveUserInfoToCloud(userInfoMap, ui ?? '');
      ref.read(firebaseUtils).getUserToken();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Alerts.showMyDialog(context, 'There are no registered users you have entered!');
      } else if (e.code == 'wrong-password') {
        Alerts.showMyDialog(context, 'The password you entered is incorrect!');
      } else if (e.code == 'invalid-email') {
        Alerts.showMyDialog(context, 'The email address you entered is incorrect!');
      } else if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
        Alerts.showMyDialog(context, 'Please check that the password and email you entered are correct!');
      } else if (e.code == 'network-request-failed') {
        Alerts.showMyDialog(context, 'Make sure you are connected to the Internet!');
      }

      log('sign in exception: ${e.toString()}, code: ${e.code}');
    }
    isLogging.value = false;
  }

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> isValidEmail = useState(false);
    email = useState("");
    password = useState("");
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back)),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          if (focusNode1.hasFocus) {
            FocusScope.of(context).requestFocus(FocusNode());
          }
          if (focusNode2.hasFocus) {
            FocusScope.of(context).requestFocus(FocusNode());
          }
        },
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ic_splash.png',
                scale: 1.5,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: Form(
                  key: _formkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextFormField(
                          onChanged: (value) {
                            isValidEmail.value = EmailValidator.validate(value);
                          },
                          focusNode: focusNode1,
                          textAlignVertical: TextAlignVertical.center,
                          controller: usermailcontroller,
                          decoration: InputDecoration(
                            suffixIcon: isValidEmail.value
                                ? const Icon(
                                    Icons.check_circle_outline,
                                    color: Color(
                                      0xff48D68A,
                                    ),
                                    size: 23,
                                  )
                                : Image.asset(
                                    'assets/images/img_login_exclamation.png',
                                    scale: 1.9,
                                  ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(width: 1, color: Colors.black38),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                width: 1,
                                color: Color(0xff434347),
                              ),
                            ),
                            hintText: 'Email',
                            hintStyle: const TextStyle(color: Color(0xff434347), fontFamily: 'Nunito', fontWeight: FontWeight.normal, fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: TextFormField(
                          onChanged: (value) {},
                          focusNode: focusNode2,
                          textAlignVertical: TextAlignVertical.center,
                          controller: userpasswordcontroller,
                          decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(width: 1, color: Colors.black38),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                width: 1.5,
                                color: Color(0xff434347),
                              ),
                            ),
                            border: InputBorder.none,
                            hintText: 'Password',
                            hintStyle: TextStyle(color: Color(0xff434347), fontFamily: 'Nunito', fontWeight: FontWeight.normal, fontSize: 14),
                          ),
                          obscureText: true,
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Container(
                        width: double.infinity,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 35),
                        child: ElevatedButton(
                          onPressed: () {
                            validator();
                            if (!_isEmptyMail && !_isEmptyPass) {
                              if (_formkey.currentState!.validate()) {
                                email.value = usermailcontroller.text;
                                password.value = userpasswordcontroller.text;
                              }
                              login();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: const Color(0xff0057ff),
                          ),
                          child: ValueListenableBuilder(
                              valueListenable: isLogging,
                              builder: (context, val, b) {
                                if (val) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  );
                                }
                                return const Text(
                                  'Sign in',
                                  style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontWeight: FontWeight.normal, fontSize: 14),
                                );
                              }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
