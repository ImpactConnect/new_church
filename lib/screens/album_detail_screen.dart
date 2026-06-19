import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/sermon.dart';
import '../services/audio_player_service.dart';
import '../services/sermon_service.dart';
import '../widgets/sermon_card.dart';
import '../widgets/mini_player.dart';

class AlbumDetailScreen extends StatefulWidget {
  const AlbumDetailScreen({
    Key? key,
    required this.albumName,
    required this.sermons,
    required this.audioPlayerService,
    required this.sermonService,
    this.coverImageUrl,
    this.description,
  }) : super(key: key);

  final String albumName;
  final List<Sermon> sermons;
  final AudioPlayerService audioPlayerService;
  final SermonService sermonService;
  final String? coverImageUrl;
  final String? description;

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  Sermon? _currentSermon;
  bool _showMiniPlayer = false;

  @override
  void initState() {
    super.initState();
    _currentSermon = widget.audioPlayerService.currentSermon;
    if (_currentSermon != null) {
      _showMiniPlayer = true;
    }
    widget.audioPlayerService.playerStateStream.listen((_) {
      if (mounted) {
        setState(() {
          _currentSermon = widget.audioPlayerService.currentSermon;
          _showMiniPlayer = _currentSermon != null;
        });
      }
    });
  }

  void _closeMiniPlayer() {
    setState(() {
      _showMiniPlayer = false;
    });
    widget.audioPlayerService.player.stop();
  }

  void _playAll() async {
    if (widget.sermons.isNotEmpty) {
      await widget.audioPlayerService.playSermonFromPlaylist(
        widget.sermons.first,
        widget.sermons,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstSermon = widget.sermons.isNotEmpty ? widget.sermons.first : null;
    final displayImageUrl =
        (widget.coverImageUrl != null && widget.coverImageUrl!.isNotEmpty)
            ? widget.coverImageUrl!
            : firstSermon?.thumbnailUrl ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.albumName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                  background: displayImageUrl.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: displayImageUrl,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                          ],
                        )
                      : Container(
                          color: colors.primary,
                          child: const Icon(Icons.folder_special,
                              size: 80, color: Colors.white54),
                        ),
                ),
              ),
              if (widget.description != null && widget.description!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      widget.description!,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Text(
                        '${widget.sermons.length} Audio Files',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _playAll,
                        icon: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white),
                        label: const Text('Play All',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final sermon = widget.sermons[index];
                    return SermonCard(
                      sermon: sermon,
                      audioPlayerService: widget.audioPlayerService,
                      sermonService: widget.sermonService,
                      onTap: () {
                        widget.audioPlayerService.playSermonFromPlaylist(
                          sermon,
                          widget.sermons,
                        );
                      },
                    );
                  },
                  childCount: widget.sermons.length,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: _showMiniPlayer ? 100 : 20),
              ),
            ],
          ),
          if (_showMiniPlayer && _currentSermon != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(
                sermon: _currentSermon!,
                audioPlayerService: widget.audioPlayerService,
                onClose: _closeMiniPlayer,
              ),
            ),
        ],
      ),
    );
  }
}
