// add_torrent_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'connectioninfo.dart';

class AddTorrentPage extends StatefulWidget {
  final String cookie;
  final ConnectionInfo connectionInfo;

  const AddTorrentPage({required this.cookie, required this.connectionInfo});

  @override
  _AddTorrentPageState createState() => _AddTorrentPageState();
}

class _AddTorrentPageState extends State<AddTorrentPage> {
  final TextEditingController _urlController = TextEditingController();

  Future<void> _addTorrentFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['torrent'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final url = '${widget.connectionInfo.useHttps ? 'https' : 'http'}://${widget.connectionInfo.ipAddress}:${widget.connectionInfo.port}${widget.connectionInfo.path}/api/v2/torrents/add';

      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['autoTMM'] = 'false'
        ..fields['cookie'] = widget.cookie
        ..files.add(await http.MultipartFile.fromPath('torrents', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to add torrent from file: ${response.statusCode}');
      }
    }
  }

  Future<void> _addTorrentFromUrl() async {
    final url = '${widget.connectionInfo.useHttps ? 'https' : 'http'}://${widget.connectionInfo.ipAddress}:${widget.connectionInfo.port}${widget.connectionInfo.path}/api/v2/torrents/add';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Cookie': 'SID=${widget.cookie}',
      },
      body: {
        'urls': _urlController.text,
      },
    );

    if (response.statusCode == 200) {
      _showSuccessDialog();
    } else {
      _showErrorDialog('Failed to add torrent from URL: ${response.statusCode}');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Torrent added successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the Add Torrent Page
              },
              child: Text('OK'),
            ),
          ],
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Torrent'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add torrent from URL:'),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Enter torrent URL',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addTorrentFromUrl,
              child: Text('Add from URL'),
            ),
            SizedBox(height: 32),
            Text('Add torrent from file:'),
            ElevatedButton(
              onPressed: _addTorrentFromFile,
              child: Text('Select File'),
            ),
          ],
        ),
      ),
    );
  }
}
