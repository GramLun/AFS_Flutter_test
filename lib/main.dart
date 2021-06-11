import 'dart:io';
import 'dart:convert';

import 'package:chat_mobile/components/chat_component.dart';
import 'package:chat_mobile/activities/user_settings.dart';
import 'package:chat_models/chat_models.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activities/chat_list.dart';
import 'globals.dart' as globals;
import 'activities/login.dart';

void main() => runApp(SimpleChatApp());

class SimpleChatApp extends StatefulWidget {
  final ChatComponent _chatComponent = ChatComponent(globals.webSocketAddress);

  @override
  _SimpleChatAppState createState() => _SimpleChatAppState();
}

class _SimpleChatAppState extends State<SimpleChatApp> {
  @override
  void initState() {
    super.initState();
    widget._chatComponent.connect();
  }

  @override
  void dispose() {
    widget._chatComponent.dispose();
    super.dispose();
  }

  String _decodeToken(String token) {
    final tokenParts = token.split('.');
    final codecBase64toStr = utf8.fuse(base64Url);
    final decoded = codecBase64toStr.decode(base64.normalize(tokenParts[1]));

    return decoded;
  }

  Future<void> _getLocalStorage() async {
    //here i will get shared pref for user and restore token
    var storage = await SharedPreferences.getInstance();
    globals.authToken = await storage.getString('token');
    print(globals.authToken);
    print(_decodeToken(globals.authToken));

    var userDataList = await storage.getStringList('user');
    var userDataMap = <String, dynamic>{
      'id': userDataList[0],
      'name': userDataList[1],
      'password': userDataList[2],
      'email': userDataList[3],
      'phone': userDataList[4],
    };
    var user = User.fromJson(userDataMap);
    globals.currentUser = user;
  }

  //token.fromBase64ToStr.split('.')[1] as Map<String, dynamic>;
  //
  // Map.exp and Map.iat;
  //
  // expiredTime = exp - iat; // get sec
  //
  // expiredTime * 0.75

  @override
  Widget build(BuildContext context) {
    return ChatComponentWidget(
      widget._chatComponent,
      FutureBuilder(
        future: _getLocalStorage(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return MaterialApp(
              title: 'Simple Chat',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              initialRoute: globals.authToken == null
                  ? LoginPage.LOGIN_ROUTE
                  : ChatListPage.CHAT_LIST_ROUTE,
              routes: {
                LoginPage.LOGIN_ROUTE: (context) => LoginPage(),
                ChatListPage.CHAT_LIST_ROUTE: (context) => ChatListPage(
                      title: globals.currentUser.name,
                      chatComponent: widget._chatComponent,
                    ),
                UserSettings.USER_SETTINGS_ROUTE: (context) => Scaffold(
                      body: UserSettings(),
                    ),
              },
            );
          } else {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }
        },
      ),
    );
  }
}
