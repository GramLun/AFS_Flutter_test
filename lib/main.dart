import 'package:chat_mobile/chat_component.dart';
import 'package:flutter/material.dart';

import 'chat_list.dart';
import 'create_chat.dart';
import 'globals.dart' as globals;
import 'login.dart';

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

  @override
  Widget build(BuildContext context) {
    return ChatComponentWidget(
      widget._chatComponent,
      MaterialApp(
        title: 'Simple Chat',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/login',
        routes: {
          // TODO(moscow): '.../...' - put in constants of according pages
          LoginPage.LOGIN_ROUTE: (context) => LoginPage(),
          '/chat_list': (context) => ChatListPage(
                title: 'Chat list',
                chatComponent: widget._chatComponent,
              ),
          '/create_chat': (context) => CreateChatPage(title: 'Create Chat'),
        },
      ),
    );
  }
}
