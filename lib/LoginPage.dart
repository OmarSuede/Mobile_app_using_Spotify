import 'package:flutter/material.dart';
import 'package:reccomendify/ChoosePage.dart';
import 'package:reccomendify/WelcomeScreen.dart';
import 'package:reccomendify/main.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});
  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  bool _connected = false;
  final Logger _logger = Logger(
    //filter: CustomLogFilter(), // custom logfilter can be used to have logs in release mode
    printer: PrettyPrinter(
      methodCount: 2, // number of method calls to be displayed
      errorMethodCount: 8, // number of method calls if stacktrace is provided
      lineLength: 120, // width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      printTime: true,
    ),
  );

  Future<void> connectToSpotifyRemote() async {
    try {
      setState(() {
        _loading = true;
      });
      var result = await SpotifySdk.connectToSpotifyRemote(
          clientId: dotenv.env['CLIENT_ID'].toString(),
          redirectUrl: dotenv.env['REDIRECT_URL'].toString());
      if (result) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChoosePage(
                      title: '',
                    )));
      } else {
        setStatus('connect to spotify failed');
      }
    } on PlatformException catch (e) {
      setState(() {
        _loading = false;
      });
      setStatus(e.code, message: e.message);
    } on MissingPluginException {
      setState(() {
        _loading = false;
      });
      setStatus('not implemented');
    }
  }

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
              const SizedBox(height: 200),
              const Text(
                "Enjoy Finding New Music",
                style: TextStyle(
                    fontFamily: 'Impact',
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 200),
              Container(
                height: 65,
                width: 350,
                decoration: BoxDecoration(
                    color: Color(0xFFFF6161),
                    borderRadius: BorderRadius.circular(20)),
                child: TextButton(
                  onPressed: () {
                    //login using spotify
                    connectToSpotifyRemote();
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

  void setStatus(String code, {String? message}) {
    var text = message ?? '';
    _logger.i('$code$text');
  }
}
