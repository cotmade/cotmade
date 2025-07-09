import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cotmade/view/ai/cotmind_conversation_engine.dart';

class CotmindChatPage extends StatefulWidget {
  const CotmindChatPage({Key? key}) : super(key: key);

  @override
  State<CotmindChatPage> createState() => _CotmindChatPageState();
}

class _CotmindChatPageState extends State<CotmindChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  String _thinkingText = 'Thinking';
  Timer? _thinkingTimer;

  @override
  void initState() {
    super.initState();
    _autoGreet();
  }

  Future<void> _showTypewriterEffect(String fullText) async {
    final index = _messages
        .indexWhere((msg) => msg['role'] == 'cotmind' && msg['text'] == '');
    if (index == -1) return;

    for (int i = 1; i <= fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;

      setState(() {
        _messages[index]['text'] = fullText.substring(0, i);
      });
    }
  }

  void _autoGreet() async {
    final res = await CotmindConversationEngine.respond('');
    setState(() => _messages.add({'role': 'cotmind', 'text': res.message}));
  }

  void _startThinking() {
    int dots = 0;
    _thinkingTimer?.cancel();
    _thinkingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      dots = (dots + 1) % 4;
      setState(() => _thinkingText = 'Thinking${'.' * dots}');
    });
  }

  void _stopThinking() {
    _thinkingTimer?.cancel();
    setState(() => _thinkingText = 'Thinking');
  }

  void _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': input});
      _controller.clear();
      _isLoading = true;
    });

    _startThinking();
    final reply = await CotmindConversationEngine.respond(input);
    _stopThinking();

    setState(() {
      // Add cotmind message with empty text to prepare for typewriter effect
      _messages.add({'role': 'cotmind', 'text': ''});
      for (var v in reply.videos) {
        _messages.add({'role': 'video', 'text': v});
      }
      _isLoading = false;
    });

    if (reply.typewriter) {
      await _showTypewriterEffect(reply.message);
    } else {
      // If no typewriter effect, just fill message immediately
      final idx = _messages
          .indexWhere((msg) => msg['role'] == 'cotmind' && msg['text'] == '');
      if (idx != -1) {
        setState(() {
          _messages[idx]['text'] = reply.message;
        });
      }
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _thinkingTimer?.cancel();
    super.dispose();
  }

  Widget _buildMessage(Map<String, String> msg) {
    final role = msg['role'], text = msg['text']!;
    if (role == 'video') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.video_library, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        ),
      );
    }

    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.grey : Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.black : Colors.green),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat with Cotmind")),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (ctx, i) => _buildMessage(_messages[i]),
          ),
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_thinkingText,
                style: const TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.grey)),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: "Ask me anything",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send)),
            ]),
          ),
        ),
      ]),
    );
  }
}
