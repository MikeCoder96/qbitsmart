import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'connectioninfo.dart';

class AddTorrentDialog extends StatefulWidget {
  final String cookie;
  final ConnectionInfo connectionInfo;
  final bool isAddingLocalFile;

  const AddTorrentDialog({
    required this.cookie,
    required this.connectionInfo,
    required this.isAddingLocalFile,
  });

  @override
  _AddTorrentDialogState createState() => _AddTorrentDialogState();
}

class _AddTorrentDialogState extends State<AddTorrentDialog> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _downloadSpeedController = TextEditingController();
  final TextEditingController _uploadSpeedController = TextEditingController();
  String _selectedCategory = 'default';
  bool _startAfterAdded = true;
  List<String> _categories = ['default'];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final url = '${widget.connectionInfo.useHttps ? 'https' : 'http'}://${widget.connectionInfo.ipAddress}:${widget.connectionInfo.port}${widget.connectionInfo.path}/api/v2/torrents/categories';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Cookie': 'SID=${widget.cookie}',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(json.decode(response.body));
      setState(() {
        _categories = data.keys.toList();
        _isLoadingCategories = false;
      });
    } else {
      setState(() {
        _isLoadingCategories = false;
      });
      _showErrorDialog('Failed to fetch categories: ${response.statusCode}');
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
        'category': _selectedCategory,
        'autoTMM': 'false',
        'dlLimit': (_downloadSpeedController.text.isNotEmpty ? (int.parse(_downloadSpeedController.text) * 1024).toString() : '0'), // Convert to bytes
        'upLimit': (_uploadSpeedController.text.isNotEmpty ? (int.parse(_uploadSpeedController.text) * 1024).toString() : '0'), // Convert to bytes
        'paused': (!_startAfterAdded).toString(),
      },
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop();
      _showSuccessDialog();
    } else {
      _showErrorDialog('Failed to add torrent from URL: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Torrent'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingCategories)
                Center(child: CircularProgressIndicator())
              else if (!widget.isAddingLocalFile) ...[
                Text('Add torrent from URL:'),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: 'Enter torrent URL',
                  ),
                ),
                SizedBox(height: 16),
                Text('Category:'),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  items: _categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Text('Maximum Download Speed (KB/s):'),
                TextFormField(
                  controller: _downloadSpeedController,
                  decoration: InputDecoration(
                    hintText: 'Enter max download speed',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                Text('Maximum Upload Speed (KB/s):'),
                TextFormField(
                  controller: _uploadSpeedController,
                  decoration: InputDecoration(
                    hintText: 'Enter max upload speed',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _startAfterAdded,
                      onChanged: (bool? value) {
                        setState(() {
                          _startAfterAdded = value!;
                        });
                      },
                    ),
                    Text('Start after added'),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addTorrentFromUrl,
                  child: Text('Add Torrent'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
              onPressed: () => Navigator.of(context).pop(),
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
}
