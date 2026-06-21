import 'package:flutter/material.dart';

import '../models/berean_evaluation_model.dart';
import '../../monetization/widgets/banner_ad_widget.dart';
import '../repositories/berean_repository.dart';
import 'berean_form_screen.dart';

class BereanDashboardScreen extends StatefulWidget {
  const BereanDashboardScreen({super.key});

  @override
  State<BereanDashboardScreen> createState() => _BereanDashboardScreenState();
}

class _BereanDashboardScreenState extends State<BereanDashboardScreen> {
  final BereanRepository _repository = BereanRepository();
  List<BereanEvaluationModel> _evaluations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
  }

  Future<void> _loadEvaluations() async {
    setState(() => _isLoading = true);
    final evaluations = await _repository.getAll();
    if (mounted) {
      setState(() {
        _evaluations = evaluations;
        _isLoading = false;
      });
    }
  }

  Color _verdictColor(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (label) {
      case 'Scripturally Sound':
        return const Color(0xFF4caf82);
      case 'Partially Supported':
      case 'Context Dependent':
      case 'Misleading Without Context':
        return colorScheme.secondary;
      case 'Contradicts Scripture':
        return const Color(0xFFe05c5c);
      case 'Scripture Silent':
      case 'Scripture Silent on This':
        return const Color(0xFF5b9bd5);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Berean Check')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BereanFormScreen()),
          );
          _loadEvaluations();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Evaluation'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvaluations,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _evaluations.isEmpty ? 2 : _evaluations.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      children: [
                        _buildHeader(theme),
                        const BannerAdWidget(),
                        const SizedBox(height: 24),
                      ],
                    );
                  }

                  if (_evaluations.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  if (index == 1) return _buildRecentLabel(theme);

                  final evaluation = _evaluations[index - 2];
                  return _buildEvaluationCard(context, evaluation);
                },
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F63D2), Color(0xFF8B3FC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4FC8).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.balance, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 20),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Berean Check',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'A Scripture comparison engine designed to help you evaluate doctrines, sermons, and sayings through a structured biblical lens.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLabel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Row(
        children: [
          Icon(Icons.history, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Recent Analysis',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF673AB7).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.balance,
              size: 64,
              color: Color(0xFF673AB7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Evaluations Yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Submit a statement, doctrine, or quote to evaluate through Scripture.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BereanFormScreen()),
              );
              _loadEvaluations();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF673AB7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Start Your First Evaluation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(
    BuildContext context,
    BereanEvaluationModel evaluation,
  ) {
    final theme = Theme.of(context);
    final verdictLabel = evaluation.alignmentVerdict.label;
    final color = _verdictColor(context, verdictLabel);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BereanResultScreenFull(evaluation: evaluation),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      evaluation.inputText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      verdictLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: color.withOpacity(0.1),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(
                      evaluation.doctrineClassification.tier,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(evaluation.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
