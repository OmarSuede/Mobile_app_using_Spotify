import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:musily/PlaylistPage.dart';

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
  late String _accessToken;

  void _initSpotify() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      _accessToken = pref.getString("_Token")!;
    });
    await _fetchSongs(widget.playlist);
  }

  Future<void> _fetchSongs(Playlist playlist) async {
    //print("yoooo ${playlist.id} ");
    try {
      //print("yoooo ${playlist.id} ");

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/playlists/${playlist.id}/tracks'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      // fix problem where if a song is removed from spotify it will bug the request
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final items = jsonData['items'] as List<dynamic>;
        final songs = items.map((items) {
          final song = items['track'];
          /*
          final durationMs = song['duration_ms'] as int;
          final Duration duration = Duration(milliseconds: durationMs)
              .toString()
              .split('.')
              .first
              .padLeft(8, "0") as Duration;
              */
          return Song(
            id: song['id'] as String,
            name: song['name'] as String,
            artistName: (song['artists'] as List<dynamic>)
                .map((artist) => artist['name'] as String)
                .join(', '),
            imageUrl: song['album']['images'].isNotEmpty
                ? song['album']['images'][0]['url'] as String?
                : null,
            //songDuration: duration
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

  Future<bool> checkIfPremium() async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final productType = jsonResponse['product'] ?? '';
      return productType == 'premium';
      //print("yoooooo" + productType);
    } else {
      throw Exception('Failed to get user info: ${response.statusCode}');
    }
  }

  @override
  void initState() {
    super.initState();
    _initSpotify();
  }

  void openSpotifyPlaylist(String playlistId) async {
    final Uri spotifyUri = Uri.parse('spotify:playlist:$playlistId');
    final Uri spotifyUrl =
        Uri.parse('https://open.spotify.com/playlist/$playlistId');

    if (await canLaunchUrl(spotifyUri)) {
      await launchUrl(spotifyUri);
    } else if (await canLaunchUrl(spotifyUrl)) {
      await launchUrl(spotifyUrl);
    } else {
      throw 'Could not launch Spotify.';
    }
  }

  void openSpotifySong(String songId) async {
    final Uri url = Uri.parse('spotify:track:$songId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(widget.playlist.name,
              style: const TextStyle(
                fontSize: 20,
              )),
        ),
        backgroundColor: const Color(0xFF1C1B1B),
      ),
      backgroundColor: const Color(0xFF1C1B1B),
      body: FutureBuilder<void>(
        future: _fetchSongs(widget.playlist),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ListView.builder(
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
                      subtitle: Text(
                        songs.artistName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      onTap: () async {
                        if (await checkIfPremium()) {
                          openSpotifySong(songs.id);
                          SpotifySdk.play(
                            spotifyUri: 'spotify:track:${songs.id}',
                          );
                        }
/*
                        final trackList = _songsFuture
                            .skip(index + 1)
                            .map((song) => 'spotify:track:${song.id}')
                            .toList();

                        if (trackList.isNotEmpty) {
                          await SpotifySdk.queue(
                            spotifyUri: trackList.join(','),
                          );
                        }
                        */
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
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      bottomNavigationBar: PreferredSize(
        preferredSize: const Size.fromHeight(200.0),
        child: BottomAppBar(
          color: Color(0xFFFF6161),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: SizedBox(
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll<Color>(Color(0xFF1C1B1B)),
                    ),
                    onPressed: () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PlaylistPage(
                                    title: '',
                                  )));
                    },
                    child: Text(
                      'Go Back',
                      style: TextStyle(color: Color(0xFFFF6161), fontSize: 15),
                    ),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(0, 5, 20, 0),
              ),
              Container(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStatePropertyAll<Color>(Color(0xFF1C1B1B)),
                  ),
                  onPressed: (
                      //open in spotify
                      ) async {
                    openSpotifyPlaylist(widget.playlist.id);
                  },
                  child: Text(
                    'Open in Spotify',
                    style: TextStyle(color: Color(0xFFFF6161), fontSize: 15),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
