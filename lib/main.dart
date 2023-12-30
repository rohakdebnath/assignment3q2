import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

Future<List<Album>> getAlbum() async {
  final response =
      await http.get(Uri.parse('https://jsonplaceholder.typicode.com/albums'));

  if (response.statusCode == 200) { //200 represents a respone status of OK
    List<dynamic> data = jsonDecode(response.body);
    List<Album> albums = [];
    for (Map<String, dynamic> json in data) {
      Album album = Album.fromJson(json);
      albums.add(album);
    }
    return albums;
  } else {
    throw Exception('Failed to load album'); //status not ok
  }
}

Future<void> createAlbum(String title) async {
  final response = await http.post(
    Uri.parse('https://jsonplaceholder.typicode.com/albums'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'title': title,
    }),
  );

  if (response.statusCode == 201) {
    print("Created album, new title: $title");
  } else {
    throw Exception("Couldn't create album.");
  }
}

Future<void> deleteAlbum(String id) async {
  final http.Response response = await http.delete(
    Uri.parse('https://jsonplaceholder.typicode.com/albums/$id'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    print("deleted album : $id");
  } else {
    // If the server did not return a "200 OK response",
    // then throw an exception.
    throw Exception("Can't delete album.");
  }
}

class Album {
  final int userId;
  final int id;
  final String title;

  const Album({
    required this.userId,
    required this.id,
    required this.title,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'userId': int userId,
        'id': int id,
        'title': String title,
      } =>
        Album(
          userId: userId,
          id: id,
          title: title,
        ),
      _ => throw const FormatException('Failed to load data.'),
    };
  }
}

void main() {
  runApp(
    const MaterialApp(
      home: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final MaterialColor amberColor = _createMaterialColor(Colors.amber.withOpacity(0.8));

    return MaterialApp(
      title: 'DISPLAY ALBUMS',
      theme: ThemeData(
        primarySwatch: amberColor,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: amberColor, // Set primary color to amber
        ),
        textTheme: ThemeData.light().textTheme.copyWith(
          titleLarge: const TextStyle(
            fontWeight: FontWeight.bold, // Make the title text bold
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
  MaterialColor _createMaterialColor(Color color) {
    List<int> strengths = <int>[50, 100, 200, 300, 400, 500, 600, 700, 800, 900];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int strength in strengths) {
      final double weight = 1.0 - (strength / 900.0);
      swatch[strength] = Color.fromRGBO(
        r + ((255 - r) * weight).round(),
        g + ((255 - g) * weight).round(),
        b + ((255 - b) * weight).round(),
        1,
      );
    }

    return MaterialColor(color.value, swatch);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static late Future<List<Album>> futureAlbum;
  late Future<Album> deleted;

  @override
  void initState() {
    super.initState();
    futureAlbum = getAlbum();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
            bool albumCreated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddPage(),
              ),
            );
            if (albumCreated) {
            // If a new album is created, refresh the UI
            setState(() {
              futureAlbum = getAlbum();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('ALBUM DISPLAY'),
        backgroundColor: Colors.amber.shade400,
      ),
      body: Center(
        child: FutureBuilder<List<Album>>(
          future: futureAlbum,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  Album album = snapshot.data![index];
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.amber, width: 1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      title: Text(album.title),
                      subtitle: Text('ID: ${album.id}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, semanticLabel: 'Delete'),
                        onPressed: () {
                          deleteAlbum(album.id.toString());
                          setState(() {
                            futureAlbum = getAlbum();
                          });
                        },
                      ),
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}

class AddPage extends StatefulWidget {
  const AddPage({
    super.key,
  });

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final TextEditingController createNewAlb = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CREATE ALBUM'),
        backgroundColor: Colors.amber.shade400,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: createNewAlb,
              decoration: const InputDecoration(
                  labelText: 'Album name'),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      createAlbum(createNewAlb.text.toString());
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context, true);
                    },
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
