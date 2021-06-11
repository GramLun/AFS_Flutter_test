import 'package:chat_mobile/activities/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class LogoutButton extends StatelessWidget {
  BuildContext context;

  LogoutButton({Key key, this.context});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        icon: Icon(Icons.exit_to_app),
        tooltip: 'Logout',
        onPressed: () {
          _showDialog().then((resultValue) {
            if (resultValue != null && resultValue is bool && resultValue) {
              _deleteStorageData();
              Navigator.popUntil(
                  context, ModalRoute.withName(LoginPage.LOGIN_ROUTE));
            }
          });
        });
  }

  Future<void> _deleteStorageData() async {
    var storage = await SharedPreferences.getInstance();
    await storage.remove('token');
    await storage.remove('user');
  }

  Future<bool> _showDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            FlatButton(
              child: Text('NO'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text('YES'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
