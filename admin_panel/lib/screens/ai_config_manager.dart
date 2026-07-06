import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_prompts_manager.dart';

class AiConfigManager extends StatefulWidget {
  const AiConfigManager({super.key});

  @override
  State<AiConfigManager> createState() => _AiConfigManagerState();
}

class _AiConfigManagerState extends State<AiConfigManager> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _modelNameController = TextEditingController();
  String _selectedProvider = 'gemini';

  final List<String> _providers = ['gemini', 'openai', 'anthropic'];

  // Voice Settings (TTS)
  String _selectedTtsProvider = 'flutter_tts';
  final List<String> _ttsProviders = ['flutter_tts', 'google_cloud'];
  final _googleCloudTtsApiKeyController = TextEditingController();

  // Voice Settings (STT)
  String _selectedSttProvider = 'whisper';
  final List<String> _sttProviders = ['native', 'whisper', 'deepgram'];
  final _whisperApiKeyController = TextEditingController();
  final _deepgramApiKeyController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelNameController.dispose();
    _googleCloudTtsApiKeyController.dispose();
    _whisperApiKeyController.dispose();
    _deepgramApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ai_config')
          .doc('settings')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _selectedProvider = data['defaultProvider'] ?? 'gemini';
          if (!_providers.contains(_selectedProvider)) {
            _selectedProvider = 'gemini';
          }
          final providersData = data['providers'] as Map<String, dynamic>? ?? {};
          final currentProviderConfig = providersData[_selectedProvider] as Map<String, dynamic>? ?? {};
          _apiKeyController.text = currentProviderConfig['apiKey'] ?? '';
          _modelNameController.text = currentProviderConfig['model'] ?? '';

          // Load Voice Data
          final voiceData = data['voice'] as Map<String, dynamic>? ?? {};
          final ttsData = voiceData['tts'] as Map<String, dynamic>? ?? {};
          final sttData = voiceData['stt'] as Map<String, dynamic>? ?? {};

          _selectedTtsProvider = ttsData['defaultProvider'] ?? 'flutter_tts';
          if (!_ttsProviders.contains(_selectedTtsProvider)) {
            _selectedTtsProvider = 'flutter_tts';
          }
          _googleCloudTtsApiKeyController.text = ttsData['googleCloudApiKey'] ?? '';

          _selectedSttProvider = sttData['defaultProvider'] ?? 'whisper';
          if (!_sttProviders.contains(_selectedSttProvider)) {
            _selectedSttProvider = 'whisper';
          }
          _whisperApiKeyController.text = sttData['whisperApiKey'] ?? '';
          _deepgramApiKeyController.text = sttData['deepgramApiKey'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('ai_config')
          .doc('settings')
          .set({
        'defaultProvider': _selectedProvider,
        'providers': {
          _selectedProvider: {
            'apiKey': _apiKeyController.text.trim(),
            'model': _modelNameController.text.trim(),
          }
        },
        'voice': {
          'tts': {
            'defaultProvider': _selectedTtsProvider,
            'googleCloudApiKey': _googleCloudTtsApiKeyController.text.trim(),
          },
          'stt': {
            'defaultProvider': _selectedSttProvider,
            'whisperApiKey': _whisperApiKeyController.text.trim(),
            'deepgramApiKey': _deepgramApiKeyController.text.trim(),
          }
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bible AI Configuration',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configure the AI Provider, API Key, and Model to power the Bible Exegesis and Chat features.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Provider Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedProvider,
                  decoration: const InputDecoration(
                    labelText: 'AI Provider',
                    border: OutlineInputBorder(),
                  ),
                  items: _providers.map((provider) {
                    return DropdownMenuItem(
                      value: provider,
                      child: Text(provider.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedProvider = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // API Key Field
                TextFormField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    border: OutlineInputBorder(),
                    helperText: 'Enter your API key from the selected provider dashboard.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the API key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Model Name Field
                TextFormField(
                  controller: _modelNameController,
                  decoration: const InputDecoration(
                    labelText: 'Model Name',
                    border: OutlineInputBorder(),
                    helperText: 'e.g. gemini-1.5-flash, gpt-4o, claude-3-opus-20240229',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the model name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                const Text(
                  'Voice Settings (TTS & STT)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configure text-to-speech and speech-to-text providers for ScriptTalk.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // TTS Provider Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedTtsProvider,
                  decoration: const InputDecoration(
                    labelText: 'TTS Provider (Text to Speech)',
                    border: OutlineInputBorder(),
                  ),
                  items: _ttsProviders.map((provider) {
                    return DropdownMenuItem(
                      value: provider,
                      child: Text(provider.toUpperCase().replaceAll('_', ' ')),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTtsProvider = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Google Cloud TTS API Key Field
                TextFormField(
                  controller: _googleCloudTtsApiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Google Cloud TTS API Key (Placeholder)',
                    border: OutlineInputBorder(),
                    helperText: 'Required if Google Cloud is selected.',
                  ),
                ),
                const SizedBox(height: 32),

                // STT Provider Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSttProvider,
                  decoration: const InputDecoration(
                    labelText: 'STT Provider (Speech to Text)',
                    border: OutlineInputBorder(),
                  ),
                  items: _sttProviders.map((provider) {
                    return DropdownMenuItem(
                      value: provider,
                      child: Text(provider.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSttProvider = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Whisper API Key Field
                TextFormField(
                  controller: _whisperApiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Whisper API Key',
                    border: OutlineInputBorder(),
                    helperText: 'Required if Whisper is selected.',
                  ),
                ),
                const SizedBox(height: 24),

                // Deepgram API Key Field
                TextFormField(
                  controller: _deepgramApiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Deepgram API Key',
                    border: OutlineInputBorder(),
                    helperText: 'Required if Deepgram is selected.',
                  ),
                ),
                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Settings'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'AI System Prompts',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Configure the foundational instructions that guide the AI\'s behavior and responses.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const AiPromptsManager(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
