import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http';

const backendUrl = 'https://YOUR-BACKEND-URL/chat';

const modes = {
  'normal': '🤖 مساعد عام',
  'deep': '🧠 تفكير عميق',
  'coding': '💻 مساعد برمجة',
  'security': '🛡️ أمن المعلومات (دفاعي)',
};

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
      ),
      builder: (c, w) =>
          Directionality(textDirection: TextDirection.rtl, child: w!),
      home: const ChatPage(),
    ));

class Msg {
  final String text;
  final bool user, error;
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
  final msgs = <Msg>[];
  String mode = 'normal';
  bool loading = false;

  void scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || loading) return;

    final history = msgs
        .where((m) => !m.error)
        .map((m) => {'role': m.user ? 'user' : 'assistant', 'content': m.text})
        .toList();

    input.clear();
    setState(() {
      msgs.add(Msg(text, user: true));
      loading = true;
    });
    scrollDown();

    try {
      final r = await http
          .post(
            Uri.parse(backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': text, 'mode': mode, 'history': history}),
          )
          .timeout(const Duration(seconds: 90));

      if (r.statusCode ~/ 100 != 2) throw Exception(r.statusCode);

      final d = jsonDecode(utf8.decode(r.bodyBytes));
      final a = (d['reply'] ?? d['message'] ?? d['response'] ?? 'لم يرجع الخادم إجابة.')
          .toString();
      if (mounted) setState(() => msgs.add(Msg(a)));
    } catch (_) {
      if (mounted) {
        setState(() => msgs.add(
            Msg('تعذر الاتصال بالخادم. تأكد من الرابط.', error: true)));
      }
    } finally {
      if (mounted) setState(() => loading = false);
      scrollDown();
    }
  }

  Widget bubble(Msg m) => Align(
        alignment:
            m.user ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .85),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: m.user
                ? const Color(0xFF2F6FED)
                : m.error
                    ? const Color(0xFF3A1A1F)
                    : const Color(0xFF161B26),
          ),
          child: SelectableText(m.text,
              style: const TextStyle(fontSize: 16, height: 1.5)),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1F2B),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SmartChat',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(modes[mode]!,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'محادثة جديدة',
              icon: const Icon(Icons.add),
              onPressed: () => setState(() {
                msgs.clear();
                mode = 'normal';
              }),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.tune),
              onSelected: (v) => setState(() => mode = v),
              itemBuilder: (_) => [
                for (final e in modes.entries)
                  PopupMenuItem(value: e.key, child: Text(e.value)),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.all(14),
                itemCount: msgs.length + (loading ? 1 : 0),
                itemBuilder: (_, i) => i == msgs.length
                    ? const Padding(
                        padding: EdgeInsets.all(12), child: Text('AI يفكر...'))
                    : bubble(msgs[i]),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        minLines: 1,
                        maxLines: 6,
                        onSubmitted: (_) => send(),
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالتك...',
                          filled: true,
                          fillColor: const Color(0xFF161B26),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Color(0xFF2F6FED)),
                      onPressed: loading ? null : send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}