import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../services/transfer_service.dart';
import '../models/transfer_model.dart';
import '../utils/file_utils.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});
  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransferService>().loadFromDB();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transfers = context.watch<TransferService>().transfers;
    final active = transfers.where((t) => t.status == TransferStatus.transferring).toList();
    final done = transfers.where((t) => t.status != TransferStatus.transferring).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1E),
      appBar: AppBar(
        title: const Text('Transfers'),
        backgroundColor: const Color(0xFF080C18),
        actions: [
          if (done.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                await context.read<TransferService>().clearHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History cleared'), backgroundColor: Color(0xFF00C853)),
                  );
                }
              },
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: transfers.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.swap_horiz, size: 64, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 16),
              Text('No transfers yet', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
              const SizedBox(height: 8),
              Text('Send or receive files to see them here',
                  style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12)),
            ]))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (active.isNotEmpty) ...[
                  const _SectionHeader(title: 'Active'),
                  ...active.map((t) => _TransferCard(transfer: t)),
                  const SizedBox(height: 8),
                ],
                if (done.isNotEmpty) ...[
                  const _SectionHeader(title: 'History'),
                  ...done.map((t) => _TransferCard(transfer: t)),
                ],
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 10),
    child: Text(title.toUpperCase(),
        style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
  );
}

class _TransferCard extends StatelessWidget {
  final FileTransfer transfer;
  const _TransferCard({required this.transfer});

  Color get _statusColor {
    switch (transfer.status) {
      case TransferStatus.completed: return const Color(0xFF00C853);
      case TransferStatus.failed: return const Color(0xFFE53935);
      case TransferStatus.cancelled: return Colors.orange;
      default: return const Color(0xFF00E5FF);
    }
  }

  String get _statusText {
    switch (transfer.status) {
      case TransferStatus.completed: return 'Done';
      case TransferStatus.failed: return 'Failed';
      case TransferStatus.cancelled: return 'Cancelled';
      case TransferStatus.transferring:
        return transfer.direction == TransferDirection.sending ? 'Sending...' : 'Receiving...';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = transfer.status == TransferStatus.transferring;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2E),
        border: Border.all(color: isActive ? _statusColor.withOpacity(0.4) : const Color(0xFF1E2840)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FileUtils.getFileColor(transfer.fileName).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(FileUtils.getFileIcon(transfer.fileName),
                color: FileUtils.getFileColor(transfer.fileName), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(transfer.fileName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Row(children: [
              Icon(transfer.direction == TransferDirection.sending
                  ? Icons.upload_rounded : Icons.download_rounded,
                  size: 12, color: Colors.white38),
              const SizedBox(width: 4),
              Text('${transfer.direction == TransferDirection.sending ? "To" : "From"}: ${transfer.peerName}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(_statusText,
                  style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 4),
            Text(transfer.fileSizeString, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ]),
        if (isActive) ...[
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${transfer.transferredString} / ${transfer.fileSizeString}',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            Text(transfer.speedString,
                style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.w600)),
            Text(transfer.remainingTime, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            percent: transfer.progress.clamp(0.0, 1.0),
            lineHeight: 6,
            backgroundColor: const Color(0xFF1E2840),
            progressColor: transfer.direction == TransferDirection.sending
                ? const Color(0xFF00E5FF) : const Color(0xFF7C4DFF),
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 6),
          Text('${(transfer.progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ] else if (transfer.status == TransferStatus.completed) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00C853), size: 14),
            const SizedBox(width: 6),
            Text('Saved to DirectShare folder',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero),
              child: const Text('Open', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
            ),
          ]),
        ],
      ]),
    );
  }
}
