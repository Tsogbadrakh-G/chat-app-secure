// ignore_for_file: must_be_immutable, use_build_context_synchronously
import 'package:chat_app_secure/constants.dart';
import 'package:chat_app_secure/controller/database_controller.dart';
import 'package:chat_app_secure/controller/socket_signal_client.dart';
import 'package:chat_app_secure/controller/user_controller.dart';
import 'package:chat_app_secure/views/channel_view.dart';
import 'package:chat_app_secure/widgets/chat_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulHookConsumerWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends ConsumerState<HomeScreen> {
  TextEditingController textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final tempSearchStore = StateProvider<List<Map<String, dynamic>>>((ref) => []);
  StateProvider<QuerySnapshot?> snapshot = StateProvider((ref) => null);
  final isFocused = StateProvider<bool>((ref) => false);

  @override
  void initState() {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        ref.read(isFocused.notifier).state = true;
      } else {
        ref.read(isFocused.notifier).state = false;
        ref.read(tempSearchStore.notifier).state = [];
      }
    });
    ref.read(socketClientProvider).init();
    super.initState();
  }

  initiateSearch(String value) {
    if (value.isEmpty) {
      ref.read(tempSearchStore.notifier).state = [];
      return;
    }
    DatabaseController.search(value.toLowerCase()).then((List<Map<String, dynamic>> usrs) {
      ref.read(tempSearchStore.notifier).state = usrs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomSnapshot = ref.watch(snapshot);
    ValueNotifier<bool> refresh = useState(false);
    useEffect(() {
      Future<void> fetch() async {
        ref.read(snapshot.notifier).state = await FirebaseFirestore.instance.collection("chatrooms").get();
      }

      fetch();
      return null;
    }, [refresh]);

    final users = ref.watch(tempSearchStore);
    final focused = ref.watch(isFocused);
    final onchange = useState(false);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: const SizedBox(),
          backgroundColor: Colors.white,
          title: const Text('Home Screen'),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.read(snapshot.notifier).state = await FirebaseFirestore.instance.collection("chatrooms").get();
            //setState(() {});
            refresh.value = !refresh.value;
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                elevation: 0,
                floating: true,
                titleSpacing: 0,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.white,
                title: Container(
                  height: 40,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: TextField(
                    cursorHeight: 25,
                    controller: textEditingController,
                    textAlignVertical: TextAlignVertical.center,
                    focusNode: _focusNode,
                    textAlign: focused ? TextAlign.start : TextAlign.center,
                    autocorrect: true,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (value) {
                      onchange.value = !onchange.value;
                      initiateSearch(value);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                      suffixIcon: IconButton(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        icon: focused
                            ? const Icon(
                                size: 25,
                                Icons.close,
                                color: Color(0Xff2675EC),
                              )
                            : const Icon(
                                size: 25,
                                Icons.search,
                                color: Color(0Xff2675EC),
                              ),
                        onPressed: () async {
                          if (focused) {
                            _focusNode.unfocus();
                            textEditingController.clear();
                            ref.read(tempSearchStore.notifier).state = [];

                            ref.read(snapshot.notifier).state = await FirebaseFirestore.instance.collection("chatrooms").get();
                          } else {
                            _focusNode.requestFocus();
                          }
                        },
                      ),
                      border: const OutlineInputBorder(borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: const BorderSide(color: Color.fromARGB(255, 205, 205, 206)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 205, 205, 206), // Set the border color when focused
                        ),
                      ),
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        fontFamily: "Manrope",
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xff3c3c43).withOpacity(0.5),
                      ),
                    ),
                    style: const TextStyle(
                        decoration: TextDecoration.none, color: Colors.black, fontFamily: 'Nunito', fontSize: 15.0, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              if (focused && users.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.only(top: 5),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return ListView(
                            padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                            primary: false,
                            shrinkWrap: true,
                            children: ref.read(tempSearchStore).map((element) {
                              return InkWell(
                                onTap: () async {
                                  String roomId = await ref.read(userController.notifier).getOrCreateRoom(element["username"]);

                                  await Navigator.pushNamed(context, '/channel', arguments: {
                                    "name": element["username"],
                                    "imageUrl": element["Photo"],
                                    "chatRoomId": roomId,
                                  });
                                  setState(() {});
                                },
                                child: ChatRoomCard(
                                  photoUrl: element['Photo'],
                                  username: element['username'],
                                ),
                              );
                            }).toList());
                      },
                      childCount: 1,
                    ),
                  ),
                )
              ] else if (focused && users.isEmpty) ...[
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 2 / 3,
                      child: const Center(
                          child: Text(
                        'No item',
                        style: TextStyle(fontFamily: 'Nunito'),
                      ))),
                )
              ] else ...[
                roomSnapshot == null
                    ? const SliverToBoxAdapter(
                        child: Center(
                        child: Text('Loading...'),
                      ))
                    : roomSnapshot.docs.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Center(
                            child: Text('No active rooms'),
                          ))
                        : SliverPadding(
                            padding: const EdgeInsets.only(top: 5),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int index) {
                                  return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: roomSnapshot.docs.length,
                                      shrinkWrap: true,
                                      physics: const ClampingScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        DocumentSnapshot ds = roomSnapshot.docs[index];
                                        String username = ds.id.replaceAll("_", "").replaceAll(
                                              ref.read(userController).myUserName,
                                              "",
                                            );

                                        return InkWell(
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => ChannelScreen(
                                                        thisChannelUsername: username,
                                                        imageUrl: AVATAR_URL,
                                                        chatRoomId: ds.id,
                                                      ))),
                                          child: ChatRoomCard(photoUrl: AVATAR_URL, username: username),
                                        );
                                      });
                                },
                                childCount: 1, // Number of items in the list
                              ),
                            ),
                          )
              ]
            ],
          ),
        ));
  }
}
