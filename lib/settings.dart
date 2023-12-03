import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connectioninfo.dart';

class SettingsPage extends StatefulWidget {
  final ConnectionInfo connectionInfo;

  const SettingsPage({required this.connectionInfo});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController _serverTitleController = TextEditingController();
  TextEditingController _ipAddressController = TextEditingController();
  TextEditingController _portController = TextEditingController();
  TextEditingController _pathController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _useHttps = false;
  bool _trustSSL = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('connectionInfo');
    if (jsonString != null) {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      final connectionInfo = ConnectionInfo.fromJson(jsonMap);
      setState(() {
        _serverTitleController.text = connectionInfo.serverTitle;
        _ipAddressController.text = connectionInfo.ipAddress;
        _portController.text = connectionInfo.port.toString();
        _pathController.text = connectionInfo.path;
        _useHttps = connectionInfo.useHttps;
        _trustSSL = connectionInfo.trustSSL;
        _usernameController.text = connectionInfo.username;
        _passwordController.text = connectionInfo.password;
      });
    }
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final connectionInfo = ConnectionInfo(
      serverTitle: _serverTitleController.text,
      ipAddress: _ipAddressController.text,
      port: int.tryParse(_portController.text) ?? 0,
      path: _pathController.text,
      useHttps: _useHttps,
      trustSSL: _trustSSL,
      username: _usernameController.text,
      password: _passwordController.text,
    );
    final jsonString = json.encode(connectionInfo.toJson());
    await prefs.setString('connectionInfo', jsonString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _serverTitleController,
              decoration: InputDecoration(labelText: 'Server Title'),
            ),
            TextFormField(
              controller: _ipAddressController,
              decoration: InputDecoration(labelText: 'IP Address'),
            ),
            TextFormField(
              controller: _portController,
              decoration: InputDecoration(labelText: 'Port'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _pathController,
              decoration: InputDecoration(labelText: 'Path'),
            ),
            Row(
              children: [
                Text('Use HTTPS'),
                Checkbox(
                  value: _useHttps,
                  onChanged: (value) {
                    setState(() {
                      _useHttps = value ?? false;
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                Text('Trust SSL'),
                Checkbox(
                  value: _trustSSL,
                  onChanged: (value) {
                    setState(() {
                      _trustSSL = value ?? true;
                    });
                  },
                ),
              ],
            ),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await saveSettings();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}