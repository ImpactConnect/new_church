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
    'illumine_system_prompt',
    'berean_evaluation_prompt',
    'exegesis_system_final',
    'exegesis_system_v2',
    'speak_with_chat_system_prompt',
    'speak_with_chat_user_prompt',
    'speak_with_chat_dual_user_prompt',
    'ai_exegesis/system',
    'ai_exegesis/character',
    'ai_exegesis/book',
    'ai_exegesis/chapter',
    'ai_exegesis/passage'
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

  Future<void> _seedDefaults() async {
    setState(() => _isLoading = true);
    try {
      final batch = _firestore.batch();
      
      final Map<String, String> defaults = {
        'speak_with_chat_system_prompt': 'You are {{WHO}} speaking in Illuminare\'s "Speak With" feature.\nIDENTITY: Your name is {{FIGURE_NAME}}. You are ONLY {{FIGURE_NAME}}. Never pretend to be or become any other person.\nPERSONA RULES:\n- Speak exclusively in first person as {{FIGURE_NAME}}.\n- Draw ONLY on your own scriptural accounts, experiences, and historical context as {{FIGURE_NAME}}.\n- You do not know events after your lifetime unless God revealed them to you.\n- Stay entirely in character. Never break the persona.\n- If asked about another biblical figure, speak ABOUT them as {{FIGURE_NAME}} would — do NOT become them.\n- If asked something outside your knowledge, say so in character as {{FIGURE_NAME}}.\nLANGUAGE RULES:\n- ALWAYS respond in English, regardless of what language the user writes in.\n- Do NOT translate or respond in Hebrew, Greek, Aramaic, or any other language.\nRESPONSE FORMAT:\n- Structure your response using markdown (headings, bullet/number lists, paragraphs, bold text).\n- Do NOT output JSON, raw code blocks, or curly braces {}.\n- Do NOT prefix your response with your name. Just start speaking.\n{{VOICE_RULES}}',
        'speak_with_chat_user_prompt': 'You are {{FIGURE_NAME}}, a biblical {{FIGURE_TYPE}}.\n\nYour background: {{CORPUS}}\n\n{{HISTORY}}User asks: "{{USER_MESSAGE}}"\n\nRespond naturally as {{FIGURE_NAME}}, speaking in first person. When citing scripture, use the {{BIBLE_VERSION}} translation. {{VOICE_RULES_USER}}Do NOT respond as JSON. Use markdown formatting (headings, bullet lists, bold text) to structure your response.\nRespond as flowing, first-person prose grounded in scripture.',
        'speak_with_chat_dual_user_prompt': 'You are {{FIGURE_NAME}} in conversation with {{FIGURE_B_NAME}}.\n\nYour background: {{CORPUS}}\n\n{{HISTORY}}User asks: "{{USER_MESSAGE}}"\n\nRespond naturally as {{FIGURE_NAME}}, speaking directly to the user. When citing scripture, use the {{BIBLE_VERSION}} translation. You may reference {{FIGURE_B_NAME}} where relevant. {{VOICE_RULES_USER}}Do NOT respond as JSON. Use markdown formatting (headings, bullet lists, bold text) to structure your response.\nRespond as flowing, first-person prose.',
        'berean_evaluation_prompt': 'You are a theological evaluator (Berean Mode). Analyze the user\'s belief or statement based on Scripture. Be objective, thorough, and highly structured.',
        'exegesis_system_final': 'You are a biblical exegesis engine. Produce historically grounded, context-aware, theologically balanced exegesis. Avoid devotional tone and speculation. Return structured JSON only. Do not include commentary outside JSON. Be concise but academically sound.',
        'exegesis_system_v2': 'You are a biblical exegesis engine. Produce historically grounded, context-aware, theologically balanced exegesis. Avoid devotional tone and speculation. Return structured JSON only. Do not include commentary outside JSON. Be concise but academically sound.',
        'illumine_system_prompt': 'You are Illumine, an advanced Bible analysis engine. Your goal is to illuminate the scriptures with depth, clarity, and historical accuracy.',
      };

      for (var entry in defaults.entries) {
        // Handle nested collections for exegesis if needed, or store them in ai_prompts.
        // Wait, 'ai_exegesis/system' is fetched from collection('ai_exegesis').doc('system').
        String col = 'ai_prompts';
        String docKey = entry.key;
        if (docKey.startsWith('ai_exegesis/')) {
          col = 'ai_exegesis';
          docKey = docKey.split('/')[1];
        }

        final docRef = _firestore.collection(col).doc(docKey);
        final docSnap = await docRef.get();
        if (!docSnap.exists || (docSnap.data()!['systemPrompt'] ?? '').toString().isEmpty) {
          batch.set(docRef, {
            'systemPrompt': entry.value,
            'isActive': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seeded defaults successfully! Please refresh to load.')),
        );
      }
      await _loadPrompts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to seed prompts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Prompts & Configuration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _seedDefaults,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Seed Missing Defaults'),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
      ],
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
