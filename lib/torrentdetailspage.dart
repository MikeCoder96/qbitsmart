import 'package:flutter/material.dart';
import 'package:qbitsmart/torrent.dart';


class TorrentDetailsPage extends StatelessWidget {
  final Torrent torrent;

  TorrentDetailsPage({required this.torrent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(torrent.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTorrentInfoCard(),
            SizedBox(height: 16),
            _buildFilesList(),
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
              torrent.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildInfoRow('Size', '${(torrent.size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GiB'),
            _buildInfoRow('Progress', '${torrent.progress * 100}%'),
            _buildInfoRow('Ratio', torrent.ratio.toStringAsFixed(2)),
            _buildInfoRow('State', torrent.state),
            _buildInfoRow('Leeches', torrent.numLeechs.toString()),
            _buildInfoRow('Seeds', torrent.numSeeds.toString()),
            _buildInfoRow('Priority', torrent.priority.toString()),
            _buildInfoRow('Download Speed', '${(torrent.downloadSpeed / (1024 * 1024)).toStringAsFixed(2)} MiB/s'),
            _buildInfoRow('Upload Speed', '${(torrent.uploadSpeed / (1024 * 1024)).toStringAsFixed(2)} MiB/s'),
            _buildInfoRow('ETA', _formatEta(torrent.eta)),
            _buildInfoRow('Added on', _formatTimestamp(torrent.addedOn)),
            _buildInfoRow('Completed on', _formatTimestamp(torrent.completionOn)),
            _buildInfoRow('Category', torrent.category),
            _buildInfoRow('Torrent Hash', torrent.hash),
            SizedBox(height: 16),
            _buildCheckbox('Download in sequential order', false),
            _buildCheckbox('Download first and last piece first', false),
          ],
        ),
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
    // Mock files data
    final files = [
      {'name': 'data1.doi', 'size': 63.7, 'progress': 1.0},
      {'name': 'data2.doi', 'size': 316.9, 'progress': 1.0},
      {'name': 'English.doi', 'size': 1.4, 'progress': 1.0},
      {'name': 'French.doi', 'size': 1.4, 'progress': 1.0},
    ];

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
        ...files.map((file) => _buildFileItem(file)).toList(),
      ],
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file) {
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
              Text('${file['size']} GiB'),
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: file['progress'],
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
}
