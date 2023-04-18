import 'package:flutter/material.dart';
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
  Playlist? _selectedPlaylist;
  late Playlist NewPlaylist;

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
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
      final accessToken = await SpotifySdk.getAccessToken(
          clientId: dotenv.env['CLIENT_ID'].toString(),
          redirectUrl: dotenv.env['REDIRECT_URL'].toString(),
          scope: 'app-remote-control, '
              'user-modify-playback-state, '
              'playlist-read-private, '
              'playlist-modify-public,user-read-currently-playing');
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/playlists'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final items = jsonData['items'];
        setState(() {
          _playlists =
              items.map<Playlist>((item) => Playlist.fromJson(item)).toList();
          _loading = false;
        });
      } else {
        throw Exception('Failed to fetch playlists');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<List<Song>> _fetchSongs(Playlist playlist) async {
    try {
      final accessToken = await SpotifySdk.getAccessToken(
          clientId: dotenv.env['CLIENT_ID'].toString(),
          redirectUrl: dotenv.env['REDIRECT_URL'].toString(),
          scope: 'app-remote-control, '
              'user-modify-playback-state, '
              'playlist-read-private, '
              'playlist-modify-public,user-read-currently-playing');
      print("yoooo ${playlist.id} ");

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/playlists/${playlist.id}/tracks'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
// fix problem where if a song is removed from spotify it will bug the request
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final items = jsonData['items'] as List<dynamic>;
        final songs = items.map((items) {
          final song = items['track'];
          return Song(
            id: song['id'] as String,
            name: song['name'] as String,
            artistName: (song['artists'] as List<dynamic>)
                .map((artist) => artist['name'] as String)
                .join(', '),
          );
        }).toList();
        return songs;
      } else {
        throw Exception('Failed to fetch songs');
      }
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<Playlist> recommendRandomSongs(Playlist playlist) async {
    final tracks = await _fetchSongs(playlist);
    final trackIds = tracks.map((track) => track.id).toList();
    final randomTrackIds = (trackIds.toList()..shuffle()).take(5).join(',');
    print('hello $randomTrackIds');
    final accessToken = await SpotifySdk.getAccessToken(
        clientId: dotenv.env['CLIENT_ID'].toString(),
        redirectUrl: dotenv.env['REDIRECT_URL'].toString(),
        scope: 'app-remote-control, '
            'user-modify-playback-state, '
            'playlist-read-private, '
            'playlist-modify-public,user-read-currently-playing');

    final url =
        'https://api.spotify.com/v1/recommendations?seed_tracks=$randomTrackIds&limit=10';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final trackJson = jsonResponse['tracks'] as List<dynamic>;
      final trackUris =
          trackJson.map((track) => 'spotify:track:${track['id']}').toList();

      final playlistName = '${playlist.name} Recommendations';
      const createPlaylistUrl = 'https://api.spotify.com/v1/me/playlists';

      final createPlaylistResponse = await http.post(
        Uri.parse(createPlaylistUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json'
        },
        body: json.encode({'name': playlistName}),
      );

      if (createPlaylistResponse.statusCode == 201) {
        final playlistJson = json.decode(createPlaylistResponse.body);
        final playlistId = playlistJson['id'] as String;

        final addTracksUrl =
            'https://api.spotify.com/v1/playlists/$playlistId/tracks';

        await http.post(
          Uri.parse(addTracksUrl),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json'
          },
          body: json.encode({'uris': trackUris}),
        );
        final createdPlaylist = Playlist(
          id: playlistId,
          name: playlistName,
        );
        return createdPlaylist;
      } else {
        throw Exception(
            'Failed to create playlist: ${createPlaylistResponse.statusCode}');
      }
    } else {
      throw Exception('Failed to recommend songs: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
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
                        NewPlaylist =
                            await recommendRandomSongs(_selectedPlaylist!);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => RecommendedPlaylist(
                                      playlist: NewPlaylist,
                                    )));
                      },
                    ),
                    Divider(
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

  Song({
    required this.id,
    required this.name,
    required this.artistName,
    this.imageUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    final id = json['track']['id'];
    final name = json['track']['name'];
    final artistName = json['track']['artists'][0]['name'];
    final imageUrl = json['track']['album']['images'].isNotEmpty
        ? json['track']['album']['images'][0]['url']
        : null;

    return Song(
      id: id,
      name: name,
      artistName: artistName,
      imageUrl: imageUrl,
    );
  }
}
