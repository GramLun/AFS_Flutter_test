# chat_mobile

Flutter mobile developer test

# Added:

- TabBar: Chats and Users
- Fab (create new chat on tap) re-work
- Save token and refresh when it will expire
  - I wanted to make a service that would decode the token and then check if it was time to refresh it, but the statusCode (response from server) check was enough
- Instead of 'Chat List' title = user.name
- RefreshIndicator
- User Settings widget
- If you click the LogOut button you will see ShowBar
- Other small things

# Problems I met:

- In file globals.dart I set host = '10.0.2.2' - to emulator get and display errors (it's emulator host)
- The project did not want to start because there were problems in the android part of the application, then I opened Android Studio:
  - set in Android Manifest permission to HTTP
  - set targetSdkVersion and compileSdkVersion to 28
