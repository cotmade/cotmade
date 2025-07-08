import 'package:flutter/material.dart';
import 'package:cotmade/view/ai/cotmind_conversation_engine.dart';

class CotmindChatPage extends StatefulWidget {
  const CotmindChatPage({Key? key}) : super(key: key);

  @override
  State<CotmindChatPage> createState() => _CotmindChatPageState();
}

class _CotmindChatPageState extends State<CotmindChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': input});
      _controller.clear();
      _isLoading = true;
    });

    final CotmindResponse reply =
        await CotmindConversationEngine.respond(input);

    setState(() {
      // Add Cotmind's main reply message
      _messages.add({'role': 'cotmind', 'text': reply.message});

      // Add each video as its own message with role 'video'
      for (var video in reply.videos) {
        _messages.add({'role': 'video', 'text': video});
      }

      _isLoading = false;
    });

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
    _messages.clear();
    super.dispose();
  }

  Widget _buildMessage(Map<String, String> msg) {
    final role = msg['role'];
    final text = msg['text'] ?? '';

    if (role == 'video') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(10),
          ),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
          child: Row(
            children: [
              Icon(Icons.video_library, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
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
          color: isUser ? Colors.grey[200] : Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (ctx, i) => _buildMessage(_messages[i]),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: CircularProgressIndicator(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: "ask me anything regarding booking",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
