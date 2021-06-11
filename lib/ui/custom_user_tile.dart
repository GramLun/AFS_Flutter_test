import 'package:flutter/material.dart';

import '../activities/create_chat.dart';

// ignore: must_be_immutable
class CustomUserTile extends StatelessWidget {
  CheckableUser checkableUser;
  final VoidCallback onItemSelected;
  CustomUserTile({Key key, this.checkableUser, this.onItemSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: checkableUser.color,
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            _findInitials(checkableUser.user.name) ?? '',
            style: TextStyle(color: Colors.white70),
          ),
          backgroundColor: Colors.blue,
        ),
        title: Text(checkableUser.user.name ?? 'UNKNOWN'),
        subtitle: Text(_checkEmail(checkableUser.user.email)),
        onTap: () {
          onItemSelected();
        },
      ),
    );
  }

  String _checkEmail(String email) {
    if (email.isEmpty) {
      return 'no_email';
    } else {
      return email;
    }
  }

  String _findInitials(String name) {
    var initials = name[0];
    var i = name.indexOf(' ');
    if (i != -1) {
      return initials += name[i + 1];
    } else {
      return initials;
    }
  }
}
