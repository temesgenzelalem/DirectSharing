import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/transfer_model.dart';
import 'database_service.dart';

class TransferService extends ChangeNotifier {
  final List<FileTransfer> transfers = [];
  final Map<String, List<ChatMessage>> chats = {};
  final Map<int, FileTransfer> _payloadToTransfer = {};
  final DatabaseService _db = DatabaseService();
  bool _loaded = false;

  Future<void> loadFromDB() async {
    if (_loaded) return;
    _loaded = true;
    final saved = await _db.getTransfers();
    transfers.addAll(saved);
    notifyListeners();
  }

  void onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.FILE) {
      // ignore: deprecated_member_use
      final fileLocation = payload.uri ?? payload.filePath;
      final transfer = FileTransfer(
        id: payload.id.toString(),
        fileName: p.basename(fileLocation ?? 'received_file'),
        fileSize: 0,
        filePath: fileLocation ?? '',
        peerName: endpointId,
        peerId: endpointId,
        direction: TransferDirection.receiving,
        status: TransferStatus.transferring,
      );
      _payloadToTransfer[payload.id] = transfer;
      transfers.insert(0, transfer);
      _db.saveTransfer(transfer);
      notifyListeners();
    } else if (payload.type == PayloadType.BYTES) {
      final msg = String.fromCharCodes(payload.bytes!);
      _addMessage(endpointId, endpointId, msg, false);
    }
  }

  void onPayloadTransferUpdate(
      String endpointId, PayloadTransferUpdate update) {
    final transfer = _payloadToTransfer[update.id];
    if (transfer == null) return;
    transfer.bytesTransferred = update.bytesTransferred;
    final elapsed =
        DateTime.now().difference(transfer.startTime).inMilliseconds;
    if (elapsed > 0) {
      transfer.speedBytesPerSec = (update.bytesTransferred / elapsed) * 1000;
    }
    if (update.status == PayloadStatus.SUCCESS) {
      transfer.status = TransferStatus.completed;
      transfer.endTime = DateTime.now();
      _db.updateTransferStatus(
          transfer.id, 'completed', transfer.bytesTransferred);
    } else if (update.status == PayloadStatus.FAILURE) {
      transfer.status = TransferStatus.failed;
      _db.updateTransferStatus(
          transfer.id, 'failed', transfer.bytesTransferred);
    }
    notifyListeners();
  }

  Future<void> sendFile(
      String endpointId, String filePath, String peerName) async {
    final file = File(filePath);
    final fileName = p.basename(filePath);
    final fileSize = await file.length();
    final transfer = FileTransfer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      fileSize: fileSize,
      filePath: filePath,
      peerName: peerName,
      peerId: endpointId,
      direction: TransferDirection.sending,
      status: TransferStatus.transferring,
    );
    transfers.insert(0, transfer);
    await _db.saveTransfer(transfer);
    notifyListeners();
    try {
      final payloadId = await Nearby().sendFilePayload(endpointId, filePath);
      _payloadToTransfer[payloadId] = transfer;
      await _db.saveKnownDevice(endpointId, peerName);
    } catch (e) {
      transfer.status = TransferStatus.failed;
      await _db.updateTransferStatus(transfer.id, 'failed', 0);
      notifyListeners();
    }
  }

  Future<void> sendMessage(
      String endpointId, String peerName, String message) async {
    _addMessage(endpointId, peerName, message, true);
    try {
      final bytes = Uint8List.fromList(message.codeUnits);
      await Nearby().sendBytesPayload(endpointId, bytes);
    } catch (_) {}
  }

  void _addMessage(
      String peerId, String peerName, String text, bool isMe) async {
    chats[peerId] ??= [];
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderId: peerId,
      isMe: isMe,
    );
    chats[peerId]!.add(msg);
    await _db.saveMessage(msg, peerId, peerName);
    notifyListeners();
  }

  Future<void> loadMessages(String peerId) async {
    final saved = await _db.getMessages(peerId);
    chats[peerId] = saved;
    notifyListeners();
  }

  List<ChatMessage> getMessages(String peerId) => chats[peerId] ?? [];

  Future<String> getDownloadPath() async {
    final dir = await getExternalStorageDirectory();
    final path = '${dir!.path}/DirectShare';
    await Directory(path).create(recursive: true);
    return path;
  }

  Future<void> clearHistory() async {
    transfers.removeWhere((t) => t.status != TransferStatus.transferring);
    await _db.clearTransfers();
    notifyListeners();
  }
}
