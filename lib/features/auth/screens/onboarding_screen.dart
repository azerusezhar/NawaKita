import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nawakita/app/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardPage(
      title: 'Lewati Macet, Nikmati Perjalanan',
      description:
          'Biarkan AI memandu Anda melewati jalanan padat. Dapatkan kembali waktu berharga Anda untuk hal yang lebih penting.',
      asset: 'assets/images/onboarding.png',
    ),
    _OnboardPage(
      title: 'Setiap Sudut Punya Cerita',
      description:
          'Dari kafe legendaris hingga wisata rahasia, temukan dan dukung pesona asli Malang yang belum pernah Anda lihat sebelumnya.',
      asset: 'assets/images/onboarding.png',
      imageTopExtra: 32,
    ),
    _OnboardPage(
      title: 'Suara Anda Mengubah Kota',
      description:
          'Laporkan masalah hanya dengan satu foto dan dapatkan info instan 24/7 dari Asisten Virtual Nita. Kota yang lebih baik dimulai dari Anda.',
      asset: 'assets/images/onboarding.png',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeAndGoHome() async {
    // Tandai onboarding selesai supaya tidak tampil lagi
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }                                     

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _completeAndGoHome();
    }
  }

  void _skip() {
    _completeAndGoHome();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _index == 0
                        ? null
                        : () => _controller.previousPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Lewati',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _pages[i],
              ),
            ),

            // Indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _Dots(count: _pages.length, index: _index),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                label: _index == _pages.length - 1 ? 'Mulai' : 'Lanjut',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({required this.title, required this.description, required this.asset, this.imageTopExtra = 0});

  final String title;
  final String description;
  final String asset;
  final double imageTopExtra;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 8 + imageTopExtra),
          Center(
            child: Image.asset(
              asset,
              height: 260,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => Icon(Icons.image_not_supported_outlined, size: 88, color: cs.outline),
            ),
          ),
          const SizedBox(height: 56),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final active = Theme.of(context).colorScheme.primary;
    final inactive = Theme.of(context).dividerColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: selected ? 22 : 8,
          decoration: BoxDecoration(
            color: selected ? active : inactive,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
