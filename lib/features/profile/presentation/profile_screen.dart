import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../home/domain/home_provider.dart';

const _allLanguages = [
  {'key': 'hindi',      'label': 'Hindi',      'native': 'हिन्दी'},
  {'key': 'english',    'label': 'English',    'native': 'English'},
  {'key': 'tamil',      'label': 'Tamil',      'native': 'தமிழ்'},
  {'key': 'telugu',     'label': 'Telugu',     'native': 'తెలుగు'},
  {'key': 'kannada',    'label': 'Kannada',    'native': 'ಕನ್ನಡ'},
  {'key': 'malayalam',  'label': 'Malayalam',  'native': 'മലയാളം'},
  {'key': 'punjabi',    'label': 'Punjabi',    'native': 'ਪੰਜਾਬੀ'},
  {'key': 'bengali',    'label': 'Bengali',    'native': 'বাংলা'},
  {'key': 'marathi',    'label': 'Marathi',    'native': 'मराठी'},
  {'key': 'gujarati',   'label': 'Gujarati',   'native': 'ગુજરાતી'},
  {'key': 'bhojpuri',   'label': 'Bhojpuri',   'native': 'भोजपुरी'},
  {'key': 'haryanvi',   'label': 'Haryanvi',   'native': 'हरयाणवी'},
  {'key': 'rajasthani', 'label': 'Rajasthani', 'native': 'राजस्थानी'},
  {'key': 'odia',       'label': 'Odia',       'native': 'ଓଡ଼ିଆ'},
  {'key': 'urdu',       'label': 'Urdu',       'native': 'اردو'},
];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _userName = '';
  Set<String> _selected = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final langs = prefs.getStringList('selected_languages') ?? ['hindi'];
    if (mounted) {
      setState(() {
        _userName = name;
        _selected = langs.toSet();
      });
    }
  }

  Future<void> _saveLanguages() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pick at least one language'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    // Save to SharedPreferences
    final langs = _selected.toList();
    await ref.read(selectedLanguagesProvider.notifier).setLanguages(langs);

    // Invalidate all trending caches → fresh songs on home screen
    for (final lang in langs) {
      ref.invalidate(trendingProvider(lang));
    }

    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saved! Home updated with ${_selected.length} language${_selected.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── Header ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.accentGradient,
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        backgroundImage: const AssetImage('assets/images/app_icon.png'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName.isNotEmpty ? _userName : 'Music Lover',
                      style: AppTextStyles.headline1.copyWith(
                        fontSize: 26,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Languages summary pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.language_rounded, color: AppColors.accent, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            _selected.isEmpty
                                ? 'No languages selected'
                                : _selected.map((l) {
                                    return _allLanguages.firstWhere(
                                      (e) => e['key'] == l,
                                      orElse: () => {'label': l},
                                    )['label']!;
                                  }).join(' · '),
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Language Studio ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'My Music Languages',
                          style: AppTextStyles.sectionTitle.copyWith(fontSize: 17),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Text(
                        'Select all languages you want to see on Home',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Language Chips Grid ──
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: _allLanguages.map((lang) {
                        final key = lang['key']!;
                        final label = lang['label']!;
                        final native = lang['native']!;
                        final isSelected = _selected.contains(key);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                if (_selected.length > 1) _selected.remove(key);
                              } else {
                                _selected.add(key);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppColors.accentGradient : null,
                              color: isSelected
                                  ? null
                                  : AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(28),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: AppColors.divider.withValues(alpha: 0.5),
                                      width: 0.8),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(alpha: 0.25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  Icon(Icons.check_rounded,
                                      size: 14,
                                      color: isSelected ? AppColors.onPrimary : AppColors.textHint),
                                  const SizedBox(width: 5),
                                ],
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.onPrimary
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      native,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.onPrimary.withValues(alpha: 0.75)
                                            : AppColors.textHint,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    // ── Save Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveLanguages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                          ),
                          child: _saving
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_rounded,
                                        color: AppColors.onPrimary, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Save & Update Home',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 180),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
