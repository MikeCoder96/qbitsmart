// main.dart

import 'dart:io';
import 'dart:async'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:qbitsmart/settings.dart';
import 'package:qbitsmart/torrent.dart';
import 'package:qbitsmart/torrentdetailspage.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_torrent_page.dart';
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
      ipAddress: '0.0.0.0',
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
      theme: ThemeData(
        brightness: Brightness.light,
        /* light theme settings */
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.dark,
      /* ThemeMode.system to follow system theme,
         ThemeMode.light for light theme,
         ThemeMode.dark for dark theme
      */
      debugShowCheckedModeBanner: false,
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
  String _selectedFilter = 'All';
  List<Torrent> _torrentList = [];
  Timer? _timer; // Declare a Timer

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      await loginToQBitTorrent(widget.connectionInfo);
      await getTorrentList(widget.connectionInfo);
    });

    // Initialize the timer to refresh every second
    _timer = Timer.periodic(Duration(seconds: 2), (Timer t) => getTorrentList(widget.connectionInfo));
  }


  List<Torrent> _filteredTorrentList(String filter){

    if (filter == "Active")
      return _torrentList
          .where((torrent) => torrent.state == "downloading" || torrent.state == "uploading")
          .toList();

    if (filter == "Downloading")
      return _torrentList
          .where((torrent) => (torrent.state == "downloading"))
          .toList();

    if (filter == "Paused")
      return _torrentList
          .where((torrent) => (torrent.state == "paused"))
          .toList();

    if (filter == "Seeding")
      return _torrentList
          .where((torrent) => (torrent.state == "uploading" || torrent.state == "queuedUP"|| torrent.state == "stalledUP"))
          .toList();

    if (filter == "Completed")
      return _torrentList
          .where((torrent) => (torrent.state == "completed" || torrent.state == "uploading" || torrent.state == "queuedUP"|| torrent.state == "stalledUP"))
          .toList();

    if (filter == "Errored")
      return _torrentList
          .where((torrent) => (torrent.state == "errored" || torrent.state == "missingFiles" || torrent.state == "unknown"))
          .toList();


    return _torrentList;

  }

  String formatDataUnit(int value, {bool isSpeed = false}) {
    double size = value.toDouble();
    final units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    String formattedValue = size.toStringAsFixed(2);
    String unit = units[unitIndex];

    if (isSpeed) {
      unit += '/s';
    }

    return '$formattedValue $unit';
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('qBitRemote'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Torrent App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            _createDrawerItem(icon: Icons.filter_list, text: 'All (${_filteredTorrentList("All").length})', onTap: () {
              setState(() {
                _selectedFilter = 'All';
              });
              Navigator.pop(context);
            },),
            _createDrawerItem(icon: Icons.flash_on, text: 'Active (${_filteredTorrentList("Active").length})', onTap: () {
              setState(() {
                _selectedFilter = 'Active';
              });
              Navigator.pop(context);
            },),
            _createDrawerItem(icon: Icons.download, text: 'Downloading (${_filteredTorrentList("Downloading").length})', onTap: () {
              setState(() {
                _selectedFilter = 'Downloading';
              });
              Navigator.pop(context);
            },),
            _createDrawerItem(icon: Icons.upload, text: 'Seeding (${_filteredTorrentList("Seeding").length})', onTap: () {
              setState(() {
                _selectedFilter = 'Seeding';
              });
              Navigator.pop(context);
            },),
            _createDrawerItem(icon: Icons.pause, text: 'Paused (${_filteredTorrentList("Paused").length})', onTap: () {
              setState(() {
                _selectedFilter = 'Paused';
              });
              Navigator.pop(context);
            },),
            _createDrawerItem(icon: Icons.check, text: 'Completed (${_filteredTorrentList("Completed").length})', onTap: () {
              setState(() {
                _selectedFilter = 'Completed';
              });
              Navigator.pop(context);
            },),
            _createDrawerItem(icon: Icons.error, text: 'Errored (${_filteredTorrentList("Errored").length})', onTap: () {
              setState(() {
                _selectedFilter = 'Errored';
              });
              Navigator.pop(context);
            },),

            Divider(),
            _createDrawerItem(icon: Icons.settings, text: 'Settings', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(connectionInfo: widget.connectionInfo)));
            }),
            _createDrawerItem(icon: Icons.help, text: 'Help'),
          ],
        ),
      ),
      body: Center(
        child: _torrentList.isEmpty
            ? CircularProgressIndicator()
            : ListView.builder(
          itemCount: _filteredTorrentList(_selectedFilter).length,
          itemBuilder: (BuildContext context, int index) {
            final torrent = _filteredTorrentList(_selectedFilter)[index];
            return GestureDetector(
                onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TorrentDetailsPage(
                    torrent: torrent,
                    connectionInfo: widget.connectionInfo,
                    cookie: _cookie,),
                ),
              );
            },
            child:Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            torrent.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (torrent.state == "downloading" || torrent.state == "uploading" || torrent.state == "queuedUP" || torrent.state == "queuedDL" || torrent.state == "stalledUP" || torrent.state == "stalledDL")
                              IconButton(
                                icon: Icon(Icons.pause, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () => pauseTorrent(torrent.hash),
                              ),
                            if (torrent.state == "pausedDL" || torrent.state == "pausedUP")
                              IconButton(
                                icon: Icon(Icons.play_arrow, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () => resumeTorrent(torrent.hash),
                              ),
                            IconButton(
                              icon: Icon(Icons.delete, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () => deleteTorrent(torrent.hash, true),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text('Size: ${formatDataUnit(torrent.size)} / ${formatDataUnit(torrent.completed)}'),
                    Text('Ratio: ${torrent.ratio.toStringAsFixed(2)}'),
                    SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '↑ ${formatDataUnit(torrent.uploadSpeed, isSpeed: true)}',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '↓ ${formatDataUnit(torrent.downloadSpeed, isSpeed: true)}',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            );
          },
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        children: [
          SpeedDialChild(
            child: Icon(Icons.link),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AddTorrentDialog(
                cookie: _cookie,
                connectionInfo: widget.connectionInfo,
                isAddingLocalFile: false,
              ),
            ),
          ),
          SpeedDialChild(
            child: Icon(Icons.file_open),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AddTorrentDialog(
                cookie: _cookie,
                connectionInfo: widget.connectionInfo,
                isAddingLocalFile: true,
              ),
            ),
          ),
        ],
      ),

    );
  }

  Future<void> pauseTorrent(String hash) async {
    final url = '${widget.connectionInfo.useHttps ? 'https' : 'http'}://${widget.connectionInfo.ipAddress}:${widget.connectionInfo.port}${widget.connectionInfo.path}/api/v2/torrents/pause';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Cookie': 'SID=$_cookie',
        },
        body: {
          'hashes': hash,
        },
      );

      if (response.statusCode != 200) {
        _showErrorDialog('Failed to pause torrent: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error pausing torrent: $e');
    }
  }

  Future<void> resumeTorrent(String hash) async {
    final url = '${widget.connectionInfo.useHttps ? 'https' : 'http'}://${widget.connectionInfo.ipAddress}:${widget.connectionInfo.port}${widget.connectionInfo.path}/api/v2/torrents/resume';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Cookie': 'SID=$_cookie',
        },
        body: {
          'hashes': hash,
        },
      );

      if (response.statusCode != 200) {
        _showErrorDialog('Failed to pause torrent: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error pausing torrent: $e');
    }
  }

  Future<void> deleteTorrent(String hash, bool deleteFiles) async {
    final url = '${widget.connectionInfo.useHttps ? 'https' : 'http'}://${widget.connectionInfo.ipAddress}:${widget.connectionInfo.port}${widget.connectionInfo.path}/api/v2/torrents/delete';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Cookie': 'SID=$_cookie',
        },
        body: {
          'hashes': hash,
          'deleteFiles': deleteFiles.toString(),
        },
      );

      if (response.statusCode != 200) {
        _showErrorDialog('Failed to delete torrent: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error deleting torrent: $e');
    }
  }

  Future<void> getTorrentList(ConnectionInfo connectionInfo) async {
    final url = '${connectionInfo.useHttps ? 'https' : 'http'}://${connectionInfo.ipAddress}:${connectionInfo.port}${connectionInfo.path}/api/v2/torrents/info';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cookie': 'SID=$_cookie',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _torrentList = data.map((json) => Torrent.fromJson(json)).toList();
        });
      } else {
        //_showErrorDialog('Failed to get torrent list: ${response.statusCode}');
      }
    } catch (e) {
      //_showErrorDialog('Error fetching torrent list: $e');
    }
  }

  Future<void> loginToQBitTorrent(ConnectionInfo connectionInfo) async {
    final url = '${connectionInfo.useHttps ? 'https' : 'http'}://${connectionInfo.ipAddress}:${connectionInfo.port}${connectionInfo.path}/api/v2/auth/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'username': connectionInfo.username,
          'password': connectionInfo.password,
        },
      );

      if (response.statusCode == 200) {
        final String? res = response.headers["set-cookie"];
        final String? SID = res?.substring(4, 36);
        setState(() {
          _cookie = SID ?? "";
        });
      } else {
        _showErrorDialog('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error logging in: $e');
    }
  }

  Widget _createDrawerItem(
      {required IconData icon, required String text, GestureTapCallback? onTap}) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Icon(icon),
          Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(text),
          )
        ],
      ),
      onTap: onTap,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
