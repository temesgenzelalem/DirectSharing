import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum DeviceStatus { idle, advertising, discovering, connected }

class DiscoveredDevice {
  final String id;
  final String name;
  bool isConnected;
  bool isConnecting;
  DiscoveredDevice({required this.id, required this.name, this.isConnected = false, this.isConnecting = false});
}

class NearbyService extends ChangeNotifier {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  String _myName = 'My Device';
  String get myName => _myName;
  DeviceStatus status = DeviceStatus.idle;
  List<DiscoveredDevice> devices = [];
  List<String> connectedEndpoints = [];
  String? lastError;

  Function(String endpointId, dynamic payload)? onPayloadReceived;
  Function(String endpointId, dynamic update)? onPayloadTransferUpdate;

  Future<void> init() async {
    try {
      final info = DeviceInfoPlugin();
      final android = await info.androidInfo;
      _myName = android.model;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
      Permission.storage,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<void> startAdvertising() async {
    try {
      status = DeviceStatus.advertising;
      notifyListeners();
      await Nearby().startAdvertising(
        _myName, strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: 'com.directshare.app',
      );
    } catch (e) {
      lastError = e.toString();
      status = DeviceStatus.idle;
      notifyListeners();
    }
  }

  Future<void> startDiscovery() async {
    try {
      status = DeviceStatus.discovering;
      devices.clear();
      notifyListeners();
      await Nearby().startDiscovery(
        _myName, strategy,
        onEndpointFound: (id, name, serviceId) {
          if (!devices.any((d) => d.id == id)) {
            devices.add(DiscoveredDevice(id: id, name: name));
            notifyListeners();
          }
        },
        onEndpointLost: (id) {
          devices.removeWhere((d) => d.id == id);
          notifyListeners();
        },
        serviceId: 'com.directshare.app',
      );
    } catch (e) {
      lastError = e.toString();
      status = DeviceStatus.idle;
      notifyListeners();
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) => onPayloadReceived?.call(endpointId, payload),
      onPayloadTransferUpdate: (endpointId, update) => onPayloadTransferUpdate?.call(endpointId, update),
    );
  }

  void _onConnectionResult(String id, Status s) {
    if (s == Status.CONNECTED) {
      connectedEndpoints.add(id);
      final idx = devices.indexWhere((d) => d.id == id);
      if (idx >= 0) {
        devices[idx].isConnected = true;
        devices[idx].isConnecting = false;
      }
      status = DeviceStatus.connected;
      notifyListeners();
    }
  }

  void _onDisconnected(String id) {
    connectedEndpoints.remove(id);
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx >= 0) devices[idx].isConnected = false;
    if (connectedEndpoints.isEmpty) status = DeviceStatus.idle;
    notifyListeners();
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    try {
      device.isConnecting = true;
      notifyListeners();
      await Nearby().requestConnection(
        _myName, device.id,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      device.isConnecting = false;
      lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendBytes(String endpointId, String message) async {
    final bytes = Uint8List.fromList(message.codeUnits);
    await Nearby().sendBytesPayload(endpointId, bytes);
  }

  Future<void> stopAll() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
    status = DeviceStatus.idle;
    connectedEndpoints.clear();
    devices.clear();
    notifyListeners();
  }
}
