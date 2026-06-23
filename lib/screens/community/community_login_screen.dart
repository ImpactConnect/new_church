import 'package:flutter/material.dart';

import '../../models/community_user.dart';
import '../../services/community_auth_service.dart';
import 'community_posts_screen.dart';

class CommunityLoginScreen extends StatefulWidget {
  final void Function(CommunityUser)? onLoginSuccess;
  const CommunityLoginScreen({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  _CommunityLoginScreenState createState() => _CommunityLoginScreenState();
}

class _CommunityLoginScreenState extends State<CommunityLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final CommunityAuthService _authService = CommunityAuthService();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final CommunityUser? existingUser = await _authService.getCurrentUser();
      if (existingUser != null) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!(existingUser);
        } else {
          // Navigate to Community Dashboard if already logged in
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      CommunityPostsScreen(currentUser: existingUser)));
        }
      }
    } catch (e) {
      print('Error checking existing login: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final CommunityUser? user = await _authService.signIn(
          _usernameController.text.trim(), _passwordController.text.trim());

      if (user != null) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!(user);
        } else {
          // Navigate to Community Dashboard
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => CommunityPostsScreen(currentUser: user)));
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.transparent : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Community Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: isDark ? 0 : 8,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent),
              ),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to access community features',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Username TextField
                    TextField(
                      controller: _usernameController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700]),
                        prefixIcon: Icon(Icons.person_outline, color: isDark ? Colors.white60 : Colors.grey[600]),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password TextField
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700]),
                        prefixIcon: Icon(Icons.lock_outline, color: isDark ? Colors.white60 : Colors.grey[600]),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Forgot Password Note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.blue.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, color: isDark ? Colors.blue[300] : Colors.blue[700], size: 24),
                          const SizedBox(height: 8),
                          Text(
                            'Please reach out to the admin if you forgot your password, or use the \'Forgot Password\' option below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.blue[900],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () async {
                              final username = _usernameController.text.trim();
                              if (username.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter your username first.')),
                                );
                                return;
                              }

                              setState(() => _isLoading = true);
                              try {
                                await _authService.sendPasswordResetEmail(username);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Password reset link sent to your email.')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? Colors.blue[300] : Colors.blue[700],
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
