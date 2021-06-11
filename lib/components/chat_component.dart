library chat_component;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:chat_models/chat_models.dart';
import 'package:flutter/widgets.dart';

typedef NotificationCallback<T> = void Function(T valueObject);

/// The component incapsulates websocket connection and provides api to subscribe
/// for new messages in some particular chat and for notifications about unread messages in any chat.
/// If there is a subscription for messages in a chat this class assume there is no unread
/// messages in this chat.
/// Clients should invoke [StreamSubscription.cancel] when stopped listening the stream.
///
/// Should be disposed after usage.
class ChatComponent {
  final String _address;
  WebSocket _webSocket;
  StreamSubscription _wsStreamSubscription;

  final _chatIdsWithUnreadMessages = HashSet<ChatId>();
  var _messageStreamControllers = <_ChatMessageStreamControllerWrapper>[];
  var _unreadMessageNotificationControllers = <StreamController<Set<ChatId>>>[];

  ChatComponent(this._address);

  Future<void> connect() async {
    var ws = WebSocket.connect(_address);
    await ws.then((webSocket) {
      _webSocket = webSocket;
      _wsStreamSubscription = webSocket.listen((data) {
        if (data is String) {
          final receivedMessage = MessageModel.fromJson(json.decode(data));
          var chatId = receivedMessage.chat;
          var messageConsumed = false;

          _messageStreamControllers
              .removeWhere((element) => element._streamController.isClosed);
          _messageStreamControllers.forEach((messageStreamControllerWrapper) {
            if (!messageStreamControllerWrapper._streamController.isClosed &&
                (messageStreamControllerWrapper._chatId == chatId)) {
              messageConsumed = true;
              messageStreamControllerWrapper._streamController.sink
                  .add(receivedMessage);
            }
          });

          if (!messageConsumed) {
            _chatIdsWithUnreadMessages.add(chatId);
            _notifyUnread();
          }
        }
      })
        ..onError((err) {
          // simple websocket reconnect policy
          print(err);
          connect();
        });
    });
  }

  StreamSubscription<Message> subscribeMessages(
      NotificationCallback<Message> callback, ChatId chatId) {
    _chatIdsWithUnreadMessages
        .remove(chatId); // assume all messages are read in this chat
    _notifyUnread();
    var streamController = StreamController<Message>();
    _messageStreamControllers
        .add(_ChatMessageStreamControllerWrapper(chatId, streamController));
    streamController.onCancel = () => streamController.close();
    return streamController.stream.listen((message) {
      callback(message);
    });
  }

  StreamSubscription<Set<ChatId>> subscribeUnreadMessagesNotification(
      NotificationCallback<Set<ChatId>> callback) {
    var streamController = StreamController<Set<ChatId>>();
    _unreadMessageNotificationControllers.add(streamController);
    streamController.onCancel = () => streamController.close();
    var result = streamController.stream.listen((chatIdSet) {
      callback(chatIdSet);
    });
    streamController.sink.add(_chatIdsWithUnreadMessages);
    return result;
  }

  void dispose() {
    _unreadMessageNotificationControllers.forEach((streamController) {
      if (!streamController.isClosed) {
        streamController.close();
      }
    });
    _unreadMessageNotificationControllers = null;

    _messageStreamControllers.forEach((streamControllerWrapper) {
      if (!streamControllerWrapper._streamController.isClosed) {
        streamControllerWrapper._streamController.close();
      }
    });
    _messageStreamControllers = null;

    _wsStreamSubscription?.cancel()?.then((_) {
      _webSocket?.close();
    });
  }

  void _notifyUnread() {
    // new
    _unreadMessageNotificationControllers
        .removeWhere((element) => element.isClosed);
    _unreadMessageNotificationControllers
        .forEach((unreadMessageNotificationController) {
      unreadMessageNotificationController.sink.add(_chatIdsWithUnreadMessages);
    });
  }
}

class _ChatMessageStreamControllerWrapper {
  final ChatId _chatId;
  final StreamController<Message> _streamController;

  _ChatMessageStreamControllerWrapper(this._chatId, this._streamController);
}

class ChatComponentWidget extends InheritedWidget {
  final ChatComponent chatComponent;

  ChatComponentWidget(this.chatComponent, child) : super(child: child);

  static ChatComponentWidget of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ChatComponentWidget>();
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;
}
