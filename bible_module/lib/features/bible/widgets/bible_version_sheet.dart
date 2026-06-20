import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/bible/bible_version.dart';
import '../providers/bible_providers.dart';
import '../services/bible_version_service.dart';
import '../../../services/app_notification_service.dart';

class BibleVersionSheet extends ConsumerStatefulWidget {
  const BibleVersionSheet({super.key});

  @override
  ConsumerState<BibleVersionSheet> createState() => _BibleVersionSheetState();
}

class _BibleVersionSheetState extends ConsumerState<BibleVersionSheet> {
  // Map to store download status: null = unknown/checking, true = downloaded, false = not downloaded
  final Map<BibleVersion, bool> _downloadStatus = {};
  // Map to store progress: 0.0 to 1.0
  final Map<BibleVersion, double> _downloadProgress = {};
  // Map to store downloading state
  final Map<BibleVersion, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
    _checkStatuses();
  }

  Future<void> _checkStatuses() async {
    final service = ref.read(bibleVersionServiceProvider);
    for (final version in BibleVersion.values) {
      final isDownloaded = await service.isVersionDownloaded(version);
      if (mounted) {
        setState(() {
          _downloadStatus[version] = isDownloaded;
        });
      }
    }
  }

  Future<void> _downloadVersion(BibleVersion version) async {
    setState(() {
      _isDownloading[version] = true;
      _downloadProgress[version] = 0.0;
    });

    try {
      final service = ref.read(bibleVersionServiceProvider);
      final notifService = AppNotificationService();
      final notificationId = version.index + 100; // Unique ID for each version

      await service.downloadVersion(
        version,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress[version] = progress;
            });

            // Update system notification
            notifService.showDownloadProgress(
              id: notificationId,
              title: 'Downloading ${version.abbreviation}',
              body: '${(progress * 100).toInt()}% complete',
              progress: (progress * 100).toInt(),
            );
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading[version] = false;
          _downloadStatus[version] = true;
        });

        // Show completion notification
        await notifService.showDownloadProgress(
          id: notificationId,
          title: '${version.abbreviation} Downloaded',
          body: 'The ${version.fullName} is ready to use.',
          progress: 100,
          isComplete: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${version.abbreviation} downloaded successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading[version] = false;
          _downloadProgress[version] = 0.0;
        });

        // Cancel/notify error
        AppNotificationService().showDownloadProgress(
          id: version.index + 100,
          title: 'Download Failed',
          body: 'Failed to download ${version.abbreviation}',
          progress: 0,
          isComplete: true,
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to download: $e')));
      }
    }
  }

  Future<void> _deleteVersion(BibleVersion version) async {
    try {
      final service = ref.read(bibleVersionServiceProvider);
      await service.deleteVersion(version);
      if (mounted) {
        setState(() {
          _downloadStatus[version] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${version.abbreviation} deleted')),
        );
      }
      // If deleted version was selected, switch to KJV?
      if (ref.read(bibleVersionNotifierProvider) == version) {
        ref
            .read(bibleVersionNotifierProvider.notifier)
            .setVersion(BibleVersion.kjv);
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVersion = ref.watch(bibleVersionNotifierProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bible Versions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: BibleVersion.values.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final version = BibleVersion.values[index];
                final isSelected = currentVersion == version;
                final isDownloaded = _downloadStatus[version] ?? false;
                final isDownloading = _isDownloading[version] ?? false;
                final progress = _downloadProgress[version] ?? 0.0;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  title: Text(
                    version.abbreviation,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    isDownloading
                        ? 'Downloading... ${(progress * 100).toInt()}%'
                        : isDownloaded || version == BibleVersion.kjv
                        ? '${version.fullName} - Downloaded'
                        : version.fullName,
                    style: TextStyle(
                      color: isDownloading
                          ? Theme.of(context).colorScheme.primary
                          : isDownloaded || version == BibleVersion.kjv
                          ? Colors.green
                          : null,
                      fontStyle: isDownloading
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  trailing: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: isDownloading
                          ? CircularProgressIndicator(
                              value: progress > 0 ? progress : null,
                              strokeWidth: 3,
                            )
                          : isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : isDownloaded || version == BibleVersion.kjv
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: version == BibleVersion.kjv
                                  ? null // Cannot delete KJV
                                  : () => _deleteVersion(version),
                            )
                          : IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () => _downloadVersion(version),
                            ),
                    ),
                  ),
                  onTap: () {
                    if (isDownloaded || version == BibleVersion.kjv) {
                      ref
                          .read(bibleVersionNotifierProvider.notifier)
                          .setVersion(version);
                      Navigator.pop(context);
                    } else if (!isDownloading) {
                      _downloadVersion(version);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
