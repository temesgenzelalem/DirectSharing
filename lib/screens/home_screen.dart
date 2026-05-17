import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nearby_service.dart';
import '../services/transfer_service.dart';
import 'send_screen.dart';
import 'receive_screen.dart';
import 'transfers_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final svc = context.read<NearbyService>();
      await svc.init();
      await svc.requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomePage(),
      const TransfersScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFF080C18),
          indicatorColor: const Color(0xFF00E5FF).withOpacity(0.15),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF00E5FF)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_outlined),
              selectedIcon: Icon(Icons.swap_horiz, color: Color(0xFF00E5FF)),
              label: 'Transfers',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat, color: Color(0xFF00E5FF)),
              label: 'Chats',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF00E5FF)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final nearby = context.watch<NearbyService>();
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with profile photo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('DirectShare',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(width: 8, height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Faster than Xender',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                    ]),
                  ]),
                  // Profile photo avatar
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/profile.png',
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            color: const Color(0xFF141C2E),
                            child: Center(
                              child: Text(
                                nearby.myName.isNotEmpty ? nearby.myName[0].toUpperCase() : 'D',
                                style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Hero speed card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.bolt, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text('Ultra Fast Transfer',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  Text('Up to 200 MB/s via WiFi Direct\nShare files up to 5GB+ offline',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.5)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _Badge(label: 'No Internet', icon: Icons.wifi_off),
                    const SizedBox(width: 8),
                    _Badge(label: 'No Limit', icon: Icons.all_inclusive),
                    const SizedBox(width: 8),
                    _Badge(label: 'Free', icon: Icons.money_off),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),

              // Actions
              const Text('Quick Actions',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _ActionCard(
                  icon: Icons.upload_rounded, label: 'Send',
                  sublabel: 'Share files\nup to 5GB',
                  color: const Color(0xFF00E5FF),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendScreen())),
                )),
                const SizedBox(width: 14),
                Expanded(child: _ActionCard(
                  icon: Icons.download_rounded, label: 'Receive',
                  sublabel: 'Accept files\nfrom nearby',
                  color: const Color(0xFF7C4DFF),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiveScreen())),
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _ActionCard(
                  icon: Icons.folder_open_rounded, label: 'My Files',
                  sublabel: 'Browse received\nfiles',
                  color: const Color(0xFFFF6D00),
                  onTap: () {},
                )),
                const SizedBox(width: 14),
                Expanded(child: _ActionCard(
                  icon: Icons.settings_outlined, label: 'Settings',
                  sublabel: 'Configure\nthe app',
                  color: const Color(0xFF00C853),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                )),
              ]),
              const SizedBox(height: 24),

              // Stats
              const Text('Performance',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _StatCard(value: '200 MB/s', label: 'Max Speed', icon: Icons.speed)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(value: '5 GB+', label: 'Max File Size', icon: Icons.storage)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(value: '200m', label: 'Range', icon: Icons.radar)),
              ]),
              const SizedBox(height: 24),

              // File types
              const Text('Share by Type',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FileType(icon: Icons.video_file, label: 'Video', color: const Color(0xFF7C4DFF)),
                  _FileType(icon: Icons.image, label: 'Photo', color: const Color(0xFF00C853)),
                  _FileType(icon: Icons.audio_file, label: 'Music', color: const Color(0xFF00B4D8)),
                  _FileType(icon: Icons.folder_zip, label: 'Apps', color: const Color(0xFFFF6D00)),
                  _FileType(icon: Icons.description, label: 'Docs', color: const Color(0xFF1565C0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Badge({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: Colors.white),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.sublabel, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2E),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(sublabel, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, height: 1.4)),
      ]),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatCard({required this.value, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF141C2E),
      border: Border.all(color: const Color(0xFF1E2840)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(children: [
      Icon(icon, color: const Color(0xFF00E5FF), size: 22),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10), textAlign: TextAlign.center),
    ]),
  );
}

class _FileType extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FileType({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 52, height: 52,
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: color, size: 26),
    ),
    const SizedBox(height: 6),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
  ]);
}

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final nearby = context.watch<NearbyService>();
    final connected = nearby.devices.where((d) => d.isConnected).toList();
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1E),
      appBar: AppBar(title: const Text('Chats'), backgroundColor: const Color(0xFF080C18)),
      body: connected.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text('No connected devices', style: TextStyle(color: Colors.white.withOpacity(0.4))),
              const SizedBox(height: 8),
              Text('Connect to a device first to chat',
                  style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12)),
            ]))
          : ListView.builder(
              itemCount: connected.length,
              itemBuilder: (ctx, i) {
                final d = connected[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
                    child: Text(d.name[0].toUpperCase(),
                        style: const TextStyle(color: Color(0xFF00E5FF))),
                  ),
                  title: Text(d.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('Connected via WiFi Direct',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ChatScreen(peerId: d.id, peerName: d.name))),
                );
              },
            ),
    );
  }
}
