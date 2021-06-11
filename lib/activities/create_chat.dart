import 'dart:async';

import 'package:chat_api_client/chat_api_client.dart';
import 'package:chat_models/chat_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../ui/custom_user_tile.dart';
import '../components/api_client.dart';
import '../components/chat_component.dart';
import 'chat_content.dart';
import '../globals.dart' as globals;

class CreateChatPage extends StatefulWidget {
  CreateChatPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _CreateChatPageState createState() => _CreateChatPageState();
}

class _CreateChatPageState extends State<CreateChatPage>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<RefreshIndicatorState> _refreshUsersKey =
      GlobalKey<RefreshIndicatorState>();
  var _checkableUsers = <CheckableUser>[];
  var _checkedUsersCount = 0;
  bool _isVisible;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
    _isVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: FloatingActionButton(
          onPressed: () {
            createChat();
          },
          child: Icon(Icons.add),
        ),
      ),
      body: RefreshIndicator(
        key: _refreshUsersKey,
        onRefresh: _refreshUsers,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                itemCount: _checkableUsers.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildListTile(_checkableUsers[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomUserTile _buildListTile(CheckableUser checkableUser) {
    return CustomUserTile(
      checkableUser: checkableUser,
      onItemSelected: () {
        setState(() {
          changeColor(checkableUser);
          checkableUser.isChecked ? ++_checkedUsersCount : --_checkedUsersCount;
          _checkedUsersCount > 0 ? _isVisible = true : _isVisible = false;
        });
      },
    );
  }

  void changeColor(CheckableUser user) {
    user.isChecked = !user.isChecked;
    if (user.isChecked) {
      user.color = Colors.lightBlueAccent;
    } else {
      user.color = Colors.transparent;
    }
  }

  Future<Null> _refreshUsers() async {
    try {
      var _usersClient = UsersClient(MobileApiClient());
      List<User> found = await _usersClient.read({});
      found.removeWhere((user) => user.id == globals.currentUser.id);
      setState(() {
        _checkableUsers = found.map((foundUser) {
          return CheckableUser(user: foundUser);
        }).toList();
      });
    } on Exception catch (e) {
      print('Failed to get list of users');
      print(e);
    }
  }

  void createChat() async {
    var _checkedCounterparts = _checkableUsers
        .where((checkableUser) => checkableUser.isChecked == true)
        .map((checkableUser) => checkableUser.user)
        .toList();
    if (_checkedCounterparts.isNotEmpty) {
      try {
        var chatsClient = ChatsClient(MobileApiClient());
        var createdChat = await chatsClient.create(
            Chat(members: _checkedCounterparts..add(globals.currentUser)));
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => ChatContentPage(
              chat: createdChat,
              chatComponent: ChatComponentWidget.of(context).chatComponent,
            ),
          ),
          // result: true,
        );
      } on Exception catch (e) {
        print('Chat creation failed');
        print(e);
      }
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class CheckableUser {
  final User user;
  bool isChecked;
  Color color;

  CheckableUser({
    this.user,
    this.isChecked = false,
    this.color = Colors.transparent,
  });
}
