import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

const _allLanguages = [
  {'key': 'hindi', 'label': 'Hindi'},
  {'key': 'tamil', 'label': 'Tamil'},
  {'key': 'telugu', 'label': 'Telugu'},
  {'key': 'kannada', 'label': 'Kannada'},
  {'key': 'malayalam', 'label': 'Malayalam'},
  {'key': 'punjabi', 'label': 'Punjabi'},
  {'key': 'bengali', 'label': 'Bengali'},
  {'key': 'marathi', 'label': 'Marathi'},
  {'key': 'gujarati', 'label': 'Gujarati'},
  {'key': 'bhojpuri', 'label': 'Bhojpuri'},
  {'key': 'haryanvi', 'label': 'Haryanvi'},
  {'key': 'rajasthani', 'label': 'Rajasthani'},
  {'key': 'odia', 'label': 'Odia'},
  {'key': 'english', 'label': 'English'},
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _selected = {'hindi'};
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  late final AnimationController _animCtrl;
  String _nameError = '';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _onStart() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter your name to continue');
      _nameFocus.requestFocus();
      return;
    }
    setState(() => _nameError = '');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setStringList('selected_languages', _selected.toList());
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _animCtrl,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // ─── Brand ───
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.premiumGradient.createShader(bounds),
                            child: const Text('RaagaFlow',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                )),
                          ),
                          Text('Your music, your vibe',
                              style: AppTextStyles.trackArtist.copyWith(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // ─── Name Input ───
                  Text(
                    'What should we call you?',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We\'ll personalise your experience',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint),
                  ),
                  const SizedBox(height: 16),
                  _NameField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    error: _nameError,
                    onChanged: (_) {
                      if (_nameError.isNotEmpty) {
                        setState(() => _nameError = '');
                      }
                    },
                    onSubmitted: (_) => _onStart(),
                  ),

                  const SizedBox(height: 40),

                  // ─── Language Selection ───
                  Text('Pick your languages', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 4),
                  Text('You can always change this later',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: _allLanguages.map((lang) {
                      final key = lang['key']!;
                      final isSelected = _selected.contains(key);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            if (_selected.length > 1) _selected.remove(key);
                          } else {
                            _selected.add(key);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? AppColors.accentGradient
                                : null,
                            color: isSelected
                                ? null
                                : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(24),
                            border: isSelected
                                ? null
                                : Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check_rounded,
                                    size: 16, color: Colors.black),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                lang['label']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 48),

                  // ─── Start Button ───
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _onStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Start Listening',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.black, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A premium styled name text field.
class _NameField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String error;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.error,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error.isNotEmpty;
    final borderColor = hasError
        ? Colors.redAccent.withValues(alpha: 0.7)
        : _focused
            ? AppColors.accent.withValues(alpha: 0.7)
            : AppColors.divider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 0.8),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      blurRadius: 16,
                      spreadRadius: 0,
                    )
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              hintText: 'Your name...',
              hintStyle: TextStyle(
                color: AppColors.textHint.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.person_rounded,
                color: _focused ? AppColors.accent : AppColors.textHint,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 18),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 14, color: Colors.redAccent),
              const SizedBox(width: 6),
              Text(
                widget.error,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
