import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qbitsmart/settings.dart';
import 'package:qbitsmart/torrent.dart';
import 'package:qbitsmart/torrentdetailspage.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'connectioninfo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final connectionInfo = await loadConnectionInfo();

  runApp(MyApp(connectionInfo: connectionInfo));
}

Future<ConnectionInfo> loadConnectionInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('connectionInfo');
  if (jsonString != null) {
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return ConnectionInfo.fromJson(jsonMap);
  } else {
    return ConnectionInfo(
      serverTitle: 'My qBittorrent Server',
      ipAddress: '192.168.1.1',
      port: 8080,
      path: '/qb',
      useHttps: false,
      trustSSL: true,
      username: 'your_username',
      password: 'your_password',
    );
  }
}

Future<void> saveConnectionInfo(ConnectionInfo connectionInfo) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = json.encode(connectionInfo.toJson());
  await prefs.setString('connectionInfo', jsonString);
}

class MyApp extends StatelessWidget {
  final ConnectionInfo connectionInfo;

  const MyApp({required this.connectionInfo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(connectionInfo: connectionInfo),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final ConnectionInfo connectionInfo;

  const MyHomePage({required this.connectionInfo});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _cookie = '';
  List<Torrent> _torrentList = [];

  @override
  void initState()
  {
    super.initState();
    Future.delayed(Duration.zero,() async {
      loginToQBitTorrent(widget.connectionInfo);
    });
  }

  @override
  Widget build(BuildContext context) {
    getTorrentList(widget.connectionInfo);
    return Scaffold(
      appBar: AppBar(
        title: Text('qBitRemote'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Connected to: ${widget.connectionInfo.serverTitle}',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              title: Text('Downloads'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // You can navigate to the downloads page or any other page here
              },
            ),
            ListTile(
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(connectionInfo: widget.connectionInfo),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _torrentList.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TorrentDetailsPage(torrent: _torrentList[index]),
                        ),
                      );
                    },
                    child: Card(
                      child: ListTile(
                        title: Text(_torrentList[index].name),
                        subtitle: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_torrentList[index].category}'),
                            Text('${(_torrentList[index].size /1024 / 1024/ 1024).toStringAsFixed(2)} GB / ${(_torrentList[index].completed / 1024 / 1024/ 1024).toStringAsFixed(2)} GB'),
                            Text('Progress: ${_torrentList[index].progress * 100}% (Ratio: ${_torrentList[index].ratio.toStringAsFixed(2)})')
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            //index = (index + 1) % customizations.length;
          });
        },
        //foregroundColor: customizations[index].$1,
        //backgroundColor: customizations[index].$2,
        //shape: customizations[index].$3,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> getTorrentList(ConnectionInfo connectionInfo) async {
    final url = '${connectionInfo.useHttps ? 'https' : 'http'}://${connectionInfo.ipAddress}:${connectionInfo.port}${connectionInfo.path}/api/v2/torrents/info';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Cookie': 'SID=${_cookie}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      setState(() {
        _torrentList = data.map((json) => Torrent.fromJson(json)).toList();
      });

      print('Torrent List: $_torrentList');
    } else {
      print('Failed to get torrent list: ${response.statusCode}');
    }
  }

  Future<void> loginToQBitTorrent(ConnectionInfo connectionInfo) async {
    loadConnectionInfo();

    final url = '${connectionInfo.useHttps ? 'https' : 'http'}://${connectionInfo.ipAddress}:${connectionInfo.port}${connectionInfo.path}/api/v2/auth/login';

    final response = await http.post(
      Uri.parse(url),
      body: {
        'username': connectionInfo.username,
        'password': connectionInfo.password,
      },
    );

    if (response.statusCode == 200) {
      final String? res = response.headers["set-cookie"];
      final String? SID = res?.substring(4,36);
      print('tmp Cookie: $res, $SID');
      setState(() {
        _cookie = SID ?? "";
      });

      print('Login successful, Cookie: $_cookie');
    } else {
      print('Login failed: ${response.statusCode}');
    }
  }
}
