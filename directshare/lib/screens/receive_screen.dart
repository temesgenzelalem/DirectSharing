import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nearby_service.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});
  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  bool _isAdvertising = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _toggleReceive() async {
    final svc = context.read<NearbyService>();
    if (_isAdvertising) {
      await svc.stopAll();
      setState(() => _isAdvertising = false);
    } else {
      await svc.startAdvertising();
      setState(() => _isAdvertising = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nearby = context.watch<NearbyService>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1E),
      appBar: AppBar(title: const Text('Receive Files'), backgroundColor: const Color(0xFF080C18)),
      body: Column(children: [
        const SizedBox(height: 30),
        // Radar animation
        AnimatedBuilder(
          animation: _pulse,
          builder: (ctx, child) {
            return Stack(alignment: Alignment.center, children: [
              if (_isAdvertising) ...[
                Opacity(
                  opacity: (1 - _pulse.value).clamp(0.0, 1.0),
                  child: Container(
                    width: 200 + _pulse.value * 60,
                    height: 200 + _pulse.value * 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.4), width: 2),
                    ),
                  ),
                ),
                Opacity(
                  opacity: ((1 - _pulse.value) * 0.6).clamp(0.0, 1.0),
                  child: Container(
                    width: 160 + _pulse.value * 60,
                    height: 160 + _pulse.value * 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3), width: 1.5),
                    ),
                  ),
                ),
              ],
              GestureDetector(
                onTap: _toggleReceive,
                child: Container(
                  width: 150, height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAdvertising
                        ? const Color(0xFF7C4DFF).withOpacity(0.2)
                        : const Color(0xFF141C2E),
                    border: Border.all(
                      color: _isAdvertising ? const Color(0xFF7C4DFF) : const Color(0xFF1E2840),
                      width: 2,
                    ),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.download_rounded,
                        size: 48, color: _isAdvertising ? const Color(0xFF7C4DFF) : Colors.white38),
                    const SizedBox(height: 8),
                    Text(_isAdvertising ? 'RECEIVING' : 'TAP TO\nRECEIVE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isAdvertising ? const Color(0xFF7C4DFF) : Colors.white38,
                          fontSize: 12, fontWeight: FontWeight.bold,
                        )),
                  ]),
                ),
              ),
            ]);
          },
        ),
        const SizedBox(height: 24),
        Text(
          _isAdvertising ? 'Waiting for files...' : 'Tap the button to start receiving',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          _isAdvertising ? 'Device is visible to nearby senders' : 'Your device will be visible to nearby devices',
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
        ),
        const SizedBox(height: 32),

        // My device info
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141C2E),
            border: Border.all(color: const Color(0xFF1E2840)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF7C4DFF).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.smartphone, color: Color(0xFF7C4DFF)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nearby.myName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('This device · WiFi Direct', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isAdvertising ? const Color(0xFF00C853).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_isAdvertising ? '● Visible' : '○ Hidden',
                  style: TextStyle(color: _isAdvertising ? const Color(0xFF00C853) : Colors.white38, fontSize: 12)),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Connected senders
        if (nearby.connectedEndpoints.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Text('CONNECTED SENDERS', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF00C853).withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text('${nearby.connectedEndpoints.length}', style: const TextStyle(color: Color(0xFF00C853), fontSize: 11)),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: nearby.connectedEndpoints.length,
              itemBuilder: (ctx, i) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141C2E),
                  border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Icon(Icons.send_rounded, color: Color(0xFF00C853), size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(nearby.connectedEndpoints[i], style: const TextStyle(color: Colors.white))),
                  const Text('Sending...', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
