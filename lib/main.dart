import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LoveProposalApp());
}

// =====================================================
// APP
// =====================================================

class LoveProposalApp extends StatelessWidget {
  const LoveProposalApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryPink = Color(0xFFE85D93);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'A Little Question for Rajorshi',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryPink,
          brightness: Brightness.light,
          surface: const Color(0xFFFFF8FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8FB),
        fontFamily: 'Roboto',
      ),
      home: const ProposalScreen(),
    );
  }
}

// =====================================================
// PROPOSAL SCREEN
// =====================================================

class ProposalScreen extends StatefulWidget {
  const ProposalScreen({super.key});

  @override
  State<ProposalScreen> createState() => _ProposalScreenState();
}

class _ProposalScreenState extends State<ProposalScreen> {
  final Random _random = Random();

  static const double _buttonWidth = 165;
  static const double _buttonHeight = 54;
  static const int _maxAttempts = 3;

  bool? _liked;

  int _attempts = 0;

  Offset? _noPosition;

  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  // One document ID for this submission.
  // Retrying will reuse the same document.
  late final DocumentReference<Map<String, dynamic>>
      _responseRef = FirebaseFirestore.instance
          .collection('proposal_responses')
          .doc();

  // ===================================================
  // SELECT YES
  // ===================================================

  void _selectYes() {
    if (_isSubmitting || _hasSubmitted) return;

    setState(() {
      _liked = true;
    });
  }

  // ===================================================
  // MOVE NO BUTTON
  // ===================================================

  void _moveNoButton(double maxWidth, double maxHeight) {
    if (_isSubmitting || _hasSubmitted) return;

    setState(() {
      _liked = false;
    });

    if (_attempts >= _maxAttempts) {
      _showNoDialog();
      return;
    }

    final maxX = max(0.0, maxWidth - _buttonWidth);
    final maxY = max(0.0, maxHeight - _buttonHeight);

    final newX = _random.nextDouble() * maxX;
    final newY = _random.nextDouble() * maxY;

    setState(() {
      _attempts++;
      _noPosition = Offset(newX, newY);
    });
  }

  // ===================================================
  // FIREBASE SUBMISSION
  // ===================================================

  Future<void> _submitResponse() async {
    if (_liked != true || _isSubmitting || _hasSubmitted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _responseRef.set({
        'response': 'yes',
        'submitted': true,
        'source': 'proposal_web',
        'recipient': 'Rajorshi',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 15),
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _hasSubmitted = true;
      });

      _showYesDialog();

    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showError(
        'Server is taking too long. Please check your connection and try again.',
      );

    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showError(
        'Firebase Error: ${e.message ?? e.code}',
      );

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showError(
        'Something went wrong. Please try again.',
      );
    }
  }

  // ===================================================
  // ERROR MESSAGE
  // ===================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF9B4269),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ===================================================
  // YES DIALOG
  // ===================================================

  void _showYesDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return const ProposalDialog(
          title: 'I knew it! 🥰',
          subtitle: "You're absolutely adorable!",
          message:
              'Sending you a million hugs and '
              'endless love! 💗',
          buttonText: 'Awww! 💕',
          isSuccess: true,
        );
      },
    );
  }

  // ===================================================
  // NO DIALOG
  // ===================================================

  void _showNoDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return const ProposalDialog(
          title: 'Oops! Sorry! 🙈',
          subtitle: "Why can't select the other option?",
          message:
              'I think you already know which option '
              'to choose! Come on, give me a chance! '
              '😜💕',
          buttonText: 'Okay, fine! 💖',
          isSuccess: false,
        );
      },
    );
  }

  // ===================================================
  // MAIN UI
  // ===================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE5EF),
              Color(0xFFFFF4F7),
              Color(0xFFEFE8FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(
                child: FloatingHearts(),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 460,
                    ),
                    child: _buildProposalCard(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================
  // PROPOSAL CARD
  // ===================================================

  Widget _buildProposalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96B9B).withOpacity(0.15),
            blurRadius: 35,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER

          const Text(
            '♡  A LITTLE QUESTION FOR RAJORSHI  ♡',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFC65B86),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 24),

          // TEDDY BEAR

          const BearLoveSticker(size: 175),

          const SizedBox(height: 18),

          // INTRODUCTION

          const Text(
            'I have something to ask you...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFAC8295),
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 24),

          // MAIN QUESTION

          const Text(
            'I love you so much, do you love me too? 💕',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD94F88),
              fontSize: 27,
              fontWeight: FontWeight.w600,
             // letterSpacing: -1,
            ),
          ),
          
          /*

          const SizedBox(height: 14),

          const Text(
            'Do you like me too? 💕',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF70445F),
              fontSize: 23,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          */

          const SizedBox(height: 32),

          // YES BUTTON

          _buildYesButton(),

          const SizedBox(height: 24),

          // NO BUTTON TEXT

          const Text(
            'Or maybe you have another answer? 🧸',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFAE8296),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          // NO BUTTON

          _buildNoButton(),

          const SizedBox(height: 14),

          // SUBMIT BUTTON

          _buildSubmitButton(),

          const SizedBox(height: 28),

          // FOOTER

          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                size: 14,
                color: Color(0xFFE88BAF),
              ),
              SizedBox(width: 9),
              Text(
                'Just For You',
                style: TextStyle(
                  color: Color(0xFFB77B96),
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(width: 9),
              Icon(
                Icons.favorite,
                size: 14,
                color: Color(0xFFE88BAF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================================================
  // YES BUTTON
  // ===================================================

  Widget _buildYesButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _liked == true ||
                _isSubmitting ||
                _hasSubmitted
            ? null
            : _selectYes,
        icon: const Icon(Icons.favorite_rounded),
        label: const Text(
          'Yes, of course!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE85D93),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFFFB8D0),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 3,
        ),
      ),
    );
  }

  // ===================================================
  // NO BUTTON
  // ===================================================

  Widget _buildNoButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const areaHeight = 120.0;

        final width = constraints.maxWidth;

        final position = _noPosition ??
            Offset(
              max(0.0, (width - _buttonWidth) / 2),
              (areaHeight - _buttonHeight) / 2,
            );

        return SizedBox(
          width: double.infinity,
          height: areaHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                left: position.dx,
                top: position.dy,
                child: SizedBox(
                  width: _buttonWidth,
                  height: _buttonHeight,
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting || _hasSubmitted
                        ? null
                        : () {
                            _moveNoButton(
                              width,
                              areaHeight,
                            );
                          },
                    icon: const Icon(
                      Icons.block_rounded,
                      size: 19,
                    ),
                    label: const Text(
                      'Not at all',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB65E82),
                      backgroundColor: const Color(0xFFFFE5EE),
                      side: const BorderSide(
                        color: Color(0xFFF3B5CD),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================================================
  // SUBMIT BUTTON
  // ===================================================

  Widget _buildSubmitButton() {
    final canSubmit = _liked == true &&
        !_isSubmitting &&
        !_hasSubmitted;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: canSubmit ? _submitResponse : null,
        icon: _isSubmitting
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                _hasSubmitted
                    ? Icons.check_circle_rounded
                    : Icons.send_rounded,
              ),
        label: Text(
          _hasSubmitted
              ? 'Answer Submitted 💗'
              : _isSubmitting
                  ? 'Submitting...'
                  : 'Submit The Answer 💌',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE85D93),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE8DCE2),
          disabledForegroundColor: const Color(0xFFAA9BA3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// BEAR LOVE STICKER
// =====================================================

class BearLoveSticker extends StatelessWidget {
  final double size;

  const BearLoveSticker({
    super.key,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/bear_love.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: size,
          height: size,
          child: const Center(
            child: Text(
              '🧸💗',
              style: TextStyle(fontSize: 65),
            ),
          ),
        );
      },
    );
  }
}

// =====================================================
// FLOATING HEARTS ANIMATION
// =====================================================

class FloatingHearts extends StatefulWidget {
  const FloatingHearts({super.key});

  @override
  State<FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<FloatingHearts>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<_HeartData> _hearts = [
    _HeartData(0.08, 0.16, 20, 0.0, '♡'),
    _HeartData(0.82, 0.12, 25, 0.2, '💕'),
    _HeartData(0.12, 0.72, 23, 0.4, '🧸'),
    _HeartData(0.88, 0.68, 18, 0.6, '💗'),
    _HeartData(0.50, 0.08, 15, 0.8, '✦'),
    _HeartData(0.72, 0.90, 20, 0.3, '♡'),
    _HeartData(0.25, 0.91, 17, 0.7, '🌷'),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: _hearts.map((heart) {
                  final movement = sin(
                    (_controller.value + heart.phase) *
                        2 *
                        pi,
                  ) * 12;

                  return Positioned(
                    left: constraints.maxWidth * heart.x,
                    top: constraints.maxHeight * heart.y +
                        movement,
                    child: Opacity(
                      opacity: 0.55,
                      child: Text(
                        heart.emoji,
                        style: TextStyle(
                          fontSize: heart.size,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}

class _HeartData {
  final double x;
  final double y;
  final double size;
  final double phase;
  final String emoji;

  const _HeartData(
    this.x,
    this.y,
    this.size,
    this.phase,
    this.emoji,
  );
}

// =====================================================
// PROPOSAL DIALOG
// =====================================================

class ProposalDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String message;
  final String buttonText;
  final bool isSuccess;

  const ProposalDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.message,
    required this.buttonText,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isSuccess
        ? const Color(0xFFE85D93)
        : const Color(0xFFAB6C91);

    return Dialog(
      backgroundColor: const Color(0xFFFFF8FB),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BearLoveSticker(
              size: isSuccess ? 155 : 125,
            ),

            const SizedBox(height: 12),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF79566B),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94788A),
                fontSize: 14,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
