import 'package:chat_api_client/chat_api_client.dart';
import 'package:chat_models/chat_models.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';
import 'globals.dart' as globals;

class LoginPage extends StatefulWidget {

  static const LOGIN_ROUTE = '/login';

  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginData {
  String login = '';
  String password = '';
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _LoginData _loginData = _LoginData();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _validateLogin(String value) {
    if (value.length < 2) {
      // check login rules here
      return 'The Login must be at least 2 characters.';
    }
    return null;
  }

  String _validatePassword(String value) {
    if (value.length < 2) {
      // check password rules here
      return 'The Password must be at least 2 characters.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Builder(
      builder: (BuildContext scaffoldContext) {
        return Container(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Form(
              key: this._formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextFormField(
                    controller: _loginController,
                    validator: this._validateLogin,
                    onSaved: (String value) {
                      this._loginData.login = value;
                    },
                    decoration: InputDecoration(
                        hintText: 'Login', labelText: 'Enter your login'),
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    // Use secure text for passwords.
                    validator: this._validatePassword,
                    onSaved: (String value) {
                      this._loginData.password = value;
                    },
                    decoration: InputDecoration(
                        hintText: 'Password', labelText: 'Enter your password'),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        RaisedButton(
                            child: Text("Login"),
                            onPressed: () {
                              _login(scaffoldContext);
                            }),
                        FlatButton(
                          child: Text("Sign up"),
                          onPressed: () {
                            _signUp(scaffoldContext);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ));
  }

  _signUp(BuildContext context) {
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save();
      _showDialog(_loginData.login).then((resultValue) {
        if (resultValue != null && resultValue is bool && resultValue) {
          var usersClient = UsersClient(MobileApiClient());
          usersClient
              .create(
                  User(name: _loginData.login, password: _loginData.password))
              .then((createdUser) {
            _clearUi();
            final snackBar =
                SnackBar(content: Text('User \'${createdUser.name}\' created'));
            Scaffold.of(context).showSnackBar(snackBar);
          }).catchError((signUpError) {
            final snackBar = SnackBar(
                content: Text('Sign up failed: ${signUpError.message}'));
            Scaffold.of(context).showSnackBar(snackBar);
            print('Sign up failed');
            print(signUpError);
          });
        }
      });
    }
  }

  _login(BuildContext context) async {
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save();

      try {
        var usersClient = UsersClient(MobileApiClient());
        var user =
            await usersClient.login(_loginData.login, _loginData.password);
        globals.currentUser = user;
        await Navigator.pushNamed(context, '/chat_list').then((_) {
          globals.currentUser = null;
          globals.authToken = null;
        });
        _clearUi();
      } on Exception catch (e) {
        final snackBar = SnackBar(content: Text('Login failed'));
        Scaffold.of(context).showSnackBar(snackBar);
        print('Login failed');
        print(e);
      }
    }
  }

  Future<bool> _showDialog(String username) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text("Do you want to create user '$username' ?"),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _clearUi() {
    _loginController.clear();
    _passwordController.clear();
  }
}
