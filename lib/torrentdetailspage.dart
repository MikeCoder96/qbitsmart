import 'package:flutter/material.dart';
import 'package:qbitsmart/torrent.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'connectioninfo.dart';

class TorrentDetailsPage extends StatefulWidget {
  final Torrent torrent;
  final String cookie;
  final ConnectionInfo connectionInfo;

  TorrentDetailsPage({required this.torrent, required this.cookie, required this.connectionInfo});

  @override
  _TorrentDetailsPageState createState() => _TorrentDetailsPageState();
}

class _TorrentDetailsPageState extends State<TorrentDetailsPage> {
  late Torrent _torrent;
  List<dynamic> _files = [];
  bool _isLoadingFiles = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _torrent = widget.torrent;
    _fetchFiles();
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateTorrentDetails();
      _fetchFiles();
    });
  }

  Future<void> _updateTorrentDetails() async {
    final url = '${widget.connectionInfo.useHttps ? 'https' : 'http'}://${widget.connectionInfo.ipAddress}:${widget.connectionInfo.port}${widget.connectionInfo.path}/api/v2/torrents/properties?hash=${_torrent.hash}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cookie': 'SID=${widget.cookie}',
        },
      );

      if (response.statusCode == 200) {
        final updatedTorrent = jsonDecode(response.body);
        //print('Updated torrent: ${updatedTorrent.toString()}');
        setState(() {
          _torrent.uploadSpeed = updatedTorrent["up_speed"];
          _torrent.downloadSpeed = updatedTorrent["dl_speed"];
          _torrent.numSeeds = updatedTorrent["seeds"];
          _torrent.ratio = updatedTorrent["share_ratio"];
        });
      } else {
        print('Error updating torrent: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating torrent: ${e}');
    }
  }

  Future<void> _fetchFiles() async {
    final url = '${widget.connectionInfo.useHttps ? 'https' : 'http'}://${widget.connectionInfo.ipAddress}:${widget.connectionInfo.port}${widget.connectionInfo.path}/api/v2/torrents/files?hash=${widget.torrent.hash}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cookie': 'SID=${widget.cookie}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _files = json.decode(response.body);
          _isLoadingFiles = false;
        });
      } else {
        setState(() {
          _isLoadingFiles = false;
        });
        _showErrorDialog('Failed to fetch files: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingFiles = false;
      });
      _showErrorDialog('Failed to fetch files: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_torrent.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTorrentInfoCard(),
            SizedBox(height: 16),
            _isLoadingFiles ? CircularProgressIndicator() : _buildFilesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTorrentInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _torrent.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildInfoRow('Size', '${(_torrent.size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GiB'),
            _buildProgressBar('Progress', double.parse(_torrent.progress)),
            _buildInfoRow('Ratio', _torrent.ratio.toStringAsFixed(2)),
            _buildInfoRow('State', _torrent.state),
            _buildInfoRow('Leeches', _torrent.numLeechs.toString()),
            _buildInfoRow('Seeds', _torrent.numSeeds.toString()),
            _buildInfoRow('Priority', _torrent.priority.toString()),
            _buildInfoRow('Download Speed', '${formatDataUnit(_torrent.downloadSpeed, isSpeed: true)}'),
            _buildInfoRow('Upload Speed', '${formatDataUnit(_torrent.uploadSpeed, isSpeed: true)}'),
            _buildInfoRow('ETA', _formatEta(_torrent.eta)),
            _buildInfoRow('Added on', _formatTimestamp(_torrent.addedOn)),
            _buildInfoRow('Completed on', _formatTimestamp(_torrent.completionOn)),
            _buildInfoRow('Category', _torrent.category),
            _buildInfoRow('Torrent Hash', _torrent.hash),
            SizedBox(height: 16),
            _buildCheckbox('Download in sequential order', false),
            _buildCheckbox('Download first and last piece first', false),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${(value * 100).toStringAsFixed(2)}%',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (newValue) {},
        ),
        Text(label),
      ],
    );
  }

  Widget _buildFilesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Files',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ..._files.map((file) => _buildFileItem(file)).toList(),
      ],
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file) {
    double progressValue = (file['progress'] is int)
        ? file['progress'].toDouble()
        : file['progress'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(file['name']),
              SizedBox(height: 4),
              Text('${formatDataUnit(file["size"])}'),
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey[200],
                color: Colors.blue,
              ),
              SizedBox(height: 4),
              Text('${(file['progress'] * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
      ),
    );
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

  String _formatEta(int eta) {
    if (eta == 0) return '∞';
    final duration = Duration(seconds: eta);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$hours h $minutes m $seconds s';
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
