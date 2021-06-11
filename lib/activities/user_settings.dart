import 'package:chat_api_client/chat_api_client.dart';
import 'package:chat_mobile/activities/chat_list.dart';
import 'package:chat_models/chat_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/api_client.dart';
import '../globals.dart' as globals;

class UserSettings extends StatefulWidget {
  static const USER_SETTINGS_ROUTE = '/user_settings';

  UserSettings({Key key}) : super(key: key);

  @override
  _UserSettingsState createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  final GlobalKey<FormState> _settingsFormKey = GlobalKey<FormState>();

  final String _title = 'Edit profile';

  String _email;
  String _phone;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    if (globals.currentUser.email.isEmpty) {
      _email = 'Email';
    } else {
      _email = globals.currentUser.email;
    }
    if (globals.currentUser.phoneNumber.isEmpty) {
      _phone = 'Phone';
    } else {
      _phone = globals.currentUser.phoneNumber;
    }
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _validateEmail(String value) {
    var emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
    if (emailValid) {
      return null;
    }
    if (value.isEmpty) {
      return null;
    }
    return 'Invalid email';
  }

  String _validatePhone(String value) {
    // var phoneValid = RegExp(r'^(?:[+0]9)?[0-9]{10}$').hasMatch(value);
    // if (phoneValid) {
    //   return null;
    // }
    if (value.contains('+') && value.length == 12) {
      return null;
    }
    if (value.length == 11 && value.indexOf('8') == 0) {
      return null;
    }
    if (value.isEmpty) {
      return null;
    }
    return 'Invalid phone number';
  }

  int _phoneLength() {
    return 12;
    // if (_phoneController.text.isEmpty) {
    //   return length;
    // }
    // if (_phoneController.text[0] == '+') {
    //   length = 12;
    // } else {
    //   length = 11;
    // }
    // return length;
  }

  void _nameCheck(String value) {
    if (_nameController.text.isNotEmpty) {
      if (globals.currentUser.name != value) {
        globals.currentUser.name = value;
      }
    }
  }

  void _emailCheck(String value) {
    if (_emailController.text.isNotEmpty) {
      if (globals.currentUser.email.isEmpty ||
          globals.currentUser.email != value) {
        globals.currentUser.email = value;
        print(globals.currentUser.email);
      }
    }
  }

  void _phoneCheck(String value) {
    if (_phoneController.text.isNotEmpty) {
      if (globals.currentUser.phoneNumber.isEmpty ||
          globals.currentUser.phoneNumber != value) {
        globals.currentUser.phoneNumber = value;
      }
    }
  }

  // ignore: always_declare_return_types
  _updateUserDataOnBack(BuildContext context) {
    if (_settingsFormKey.currentState.validate()) {
      _settingsFormKey.currentState.save();
      var usersClient = UsersClient(MobileApiClient());
      usersClient
          .update(User(
        id: globals.currentUser.id,
        name: globals.currentUser.name,
        password: globals.currentUser.password,
        email: globals.currentUser.email,
        phoneNumber: globals.currentUser.phoneNumber,
      ))
          .then((updatedUser) {
        final snackBar =
            SnackBar(content: Text('User \'${updatedUser.name}\' updated'));
        Scaffold.of(context).showSnackBar(snackBar);
        Navigator.popUntil(
            context, ModalRoute.withName(ChatListPage.CHAT_LIST_ROUTE));
      }).catchError((updateError) {
        final snackBar =
            SnackBar(content: Text('Updating failed: ${updateError.message}'));
        Scaffold.of(context).showSnackBar(snackBar);
        print('Updating failed');
        print(updateError);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.popUntil(
                context, ModalRoute.withName(ChatListPage.CHAT_LIST_ROUTE)),
            icon: Icon(
              Icons.arrow_back,
            ),
          ),
          title: Text(
            _title,
            style: TextStyle(fontSize: 23),
          ),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.check),
                tooltip: 'Submit',
                onPressed: () {
                  _updateUserDataOnBack(context);
                }),
          ],
        ),
        body:
            userSettingsView() // This trailing comma makes auto-formatting nicer for build methods.
        );
  }

  Widget userSettingsView() {
    return Column(
      children: <Widget>[
        Expanded(
          child: Container(
            child: Form(
              key: _settingsFormKey,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 4),
                    child: Container(
                      child: TextFormField(
                        onSaved: (String value) => _nameCheck(value),
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: globals.currentUser.name,
                          hintStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 4),
                    child: Container(
                      child: TextFormField(
                        onSaved: (String value) => _emailCheck(value),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => _validateEmail(value),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: _email,
                          hintStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 4),
                    child: Container(
                      child: TextFormField(
                        onSaved: (String value) => _phoneCheck(value),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) => _validatePhone(value),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(_phoneLength())
                        ],
                        decoration: InputDecoration(
                          labelText: 'Phone number',
                          hintText: _phone,
                          hintStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
