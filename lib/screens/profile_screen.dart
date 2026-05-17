import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/nearby_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _totalSent = 0;
  int _totalReceived = 0;
  int _totalDevices = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = DatabaseService();
    final transfers = await db.getTransfers();
    final devices = await db.getKnownDevices();
    setState(() {
      _totalSent = transfers.where((t) => t.direction.name == 'sending').length;
      _totalReceived = transfers.where((t) => t.direction.name == 'receiving').length;
      _totalDevices = devices.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nearby = context.watch<NearbyService>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1E),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF080C18),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              color: const Color(0xFF080C18),
              child: Column(children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00E5FF), width: 2.5),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/profile.png',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        color: const Color(0xFF141C2E),
                        child: const Icon(Icons.person, color: Color(0xFF00E5FF), size: 50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(nearby.myName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF00E5FF).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: const Text('DirectShare User', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: _StatCard(value: '$_totalSent', label: 'Files Sent', icon: Icons.upload_rounded, color: const Color(0xFF00E5FF))),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(value: '$_totalReceived', label: 'Received', icon: Icons.download_rounded, color: const Color(0xFF7C4DFF))),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(value: '$_totalDevices', label: 'Devices', icon: Icons.devices, color: const Color(0xFF00C853))),
              ]),
            ),
            const SizedBox(height: 20),
            _Section(title: 'Device Info', children: [
              _Tile(icon: Icons.smartphone, label: 'Device Name', value: nearby.myName),
              _Tile(icon: Icons.wifi_tethering, label: 'Transfer Mode', value: 'WiFi Direct'),
              _Tile(icon: Icons.speed, label: 'Max Speed', value: '200 MB/s'),
              _Tile(icon: Icons.radar, label: 'Range', value: 'Up to 200m'),
            ]),
            const SizedBox(height: 16),
            _Section(title: 'App Info', children: [
              _Tile(icon: Icons.info_outline, label: 'Version', value: '1.0.0'),
              _Tile(icon: Icons.bolt, label: 'Technology', value: 'WiFi Direct P2P'),
              _Tile(icon: Icons.storage, label: 'Database', value: 'SQLite (local)'),
              _Tile(icon: Icons.lock_outline, label: 'Encryption', value: 'End-to-end'),
            ]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await DatabaseService().clearTransfers();
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transfer history cleared'), backgroundColor: Color(0xFF00C853)),
                  );
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear Transfer History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A0A0A),
                  foregroundColor: const Color(0xFFEF5350),
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF141C2E), border: Border.all(color: const Color(0xFF1E2840)), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        ),
        Container(
          decoration: BoxDecoration(color: const Color(0xFF141C2E), border: Border.all(color: const Color(0xFF1E2840)), borderRadius: BorderRadius.circular(14)),
          child: Column(children: children),
        ),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Tile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Text(value, style: const TextStyle(color: Colors.white38, fontSize: 12)),
    );
  }
}
