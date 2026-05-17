import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nearby_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nearby = context.watch<NearbyService>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1E),
      appBar: AppBar(title: const Text('Settings'), backgroundColor: const Color(0xFF080C18)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: 'Device', children: [
            _Tile(icon: Icons.smartphone, label: 'Device Name', value: nearby.myName),
            _Tile(icon: Icons.wifi_tethering, label: 'Transfer Mode', value: 'WiFi Direct (Fastest)'),
            _Tile(icon: Icons.speed, label: 'Max Speed', value: '200 MB/s'),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Transfer', children: [
            _ToggleTile(icon: Icons.auto_awesome, label: 'Auto Accept Files', initial: false),
            _ToggleTile(icon: Icons.compress, label: 'Compress Before Send', initial: false),
            _ToggleTile(icon: Icons.lock, label: 'Encrypt Transfers', initial: true),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Storage', children: [
            _Tile(icon: Icons.folder, label: 'Save Location', value: '/DirectShare'),
            _Tile(icon: Icons.storage, label: 'Max File Size', value: 'Unlimited (5GB+)'),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'About', children: [
            _Tile(icon: Icons.info_outline, label: 'Version', value: '1.0.0'),
            _Tile(icon: Icons.bolt, label: 'Technology', value: 'WiFi Direct P2P'),
            _Tile(icon: Icons.code, label: 'Open Source', value: 'Yes'),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141C2E),
          border: Border.all(color: const Color(0xFF1E2840)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: children),
      ),
    ]);
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

class _ToggleTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool initial;
  const _ToggleTile({required this.icon, required this.label, required this.initial});

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  late bool _value;
  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(widget.icon, color: const Color(0xFF00E5FF), size: 20),
      title: Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      activeColor: const Color(0xFF00E5FF),
    );
  }
}
