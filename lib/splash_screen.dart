import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: Center(
        child: Text("Simple Chat",
          style: TextStyle(
            color: Colors.white,
            decoration: TextDecoration.none
          ),
        )
      ),
    );
  }
}