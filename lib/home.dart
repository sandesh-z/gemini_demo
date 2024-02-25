import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gemini_demo/api_key/api_key.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _inputController = TextEditingController();
  bool _loading = false;
  final ScrollController _scrollController = ScrollController();

  late ChatSession _session;
  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  @override
  void initState() {
    _session = model.startChat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            children: [
              ..._session.history.map(
                (content) {
                  var text = content.parts
                      .whereType<TextPart>()
                      .map<String>((e) => e.text)
                      .join('');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        content.role == 'user' ? 'User:' : 'Gemini:',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      MarkdownBody(data: text),
                      const Divider(),
                      const SizedBox(height: 10.0),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your prompt',
                  ),
                  onEditingComplete: () {
                    if (!_loading) {
                      _sendMessage();
                    }
                  },
                ),
              ),
              _loading
                  ? const CircularProgressIndicator()
                  : IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send),
                    ),
            ],
          ),
        )
      ]),
    );
  }

  void _sendMessage() async {
    debugPrint(_inputController.text);
    setState(() {
      _loading = true;
    });
    try {
      final response =
          await _session.sendMessage(Content.text(_inputController.text));

      if (response.text == null) {
        _showError('No response from API');
      } else {
        setState(() {
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _inputController.clear();
      setState(() {
        _loading = false;
      });
    }
  }

  void _showError(String string) {
    debugPrint("Error: $string");
  }
}
