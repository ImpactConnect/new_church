import 'package:flutter/material.dart';
import '../features/bible/screens/rabbi_intro_screen.dart';
import '../features/speak_with/screens/speak_with_home_screen.dart';
import '../features/exegesis/screens/exegesis_dashboard_screen.dart';
import '../features/berean/screens/berean_dashboard_screen.dart';

class PneumaAiHubScreen extends StatefulWidget {
  const PneumaAiHubScreen({super.key});

  @override
  State<PneumaAiHubScreen> createState() => _PneumaAiHubScreenState();
}

class _PneumaAiHubScreenState extends State<PneumaAiHubScreen> {
  late ScrollController _scrollController;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 160 && !_showTitle) {
        setState(() => _showTitle = true);
      } else if (_scrollController.offset <= 160 && _showTitle) {
        setState(() => _showTitle = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F3FF),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF1A0A3C),
            centerTitle: true,
            title: AnimatedOpacity(
              opacity: _showTitle ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Text('Pneuma AI', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A0A3C), Color(0xFF3D1A7A), Color(0xFF6B2FC8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Decorative glowing orbs
                  Positioned(
                    top: -30, right: -30,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20, left: 40,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFB88AFC).withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🕊️', style: TextStyle(fontSize: 32)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Pneuma AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Spirit-led Intelligence',
                          style: TextStyle(
                            color: Color(0xFFD4BBFF),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'AI-powered theological tools to deepen your understanding of the Word.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFBFA8E8), fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _SectionLabel(label: 'Your AI Tools'),
                const SizedBox(height: 12),
                _PneumaFeatureCard(
                  emoji: '📜',
                  title: 'Ask GSW',
                  subtitle: 'Get 24/7 spiritual guidance and answers to your scripture questions directly from Pastor GSW.',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F63D2), Color(0xFF8B3FC0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RabbiIntroScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _PneumaFeatureCard(
                  emoji: '🗣️',
                  title: 'ScriptTalk',
                  subtitle: 'Engage in voice-driven conversations with Biblical figures and authors. Step into the pages of Scripture.',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF673AB7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SpeakWithHomeScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _PneumaFeatureCard(
                  emoji: '🔬',
                  title: 'Exegesis Engine',
                  subtitle: 'Academic-level, AI-generated deep dives into any passage, chapter, book, or biblical character.',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ExegesisDashboardScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _PneumaFeatureCard(
                  emoji: '⚖️',
                  title: 'Berean Check',
                  subtitle: 'Evaluate doctrines, sermons, and teachings through a structured biblical and hermeneutical lens.',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BereanDashboardScreen()),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B2FC8).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6B2FC8).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF6B2FC8), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI behavior is controlled by your administrator through the AI Config settings.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFD4BBFF) : const Color(0xFF4A1D96),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _PneumaFeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _PneumaFeatureCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decorative element
            Positioned(
              right: -15,
              top: -15,
              child: Text(emoji, style: const TextStyle(fontSize: 80)),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, gradient.colors.last.withValues(alpha: 0.3)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Open', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
