import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiPromptsManager extends StatefulWidget {
  const AiPromptsManager({super.key});

  @override
  State<AiPromptsManager> createState() => _AiPromptsManagerState();
}

class _AiPromptsManagerState extends State<AiPromptsManager> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Key-value pairs for prompts. Using a simple static list for the most critical ones.
  final List<String> _promptKeys = [
    'explain_verse_explain',
    'explain_verse_context',
    'explain_verse_keyWord',
    'explain_verse_crossRefs',
    'explain_verse_application',
    'chat_verse',
    'chat_general',
  ];

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _activeStates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    for (var key in _promptKeys) {
      _controllers[key] = TextEditingController();
      _activeStates[key] = false;
    }
    _loadPrompts();
  }

  Future<void> _loadPrompts() async {
    setState(() => _isLoading = true);
    try {
      for (var key in _promptKeys) {
        final doc = await _firestore.collection('ai_prompts').doc(key).get();
        if (doc.exists) {
          final data = doc.data()!;
          _controllers[key]!.text = data['systemPrompt'] ?? '';
          _activeStates[key] = data['isActive'] ?? false;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading prompts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrompt(String key) async {
    try {
      await _firestore.collection('ai_prompts').doc(key).set({
        'systemPrompt': _controllers[key]!.text.trim(),
        'isActive': _activeStates[key],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved $key successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save $key: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI System Prompts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrompts,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _promptKeys.length,
        itemBuilder: (context, index) {
          final key = _promptKeys[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Switch(
                        value: _activeStates[key] ?? false,
                        onChanged: (val) {
                          setState(() {
                            _activeStates[key] = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controllers[key],
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'Enter system prompt here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _savePrompt(key),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Prompt'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
