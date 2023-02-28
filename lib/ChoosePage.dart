import 'package:flutter/material.dart';
import 'package:reccomendify/WelcomeScreen.dart';
import 'package:reccomendify/main.dart';

class ChoosePage extends StatefulWidget {
  const ChoosePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<ChoosePage> createState() => _ChoosePageState();
}

class _ChoosePageState extends State<ChoosePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF1C1B1B),
        ),
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
              SizedBox(height: 60),
              Text(
                "Discover And Share New Music",
                style: TextStyle(
                    fontFamily: 'Impact',
                    fontSize: 25,
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              Text(
                "With Musily You choose a playlist from spotify, and we will reccomend music that sounds Alike",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Impact',
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
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
                            builder: (_) => WelcomeScreen(
                                  title: '',
                                )));
                  },
                  child: Text(
                    'Choose a playlist',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
