import 'dart:async';
import 'dart:collection';

import 'package:chat_api_client/chat_api_client.dart';
import 'package:chat_mobile/activities/chat_list.dart';
import 'package:chat_models/chat_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/api_client.dart';
import '../components/chat_component.dart';
import '../ui/common_ui.dart';
import '../globals.dart' as globals;

class ChatContentPage extends StatefulWidget {
  ChatContentPage({Key key, @required this.chat, @required this.chatComponent})
      : super(key: key);
  final ChatComponent chatComponent;
  final Chat chat;
  final formatter = DateFormat('HH:mm');

  @override
  _ChatContentPageState createState() => _ChatContentPageState();
}

class _ChatContentPageState extends State<ChatContentPage> {
  String _title;
  var _messages = <Message>[];
  final _sendMessageTextController = TextEditingController();
  StreamSubscription<Message> _messagesSubscription;
  StreamSubscription<Set<ChatId>> _unreadMessagesSubscription;
  final Set<ChatId> _unreadChats = HashSet<ChatId>();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _title = widget.chat.members
        .where((user) => user.id != globals.currentUser.id)
        .map((user) => user.name)
        .join(', ');
    refreshChatContent();

    _messagesSubscription =
        widget.chatComponent.subscribeMessages((receivedMessage) {
      setState(() {
        _messages.add(receivedMessage);
      });
    }, widget.chat.id);

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
    _sendMessageTextController.dispose();
    _messagesSubscription.cancel();
    _unreadMessagesSubscription.cancel();
    super.dispose();
  }

  void refreshChatContent() async {
    try {
      var msgList =
          await MessagesClient(MobileApiClient()).read(widget.chat.id);
      setState(() {
        _messages = msgList.reversed.toList();
      });
    } on Exception catch (e) {
      print('Failed to get list of messages');
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    var actions = <Widget>[];
    if (_unreadChats.isNotEmpty) {
      actions.add(IconButton(
          icon: Icon(Icons.message),
          tooltip: 'New messages',
          color: Colors.greenAccent,
          onPressed: () {
            Navigator.popUntil(
                context, ModalRoute.withName(ChatListPage.CHAT_LIST_ROUTE));
          }));
    }
    actions.add(LogoutButton());

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: actions,
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildListTile(_messages[index]);
                },
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _sendMessageTextController,
                    decoration: InputDecoration(hintText: 'Your message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_sendMessageTextController.text.isNotEmpty) {
                      send(_sendMessageTextController.text);
                      _scrollController.animateTo(0.0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut);
                    }
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(Message message) {
    var isMyMessage = message.author.id == globals.currentUser.id;
    var messageTime = widget.formatter.format(message.createdAt);
    return _Bubble(
      message: message.text,
      isMe: isMyMessage,
      time: messageTime,
    );
  }

  void send(String message) async {
    final newMessage = MessageModel(
        chat: widget.chat.id,
        author: globals.currentUser,
        text: message,
        createdAt: DateTime.now());
    try {
      await MessagesClient(MobileApiClient()).create(newMessage);
      _sendMessageTextController.clear();
    } on Exception catch (e) {
      print('Sending message failed');
      print(e);
    }
  }
}

class _Bubble extends StatelessWidget {
  _Bubble({this.message, this.time, this.isMe});

  final String message, time;
  final isMe;

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? Colors.white : Colors.greenAccent.shade100;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isMe
        ? BorderRadius.only(
            topLeft: Radius.circular(7.0),
            bottomLeft: Radius.circular(7.0),
            bottomRight: Radius.circular(10.0),
          )
        : BorderRadius.only(
            topRight: Radius.circular(7.0),
            bottomLeft: Radius.circular(10.0),
            bottomRight: Radius.circular(7.0),
          );
    return Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.all(3.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  blurRadius: .5,
                  spreadRadius: 1.0,
                  color: Colors.black.withOpacity(.12))
            ],
            color: bg,
            borderRadius: radius,
          ),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 48.0),
                child: Text(message),
              ),
              Positioned(
                bottom: 0.0,
                right: 0.0,
                child: Row(
                  children: <Widget>[
                    Text(time,
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 10.0,
                        )),
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
