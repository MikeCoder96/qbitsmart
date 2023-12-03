class ConnectionInfo {
  String serverTitle;
  String ipAddress;
  int port;
  String path;
  bool useHttps;
  bool trustSSL;
  String username;
  String password;

  ConnectionInfo({
    required this.serverTitle,
    required this.ipAddress,
    required this.port,
    required this.path,
    required this.useHttps,
    required this.trustSSL,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'serverTitle': serverTitle,
      'ipAddress': ipAddress,
      'port': port,
      'path': path,
      'useHttps': useHttps,
      'trustSSL': trustSSL,
      'username': username,
      'password': password,
    };
  }

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) {
    return ConnectionInfo(
      serverTitle: json['serverTitle'] as String,
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int,
      path: json['path'] as String,
      useHttps: json['useHttps'] as bool,
      trustSSL: json['trustSSL'] as bool,
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }
}
