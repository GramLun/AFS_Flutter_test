import 'package:flutter/material.dart';

class LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
        icon: Icon(Icons.exit_to_app),
        tooltip: 'Logout',
        onPressed: () {
          Navigator.popUntil(context, ModalRoute.withName('/'));
        });
  }
}
