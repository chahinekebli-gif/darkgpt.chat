
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const backendUr ;

const modes = <String, String>{
  'normal': '🤖 DarkGPT AI',
  'deep': '🧠 Deep Thinking',
  'coding': '💻 Coding AI',
  'cybersecurity': '🛡️ Cybersecurity',
  'negative': '⚫ Dark Analysis',
};

const bg = Color(0xFF080A10);
const panel = Color(0xFF141824);
const blue = Color(0xFF3988FF);

void main() {
  runApp(const DarkGPTApp());
}

class DarkGPTApp extends StatelessWidget {
  const DarkGPTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: ChatPage(),
      ),
    );
  }
}

class Msg {
  final String text;
  final bool user;
  final bool error;

  Msg(this.text, {this.user = false, this.error = false});
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final messages = <Msg>[];

  String mode = 'normal';
  bool loading = false;

  Future<void> send() async {
    final text = input.text.trim();

    if (text.isEmpty || loading) return;

    if (backendUrl.contains('YOUR-BACKEND-URL')) {
      setState(() {
        messages.add(Msg(
          'يجب إعداد رابط الخادم أولاً داخل backendUrl.',
          error: true,
        ));
      });
      return;
    }

    final history = messages
        .where((m) => !m.error)
        .map((m) => {
              'role': m.user ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    input.clear();

    setState(() {
      messages.add(Msg(text, user: true));
      loading = true;
    });

    _scrollToBottom();

    try {
      final response = await http
          .post(
            Uri.parse(backendUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'message': text,
              'mode': mode,
              'history': history,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid server response');
      }

      final reply = (data['reply'] ??
              data['message'] ??
              data['response'] ??
              'لم يرجع الخادم إجابة.')
          .toString();

      if (mounted) {
        setState(() => messages.add(Msg(reply)));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.add(Msg(
            'تعذر الاتصال بخادم الذكاء الاصطناعي.\n'
            'تحقق من الرابط والإنترنت وإعدادات الخادم.',
            error: true,
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void newChat() {
    if (loading) return;
    setState(() {
      messages.clear();
      mode = 'normal';
    });
  }

  Widget bubble(Msg message) {
    final color = message.user
        ? const Color(0xFF173B72)
        : message.error
            ? const Color(0xFF421D28)
            : panel;

    return Align(
      alignment: message.user
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: message.user
                ? blue.withValues(alpha: 0.35)
                : Colors.white10,
          ),
        ),
        child: SelectableText(
          message.text,
          style: const TextStyle(fontSize: 15, height: 1.6),
        ),
      ),
    );
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'darkgpt.chat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              modes[mode]!,
              style: const TextStyle(
                fontSize: 11,
                color: blue,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'محادثة جديدة',
            onPressed: newChat,
            icon: const Icon(Icons.add_circle_outline),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune),
            onSelected: (value) => setState(() => mode = value),
            itemBuilder: (_) => [
              for (final entry in modes.entries)
                PopupMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt,
                          size: 64,
                          color: blue,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'مرحباً بك في DarkGPT',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اسأل، تعلّم، حلّل، أو اكتب كوداً.',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.all(14),
                    itemCount: messages.length + (loading ? 1 : 0),
                    itemBuilder: (_, index) {
                      if (index == messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: blue,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('DarkGPT يفكر...'),
                            ],
                          ),
                        );
                      }
                      return bubble(messages[index]);
                    },
                  ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: bg,
                border: Border(
                  top: BorderSide(color: Colors.white10),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 6,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => send(),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك...',
                        filled: true,
                        fillColor: panel,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: loading ? null : send,
                    style: IconButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_upward),
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
