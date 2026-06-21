import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    return Padding(
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
    );
  }
}
