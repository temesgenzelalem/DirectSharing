import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/transfer_service.dart';
import '../models/transfer_model.dart';
import '../utils/file_utils.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  const ChatScreen({super.key, required this.peerId, required this.peerName});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<TransferService>().loadMessages(widget.peerId);
      _scrollToBottom();
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<TransferService>().sendMessage(widget.peerId, widget.peerName, text);
    _controller.clear();
    _scrollToBottom();
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    final transfer = context.read<TransferService>();
    for (final file in result.files) {
      if (file.path != null) {
        await transfer.sendFile(widget.peerId, file.path!, widget.peerName);
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sending ${result.files.length} file(s)...'),
          backgroundColor: const Color(0xFF00C853),
        ),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<TransferService>().getMessages(widget.peerId);
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080C18),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
            child: Text(widget.peerName[0].toUpperCase(),
                style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.peerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const Text('● Connected via WiFi Direct',
                style: TextStyle(fontSize: 10, color: Color(0xFF00C853))),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.attach_file), onPressed: _sendFile, tooltip: 'Send File'),
        ],
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
          color: const Color(0xFF080C18),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_outline, size: 12, color: Color(0xFF00C853)),
            const SizedBox(width: 6),
            Text('End-to-end encrypted · No internet · Saved locally',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ]),
        ),
        Expanded(
          child: messages.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 12),
                  Text('No messages yet', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                  const SizedBox(height: 6),
                  Text('Send a message or share a file',
                      style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
                ]))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) => _MessageBubble(message: messages[i]),
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: const Color(0xFF080C18),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.white54),
              onPressed: _sendFile,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2540),
                  border: Border.all(color: const Color(0xFF1E2840)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 42, height: 42,
                decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: message.isFile
                  ? const EdgeInsets.all(12)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF1565C0) : const Color(0xFF1E2D50),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: message.isFile
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(FileUtils.getFileIcon(message.fileName ?? ''),
                          color: FileUtils.getFileColor(message.fileName ?? ''), size: 28),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(message.fileName ?? 'File',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        const Text('Tap to open', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      ]),
                    ])
                  : Text(message.text,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
            ),
            const SizedBox(height: 3),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(Icons.done_all, size: 12, color: Color(0xFF00E5FF)),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}
