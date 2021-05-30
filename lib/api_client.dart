import 'package:chat_api_client/chat_api_client.dart';

import 'globals.dart' as globals;

class MobileApiClient extends ApiClient {
  MobileApiClient()
      : super(Uri.parse(globals.chatApiAddress),
            onBeforeRequest: (ApiRequest request) {
          if (globals.authToken != null) {
            return request.change(
                headers: {}
                  ..addAll(request.headers)
                  ..addAll({'authorization': globals.authToken}));
          }
          return request;
        }, onAfterResponse: (ApiResponse response) {
          if (response.headers.containsKey('authorization')) {
            globals.authToken = response.headers['authorization'];
          }
          return response;
        });
}
