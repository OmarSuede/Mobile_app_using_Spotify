import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

import 'PlaylistPage.dart';

class RecommendedPlaylist extends StatefulWidget {
  final Playlist playlist;

  // ignore: use_key_in_widget_constructors
  const RecommendedPlaylist({required this.playlist});

  @override
  // ignore: library_private_types_in_public_api
  State<RecommendedPlaylist> createState() => _RecommendedPlaylistState();
}

class _RecommendedPlaylistState extends State<RecommendedPlaylist> {
  List<Song> _songsFuture = [];

  Future<void> _fetchSongs(Playlist playlist) async {
    //print("yoooo ${playlist.id} ");
    try {
      final accessToken = await SpotifySdk.getAccessToken(
          clientId: dotenv.env['CLIENT_ID'].toString(),
          redirectUrl: dotenv.env['REDIRECT_URL'].toString(),
          scope: 'app-remote-control, '
              'user-modify-playback-state, '
              'playlist-read-private, '
              'playlist-modify-public,user-read-currently-playing');
      //print("yoooo ${playlist.id} ");

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
            imageUrl: song['album']['images'][0]['url'] as String,
          );
        }).toList();
        _songsFuture = songs;
      } else {
        throw Exception('Failed to fetch songs');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSongs(widget.playlist);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.playlist.name} Recommendations'),
        backgroundColor: const Color(0xFF1C1B1B),
      ),
      backgroundColor: const Color(0xFF1C1B1B),
      body: ListView.builder(
        itemCount: _songsFuture.length,
        itemBuilder: (context, index) {
          final songs = _songsFuture[index];
          return Column(
            children: [
              ListTile(
                leading: Image.network(
                  songs.imageUrl ?? Song.defaultImageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(
                  songs.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
