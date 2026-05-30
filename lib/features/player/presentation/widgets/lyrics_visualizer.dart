import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class LyricsVisualizer extends StatefulWidget {
  final String imageUrl;
  final String title;
  final bool isPlaying;

  const LyricsVisualizer({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.isPlaying,
  });

  @override
  State<LyricsVisualizer> createState() => _LyricsVisualizerState();
}

class _LyricsVisualizerState extends State<LyricsVisualizer>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animCtrl;
  List<String> _mockLyrics = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    );
    
    _generateMockLyrics();

    if (widget.isPlaying) {
      _startScrolling();
    }
  }

  void _generateMockLyrics() {
    // Generate some elegant mock lyrics based on the title
    _mockLyrics = [
      widget.title,
      "The city lights are fading out",
      "I hear the whispers in the wind",
      "Walking down this empty road",
      "Wondering where to begin",
      "Oh, the shadows are dancing",
      widget.title,
      "And the time is standing still",
      "In the echo of your voice",
      "I find the strength, I find the will",
      "Hold my hand and close your eyes",
      "Let the rhythm take control",
      "We're diving into the deep",
      "A melody that heals the soul",
      widget.title,
      "Like a river flowing endlessly",
      "Towards an ocean of dreams",
      "Everything is meant to be",
      "Or so it softly seems",
      "Yeah, we're flying so high",
      widget.title,
      "Never looking back again",
      "The stars are our only guide",
      "Until the very end.",
    ];
  }

  void _startScrolling() {
    _animCtrl.forward().then((_) {
      if (mounted) {
        // Reverse or just stay
      }
    });
    _animCtrl.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(_animCtrl.value * maxScroll);
      }
    });
  }

  @override
  void didUpdateWidget(LyricsVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.title != oldWidget.title) {
      _generateMockLyrics();
      _scrollController.jumpTo(0);
      _animCtrl.reset();
      if (widget.isPlaying) _startScrolling();
    } else if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _animCtrl.forward();
      } else {
        _animCtrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Blurred Album Art Background
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),
            
            // Lyrics List
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              physics: const BouncingScrollPhysics(),
              itemCount: _mockLyrics.length,
              itemBuilder: (context, index) {
                final isHighlight = index == 0 || index == 6 || index == 14 || index == 20;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    _mockLyrics[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isHighlight 
                        ? Colors.white 
                        : Colors.white.withValues(alpha: 0.5),
                      fontSize: isHighlight ? 22 : 18,
                      fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.5,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
            
            // Gradient Fades
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
