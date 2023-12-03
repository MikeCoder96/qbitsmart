import 'dart:ffi';

class Torrent {
  String hash;
  String name;
  int size;
  int progress;
  int priority;
  String category;
  String state;
  int downloadSpeed;
  int uploadSpeed;
  int numSeeds;
  int numComplete;
  int numLeechs;
  int numIncomplete;
  int completed;
  double ratio;
  int eta;
  String savePath;
  int addedOn;
  int completionOn;
  String tags;

  Torrent({
    required this.hash,
    required this.name,
    required this.size,
    required this.progress,
    required this.priority,
    required this.category,
    required this.state,
    required this.completed,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.numSeeds,
    required this.numComplete,
    required this.numLeechs,
    required this.numIncomplete,
    required this.ratio,
    required this.eta,
    required this.savePath,
    required this.addedOn,
    required this.completionOn,
    required this.tags,
  });

  factory Torrent.fromJson(Map<String, dynamic> json) {
    return Torrent(
      hash: json['hash'] as String,
      name: json['name'] as String,
      size: json['size'] as int,
      progress: json['progress'] as int,
      priority: json['priority'] as int,
      completed: json['completed'] as int,
      category: json['category'] as String,
      state: json['state'] as String,
      downloadSpeed: json['dlspeed'] as int,
      uploadSpeed: json['upspeed'] as int,
      numSeeds: json['num_seeds'] as int,
      numComplete: json['num_complete'] as int,
      numLeechs: json['num_leechs'] as int,
      numIncomplete: json['num_incomplete'] as int,
      ratio: double.parse(json["ratio"].toString()),
      eta: json['eta'] as int,
      savePath: json['save_path'] as String,
      addedOn: json['added_on'] as int,
      completionOn: json['completion_on'] as int,
      tags: json['tags'] as String,
    );
  }
}
