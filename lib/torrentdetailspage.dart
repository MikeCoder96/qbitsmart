import 'package:flutter/material.dart';
import 'package:qbitsmart/torrent.dart';

class TorrentDetailsPage extends StatefulWidget {
  final Torrent torrent;

  TorrentDetailsPage({required this.torrent});

  @override
  _TorrentDetailsPageState createState() => _TorrentDetailsPageState();
}

class _TorrentDetailsPageState extends State<TorrentDetailsPage> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0; // Indice iniziale
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Torrent Details'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          tabs: [
            Tab(text: 'Info'),
            Tab(text: 'Downloaded Files'),
            Tab(text: 'Trackers'),
            Tab(text: 'Peers'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TorrentInfoWidget(torrent: widget.torrent),
          DownloadFilesWidget(torrent: widget.torrent),
          TrackersWidget(torrent: widget.torrent),
          PeersWidget(torrent: widget.torrent),
        ],
      ),
    );
  }
}

class TorrentInfoWidget extends StatelessWidget {
  final Torrent torrent;

  TorrentInfoWidget({required this.torrent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Info for ${torrent.name}'),
    );
  }
}

class DownloadFilesWidget extends StatelessWidget {
  final Torrent torrent;

  DownloadFilesWidget({required this.torrent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Downloaded Files for ${torrent.name}'),
    );
  }
}

class TrackersWidget extends StatelessWidget {
  final Torrent torrent;

  TrackersWidget({required this.torrent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Trackers for ${torrent.name}'),
    );
  }
}

class PeersWidget extends StatelessWidget {
  final Torrent torrent;

  PeersWidget({required this.torrent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Peers for ${torrent.name}'),
    );
  }
}