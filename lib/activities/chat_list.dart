import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:chat_api_client/chat_api_client.dart';
import 'package:chat_mobile/activities/user_settings.dart';
import 'package:chat_models/chat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/api_client.dart';
import '../components/chat_component.dart';
import 'chat_content.dart';
import '../ui/common_ui.dart';
import 'create_chat.dart';
import '../globals.dart' as globals;

class ChatListPage extends StatefulWidget {
  static const CHAT_LIST_ROUTE = '/chat_list';

  ChatListPage({Key key, this.title, @required this.chatComponent})
      : super(key: key);

  final String title;
  final ChatComponent chatComponent;

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final GlobalKey<RefreshIndicatorState> _refreshChatsKey =
      GlobalKey<RefreshIndicatorState>();

  var _chats = <Chat>[];
  final Set<ChatId> _unreadChats = HashSet<ChatId>();
  StreamSubscription<Set<ChatId>> _unreadMessagesSubscription;

  @override
  void initState() {
    super.initState();
    _refreshChats();
    _unreadMessagesSubscription = widget.chatComponent
        .subscribeUnreadMessagesNotification((unreadChatIds) {
      setState(() {
        _unreadChats.clear();
        _unreadChats.addAll(unreadChatIds);
      });
    });
  }

  @override
  void dispose() {
    _unreadMessagesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var listTiles =
        _chats.map<Widget>((Chat chatItem) => _buildListTile(chatItem));
    listTiles = ListTile.divideTiles(context: context, tiles: listTiles);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(fontSize: 23),
          ),
          leading: IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, UserSettings.USER_SETTINGS_ROUTE),
            icon: Icon(
              Icons.account_circle_rounded,
            ),
          ),
          actions: <Widget>[LogoutButton(context: context)],
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Users'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            Expanded(
              child: RefreshIndicator(
                key: _refreshChatsKey,
                onRefresh: _refreshChats,
                child: ListView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  children: listTiles.toList(),
                ),
              ),
            ),
            Expanded(
              child: CreateChatPage(
                title: 'second fragment',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(Chat chat) {
    return Container(
      child: ListTile(
        leading:
            _unreadChats.contains(chat.id) ? const Icon(Icons.message) : null,
        title: Text(chat.members
            .where((user) => user.id != globals.currentUser.id)
            .map((user) => user.name)
            .join(', ')),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return ChatContentPage(
                  chat: chat,
                  chatComponent: ChatComponentWidget.of(context).chatComponent,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ignore: always_declare_return_types
  _reLogin() async {
    try {
      var storage = await SharedPreferences.getInstance();
      var login = storage.getStringList('user')[1];
      var password = storage.getStringList('user')[2];

      var usersClient = UsersClient(MobileApiClient());
      var user = await usersClient.login(login, password);
      globals.currentUser = user;

      await storage.setString('token', globals.authToken);

      await Navigator.pushNamed(context, ChatListPage.CHAT_LIST_ROUTE)
          .then((_) {
        globals.currentUser = null;
        globals.authToken = null;
      });
    } on Exception catch (e) {
      final snackBar = SnackBar(content: Text('Re-login failed'));
      Scaffold.of(context).showSnackBar(snackBar);
      print('Re-login failed');
      print(e);
    }
  }

  Future<Null> _refreshChats() async {
    try {
      var mApiClient = MobileApiClient();
      List<Chat> found = await ChatsClient(mApiClient).read({});
      setState(() {
        _chats = found;
      });
    } on Exception catch (e) {
      if (globals.authResponseCode == 401) {
        _reLogin();
      }
      print('Failed to get list of chats');
      print(e);
    }
  }
}
