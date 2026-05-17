import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transfer_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'directshare.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        peer_id TEXT NOT NULL,
        peer_name TEXT NOT NULL,
        text TEXT NOT NULL,
        is_me INTEGER NOT NULL DEFAULT 0,
        timestamp INTEGER NOT NULL,
        is_file INTEGER NOT NULL DEFAULT 0,
        file_name TEXT,
        file_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transfers (
        id TEXT PRIMARY KEY,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        peer_name TEXT NOT NULL,
        peer_id TEXT NOT NULL,
        direction TEXT NOT NULL,
        status TEXT NOT NULL,
        bytes_transferred INTEGER DEFAULT 0,
        speed_bytes_per_sec REAL DEFAULT 0,
        start_time INTEGER NOT NULL,
        end_time INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE known_devices (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        last_seen INTEGER NOT NULL,
        times_connected INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ── MESSAGES ──────────────────────────────────────
  Future<void> saveMessage(ChatMessage msg, String peerId, String peerName) async {
    final db = await database;
    await db.insert('messages', {
      'id': msg.id,
      'peer_id': peerId,
      'peer_name': peerName,
      'text': msg.text,
      'is_me': msg.isMe ? 1 : 0,
      'timestamp': msg.time.millisecondsSinceEpoch,
      'is_file': msg.isFile ? 1 : 0,
      'file_name': msg.fileName,
      'file_path': msg.filePath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatMessage>> getMessages(String peerId) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'peer_id = ?',
      whereArgs: [peerId],
      orderBy: 'timestamp ASC',
    );
    return rows.map((r) => ChatMessage(
      id: r['id'] as String,
      text: r['text'] as String,
      senderId: r['peer_id'] as String,
      isMe: (r['is_me'] as int) == 1,
      time: DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int),
      isFile: (r['is_file'] as int) == 1,
      fileName: r['file_name'] as String?,
      filePath: r['file_path'] as String?,
    )).toList();
  }

  Future<void> deleteMessages(String peerId) async {
    final db = await database;
    await db.delete('messages', where: 'peer_id = ?', whereArgs: [peerId]);
  }

  Future<List<Map<String, dynamic>>> getRecentChats() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT peer_id, peer_name, text, timestamp, is_me
      FROM messages
      WHERE id IN (
        SELECT id FROM messages m2
        WHERE m2.peer_id = messages.peer_id
        ORDER BY timestamp DESC LIMIT 1
      )
      GROUP BY peer_id
      ORDER BY timestamp DESC
    ''');
  }

  // ── TRANSFERS ──────────────────────────────────────
  Future<void> saveTransfer(FileTransfer t) async {
    final db = await database;
    await db.insert('transfers', {
      'id': t.id,
      'file_name': t.fileName,
      'file_size': t.fileSize,
      'file_path': t.filePath,
      'peer_name': t.peerName,
      'peer_id': t.peerId,
      'direction': t.direction.name,
      'status': t.status.name,
      'bytes_transferred': t.bytesTransferred,
      'speed_bytes_per_sec': t.speedBytesPerSec,
      'start_time': t.startTime.millisecondsSinceEpoch,
      'end_time': t.endTime?.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTransferStatus(String id, String status, int bytesTransferred) async {
    final db = await database;
    await db.update('transfers', {
      'status': status,
      'bytes_transferred': bytesTransferred,
      'end_time': DateTime.now().millisecondsSinceEpoch,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FileTransfer>> getTransfers() async {
    final db = await database;
    final rows = await db.query('transfers', orderBy: 'start_time DESC', limit: 100);
    return rows.map((r) => FileTransfer(
      id: r['id'] as String,
      fileName: r['file_name'] as String,
      fileSize: r['file_size'] as int,
      filePath: r['file_path'] as String,
      peerName: r['peer_name'] as String,
      peerId: r['peer_id'] as String,
      direction: TransferDirection.values.firstWhere((d) => d.name == r['direction']),
      status: TransferStatus.values.firstWhere((s) => s.name == r['status']),
      bytesTransferred: r['bytes_transferred'] as int,
      speedBytesPerSec: r['speed_bytes_per_sec'] as double,
      startTime: DateTime.fromMillisecondsSinceEpoch(r['start_time'] as int),
      endTime: r['end_time'] != null ? DateTime.fromMillisecondsSinceEpoch(r['end_time'] as int) : null,
    )).toList();
  }

  Future<void> clearTransfers() async {
    final db = await database;
    await db.delete('transfers');
  }

  // ── KNOWN DEVICES ──────────────────────────────────────
  Future<void> saveKnownDevice(String id, String name) async {
    final db = await database;
    final existing = await db.query('known_devices', where: 'id = ?', whereArgs: [id]);
    if (existing.isNotEmpty) {
      await db.update('known_devices', {
        'last_seen': DateTime.now().millisecondsSinceEpoch,
        'times_connected': (existing.first['times_connected'] as int) + 1,
      }, where: 'id = ?', whereArgs: [id]);
    } else {
      await db.insert('known_devices', {
        'id': id,
        'name': name,
        'last_seen': DateTime.now().millisecondsSinceEpoch,
        'times_connected': 1,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getKnownDevices() async {
    final db = await database;
    return await db.query('known_devices', orderBy: 'last_seen DESC', limit: 50);
  }

  // ── SETTINGS ──────────────────────────────────────
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    return rows.isNotEmpty ? rows.first['value'] as String : null;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
