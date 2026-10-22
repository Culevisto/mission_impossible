class HealthStatusModel {
  final bool isOnline;
  final String backend;
  final bool isSerialConnected;
  final String serialPort;
  final int baudRate;
  final bool isDryRun;
  final List<String> enabledServos;
  final String? errorMessage;

  const HealthStatusModel({
    this.isOnline = false,
    this.backend = 'Disconnected',
    this.isSerialConnected = false,
    this.serialPort = 'None',
    this.baudRate = 9600,
    this.isDryRun = false,
    this.enabledServos = const [],
    this.errorMessage,
  });

  factory HealthStatusModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String?;
    final isOnline = statusStr == 'online';
    final backend = json['backend'] as String? ?? 'Spring Boot 3';
    final serialConnected = (json['serial_connected'] ?? json['serialConnected']) as bool? ?? false;
    final serialPort = (json['serial_port'] ?? json['serialPort']) as String? ?? 'Disconnected';
    final baudRate = (json['baud_rate'] ?? json['baudRate']) as int? ?? 9600;
    final dryRun = (json['dry_run'] ?? json['dryRun']) as bool? ?? false;
    
    final rawServos = json['enabled_servos'] ?? json['enabledServos'];
    final List<String> servos = [];
    if (rawServos is List) {
      for (final item in rawServos) {
        if (item != null) servos.add(item.toString());
      }
    }

    return HealthStatusModel(
      isOnline: isOnline,
      backend: backend,
      isSerialConnected: serialConnected,
      serialPort: serialPort,
      baudRate: baudRate,
      isDryRun: dryRun,
      enabledServos: servos,
      errorMessage: null,
    );
  }

  factory HealthStatusModel.offline({String? message}) {
    return HealthStatusModel(
      isOnline: false,
      backend: 'Unreachable',
      isSerialConnected: false,
      serialPort: 'Unreachable',
      baudRate: 9600,
      isDryRun: false,
      enabledServos: const [],
      errorMessage: message ?? 'Cannot reach ARMAN backend server',
    );
  }
}
