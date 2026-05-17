enum TransferStatus { pending, transferring, completed, failed, cancelled }
enum TransferDirection { sending, receiving }

class FileTransfer {
  final String id;
  final String fileName;
  final int fileSize;
  final String filePath;
  final String peerName;
  final String peerId;
  final TransferDirection direction;
  TransferStatus status;
  int bytesTransferred;
  double speedBytesPerSec;
  DateTime startTime;
  DateTime? endTime;

  FileTransfer({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.filePath,
    required this.peerName,
    required this.peerId,
    required this.direction,
    this.status = TransferStatus.pending,
    this.bytesTransferred = 0,
    this.speedBytesPerSec = 0,
    DateTime? startTime,
    this.endTime,
  }) : startTime = startTime ?? DateTime.now();

  double get progress => fileSize > 0 ? bytesTransferred / fileSize : 0;

  String get speedString {
    if (speedBytesPerSec < 1024) return '${speedBytesPerSec.toStringAsFixed(0)} B/s';
    if (speedBytesPerSec < 1048576) return '${(speedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    if (speedBytesPerSec < 1073741824) return '${(speedBytesPerSec / 1048576).toStringAsFixed(1)} MB/s';
    return '${(speedBytesPerSec / 1073741824).toStringAsFixed(2)} GB/s';
  }

  String get fileSizeString => _formatBytes(fileSize);
  String get transferredString => _formatBytes(bytesTransferred);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  String get remainingTime {
    if (speedBytesPerSec <= 0) return '--';
    final remaining = fileSize - bytesTransferred;
    final secs = (remaining / speedBytesPerSec).round();
    if (secs < 60) return '${secs}s left';
    if (secs < 3600) return '${(secs / 60).round()}m left';
    return '${(secs / 3600).toStringAsFixed(1)}h left';
  }
}

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final bool isMe;
  final DateTime time;
  final String? filePath;
  final String? fileName;
  final bool isFile;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.isMe,
    DateTime? time,
    this.filePath,
    this.fileName,
    this.isFile = false,
  }) : time = time ?? DateTime.now();
}
