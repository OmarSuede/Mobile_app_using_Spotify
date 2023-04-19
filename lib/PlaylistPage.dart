import 'package:flutter/material.dart';
import 'package:reccomendify/PlaylistView.dart';
import 'package:reccomendify/RecommendedPlaylist.dart';
//import 'package:reccomendify/RecommendedPlaylist.dart';
import 'package:reccomendify/WelcomeScreen.dart';
import 'package:reccomendify/main.dart';
import 'package:http/http.dart' as http;
import 'package:spotify_sdk/spotify_sdk.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:jwt_decode/jwt_decode.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<Playlist> _playlists = [];
  bool _loading = true;
  late Playlist? _selectedPlaylist;
  late Playlist NewPlaylist;
  late String _accessToken;
  String userId = "";

  void _initSpotify() async {
    var accessToken = await SpotifySdk.getAccessToken(
        clientId: dotenv.env['CLIENT_ID'].toString(),
        redirectUrl: dotenv.env['REDIRECT_URL'].toString(),
        scope: 'app-remote-control, '
            'user-modify-playback-state, '
            'playlist-read-private, '
            'playlist-modify-public,user-read-currently-playing,user-read-email,user-read-private');
    setState(() {
      _accessToken = accessToken;
    });
    await _fetchPlaylists();
  }

  @override
  void initState() {
    super.initState();
    _initSpotify();
  }

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
  void setStatus(String code, {String? message}) {
    var text = message ?? '';
    _logger.i('$code$text');
  }

  Future<void> _fetchPlaylists() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/playlists'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      //print("yooooooo" + _accessToken);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final items = jsonData['items'];
        setState(() {
          _playlists =
              items.map<Playlist>((item) => Playlist.fromJson(item)).toList();
          _loading = false;
        });
      } else {
        throw Exception('Failed to fetch playlists  ${response.reasonPhrase}');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Playlists',
            style: TextStyle(
              fontSize: 20,
            )),
        centerTitle: true,
        backgroundColor: const Color(0xFF1C1B1B),
      ),
      backgroundColor: const Color(0xFF1C1B1B),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return Column(
                  children: [
                    ListTile(
                      leading: Image.network(
                        playlist.imageUrl ?? Playlist.defaultImageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(
                        playlist.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () async {
                        // Navigate to playlist details screen
                        _selectedPlaylist = playlist;

                        //NewPlaylist =
                        //await recommendRandomSongs(_selectedPlaylist!);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PlaylistView(
                                      playlist: _selectedPlaylist!,
                                    )));
                      },
                    ),
                    const Divider(
                      height: 20,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class Playlist {
  static const defaultImageUrl =
      'https://via.placeholder.com/50x50.png?text=No+Image';

  final String name;
  final String id;
  final String? imageUrl;

  Playlist({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final imagesJson = json['images'];
    final imageUrl = imagesJson.isNotEmpty ? imagesJson[0]['url'] : null;
    return Playlist(
      id: id,
      name: json['name'],
      imageUrl: imageUrl,
    );
  }
}

class Song {
  static const defaultImageUrl =
      'https://via.placeholder.com/50x50.png?text=No+Image';
  final String id;
  final String name;
  final String artistName;
  final String? imageUrl;
  //final Duration songDuration;

  Song({
    required this.id,
    required this.name,
    required this.artistName,
    this.imageUrl,
    //required this.songDuration,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    final id = json['track']['id'];
    final name = json['track']['name'];
    final artistName = json['track']['artists'][0]['name'];
    final imageUrl = json['track']['album']['images'].isNotEmpty
        ? json['track']['album']['images'][0]['url']
        : null;
    //final songDuration = Duration(milliseconds: json['track']['duration_ms']);

    return Song(
      id: id,
      name: name,
      artistName: artistName,
      imageUrl: imageUrl,
      //songDuration: songDuration,
    );
  }
}
