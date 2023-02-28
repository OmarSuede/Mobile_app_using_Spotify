import 'package:flutter/material.dart';
import 'package:reccomendify/ChoosePage.dart';
import 'package:reccomendify/WelcomeScreen.dart';
import 'package:reccomendify/main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF1C1B1B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'images/logo-png.png',
                height: 110,
                width: 165,
              ),
              SizedBox(height: 200),
              Text(
                "Enjoy Finding New Music",
                style: TextStyle(
                    fontFamily: 'Impact',
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 200),
              Container(
                height: 65,
                width: 350,
                decoration: BoxDecoration(
                    color: Color(0xFFFF6161),
                    borderRadius: BorderRadius.circular(20)),
                child: TextButton(
                  onPressed: () {
                    //login using spotify
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChoosePage(
                                  title: '',
                                )));
                  },
                  child: Text(
                    'Login With Spotify',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Not a Member? ",
                      style: TextStyle(
                          fontFamily: 'Impact',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () {
                        //TODO take you to register for spotify
                      },
                      child: Text(
                        'Register Here',
                        style: TextStyle(color: Colors.blue, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
