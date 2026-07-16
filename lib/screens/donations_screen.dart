import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/donation_model.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/hero_header_widget.dart';

class DonationsScreen extends StatelessWidget {
  const DonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .where('isActive', isEqualTo: true)
            .orderBy('sortOrder')
            .snapshots(),
        builder: (context, snapshot) {
          Widget sliverContent;
          if (snapshot.hasError) {
            sliverContent = SliverFillRemaining(
                child: Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red))));
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            sliverContent = const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()));
          } else {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              sliverContent = SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No donation options available right now.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            } else {
              sliverContent = SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final model = DonationModel.fromFirestore(docs[index]);
                      return _DonationCard(donation: model);
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            }
          }

          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                pinned: true,
                backgroundColor: Color(0xFF161622),
                iconTheme: IconThemeData(color: Colors.white),
                title: Text('Give',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                centerTitle: true,
              ),
              const SliverToBoxAdapter(
                child: HeroHeaderWidget(
                    imagePath: 'assets/images/donations.png'),
              ),
              sliverContent,
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: -1),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final DonationModel donation;

  const _DonationCard({required this.donation});

  void _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                donation.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                donation.description,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              if (donation.isFixedAmount && donation.fixedAmount != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest ?? theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Fixed Amount: ₦${donation.fixedAmount!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              
              // Bank Transfer Details
              if ((donation.bankName != null && donation.bankName!.isNotEmpty) ||
                  (donation.accountNumber != null && donation.accountNumber!.isNotEmpty)) ...[
                Text(
                  'Bank Transfer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest ?? theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (donation.bankName != null && donation.bankName!.isNotEmpty)
                        _buildDetailRow('Bank Name', donation.bankName!, theme),
                      if (donation.accountName != null && donation.accountName!.isNotEmpty) ...[
                        Divider(color: theme.colorScheme.onSurface.withOpacity(0.12), height: 24),
                        _buildDetailRow('Account Name', donation.accountName!, theme),
                      ],
                      if (donation.accountNumber != null && donation.accountNumber!.isNotEmpty) ...[
                        Divider(color: theme.colorScheme.onSurface.withOpacity(0.12), height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Account No.',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                donation.accountNumber!,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: donation.accountNumber!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Account number copied to clipboard')),
                                );
                              },
                              child: const Icon(Icons.copy, color: Colors.blue, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Paystack Link
              if (donation.paystackLink != null && donation.paystackLink!.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _launchUrl(context, donation.paystackLink!),
                    child: const Text(
                      'Give Online (Paystack)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(BuildContext context, String urlStr) async {
    if (urlStr.isEmpty) return;
    
    // Validate it looks somewhat like a URL (contains a dot for domain, doesn't look like a raw API key)
    if (!urlStr.contains('.') || urlStr.startsWith('pk_test') || urlStr.startsWith('pk_live')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid payment link. Please update the link in the Admin Panel.')),
        );
      }
      return;
    }
    
    String formattedUrl = urlStr;
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }
    
    try {
      final url = Uri.parse(formattedUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.inAppWebView);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link. Please verify it is a valid URL.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid link format.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = donation.imageUrl != null && donation.imageUrl!.isNotEmpty;
    
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image / Icon section
            Expanded(
              flex: 5,
              child: hasImage
                  ? Image.network(
                      donation.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultHeader(),
                    )
                  : _buildDefaultHeader(),
            ),
            // Details section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (donation.isFixedAmount && donation.fixedAmount != null)
                      Text(
                        '₦${donation.fixedAmount!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      )
                    else
                      const Text(
                        'Open Amount',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    const Spacer(),
                    Text(
                      donation.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.2),
            Colors.blue.withOpacity(0.05),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.volunteer_activism, color: Colors.blue, size: 40),
      ),
    );
  }
}
