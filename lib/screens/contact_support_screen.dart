import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({Key? key}) : super(key: key);

  @override
  _ContactSupportScreenState createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  String _selectedSupportType = 'General Inquiry';
  final List<String> _supportTypes = [
    'General Inquiry',
    'Technical Issue',
    'Account Recovery',
    'Billing/Donation',
    'Feedback/Suggestion',
    'Other'
  ];
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance.collection('support_requests').add({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'type': _selectedSupportType,
        'message': _messageController.text.trim(),
        'userId': user?.uid,
        'userEmail': user?.email,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support request sent successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.transparent : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Contact Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How can we help you?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill out the form below and our team will get back to you shortly.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700]),
                  prefixIcon: Icon(Icons.person_outline, color: isDark ? Colors.white60 : Colors.grey[600]),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide(color: Colors.white.withOpacity(0.1)) : const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide(color: Colors.white.withOpacity(0.1)) : const BorderSide(color: Colors.black12),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              
              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700]),
                  prefixIcon: Icon(Icons.phone_outlined, color: isDark ? Colors.white60 : Colors.grey[600]),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide(color: Colors.white.withOpacity(0.1)) : const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide(color: Colors.white.withOpacity(0.1)) : const BorderSide(color: Colors.black12),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 16),
              
              // Support Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSupportType,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Support Type',
                  labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700]),
                  prefixIcon: Icon(Icons.category_outlined, color: isDark ? Colors.white60 : Colors.grey[600]),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide(color: Colors.white.withOpacity(0.1)) : const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide(color: Colors.white.withOpacity(0.1)) : const BorderSide(color: Colors.black12),
                  ),
                ),
                items: _supportTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSupportType = val);
                },
              ),
              const SizedBox(height: 16),
              
              // Message Box
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Message / Details',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700]),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide(color: Colors.white.withOpacity(0.1)) : const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: isDark ? BorderSide(color: Colors.white.withOpacity(0.1)) : const BorderSide(color: Colors.black12),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your message' : null,
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Request',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
