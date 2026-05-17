import 'package:flutter/material.dart';

class SpeedIndicator extends StatefulWidget {
  final double speedMBps;
  const SpeedIndicator({super.key, required this.speedMBps});
  @override
  State<SpeedIndicator> createState() => _SpeedIndicatorState();
}

class _SpeedIndicatorState extends State<SpeedIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: widget.speedMBps / 200)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(SpeedIndicator old) {
    super.didUpdateWidget(old);
    _anim = Tween<double>(begin: _anim.value, end: widget.speedMBps / 200)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) => Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Transfer Speed', style: TextStyle(color: Colors.white54, fontSize: 12)),
          Text('${widget.speedMBps.toStringAsFixed(1)} MB/s',
              style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _anim.value.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFF1E2840),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.speedMBps > 100
                  ? const Color(0xFF00C853)
                  : widget.speedMBps > 50 ? const Color(0xFF00E5FF) : const Color(0xFFFF8F00),
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('0', style: TextStyle(color: Colors.white24, fontSize: 9)),
          Text('100 MB/s', style: TextStyle(color: Colors.white24, fontSize: 9)),
          Text('200 MB/s', style: TextStyle(color: Colors.white24, fontSize: 9)),
        ]),
      ]),
    );
  }
}
