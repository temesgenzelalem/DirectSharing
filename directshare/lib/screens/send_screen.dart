import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/nearby_service.dart';
import '../services/transfer_service.dart';
import '../utils/file_utils.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});
  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  List<PlatformFile> _selectedFiles = [];
  bool _isScanning = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withReadStream: true);
    if (result != null) setState(() => _selectedFiles = result.files);
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    final svc = context.read<NearbyService>();
    await svc.startAdvertising();
    await svc.startDiscovery();
    await Future.delayed(const Duration(seconds: 5));
    setState(() => _isScanning = false);
  }

  Future<void> _sendTo(String endpointId, String peerName) async {
    final transfer = context.read<TransferService>();
    for (final file in _selectedFiles) {
      if (file.path != null) {
        await transfer.sendFile(endpointId, file.path!, peerName);
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sending ${_selectedFiles.length} file(s) to $peerName'), backgroundColor: const Color(0xFF00C853)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nearby = context.watch<NearbyService>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1E),
      appBar: AppBar(
        title: const Text('Send Files'),
        backgroundColor: const Color(0xFF080C18),
        actions: [
          if (_selectedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text('${_selectedFiles.length} file(s)', style: const TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // File picker section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141C2E),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (_selectedFiles.isEmpty) ...[
                  const Icon(Icons.upload_file, size: 48, color: Color(0xFF00E5FF)),
                  const SizedBox(height: 12),
                  const Text('Select files to share', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Any file type · Up to 5GB+ · Super fast', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  const SizedBox(height: 16),
                ] else ...[
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedFiles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, i) {
                        final file = _selectedFiles[i];
                        return Container(
                          width: 100,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B0F1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(FileUtils.getFileIcon(file.name), color: FileUtils.getFileColor(file.name), size: 32),
                            const SizedBox(height: 6),
                            Text(file.name, style: const TextStyle(color: Colors.white, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            Text(FileUtils.formatBytes(file.size), style: const TextStyle(color: Colors.white38, fontSize: 9)),
                          ]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(_selectedFiles.isEmpty ? 'Choose Files' : 'Add More Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          // Scan button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: _isScanning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.radar),
              label: Text(_isScanning ? 'Scanning for devices...' : 'Scan for Nearby Devices'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2540),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Devices list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Text('NEARBY DEVICES', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(width: 8),
              if (_isScanning) const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF00E5FF))),
            ]),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: nearby.devices.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.devices, size: 56, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 12),
                    Text('No devices found yet', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                    const SizedBox(height: 6),
                    Text('Tap "Scan" to find nearby devices', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: nearby.devices.length,
                    itemBuilder: (ctx, i) {
                      final device = nearby.devices[i];
                      return _DeviceCard(
                        name: device.name,
                        isConnected: device.isConnected,
                        isConnecting: device.isConnecting,
                        onConnect: () => context.read<NearbyService>().connectToDevice(device),
                        onSend: _selectedFiles.isEmpty
                            ? null
                            : () => _sendTo(device.id, device.name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String name;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onConnect;
  final VoidCallback? onSend;

  const _DeviceCard({required this.name, required this.isConnected, required this.isConnecting, required this.onConnect, this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2E),
        border: Border.all(color: isConnected ? const Color(0xFF00C853).withOpacity(0.5) : const Color(0xFF1E2840)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF00E5FF).withOpacity(0.15),
          child: Text(name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(isConnected ? '● Connected via WiFi Direct' : 'WiFi Direct · Tap to connect',
              style: TextStyle(color: isConnected ? const Color(0xFF00C853) : Colors.white38, fontSize: 11)),
        ])),
        if (isConnecting)
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)))
        else if (isConnected && onSend != null)
          ElevatedButton.icon(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )
        else if (!isConnected)
          OutlinedButton(
            onPressed: onConnect,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00E5FF),
              side: const BorderSide(color: Color(0xFF00E5FF)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Connect', style: TextStyle(fontSize: 12)),
          ),
      ]),
    );
  }
}
