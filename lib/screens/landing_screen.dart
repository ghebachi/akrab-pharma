import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    final bool isTablet =
        MediaQuery.of(context).size.width > 600 && !isDesktop;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _Navbar(isDesktop: isDesktop),
              _HeroSection(
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                  context: context),
              _StatsSection(isDesktop: isDesktop),
              _FeaturesSection(isDesktop: isDesktop),
              _FooterSection(isDesktop: isDesktop),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Navbar ──────────────────────────────────────────────────────
class _Navbar extends StatelessWidget {
  final bool isDesktop;
  const _Navbar({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3B8B), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_pharmacy,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Akrab Pharma',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3B8B),
                ),
              ),
            ],
          ),
          if (isDesktop)
            Row(
              children: [
                _navLink('الرئيسية'),
                const SizedBox(width: 32),
                _navLink('الصيدليات'),
                const SizedBox(width: 32),
                _navLink('عن التطبيق'),
              ],
            ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3B8B), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 28 : 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {},
              child: const Text('دخول الصيادلة',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navLink(String title) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }
}

// ─── Hero Section ────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final BuildContext context;

  const _HeroSection(
      {required this.isDesktop,
      required this.isTablet,
      required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3B8B),
            Color(0xFF1D4ED8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : 24,
                vertical: isDesktop ? 70 : 40),
            child: Flex(
              direction: isDesktop ? Axis.horizontal : Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Left: Text Content ──
                SizedBox(
                  width: isDesktop ? 580 : double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'صيدليات المناوبة — نشط الآن',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      Text(
                        'صيدليات المناوبة\nفي ولايتك بين يديك',
                        style: TextStyle(
                          fontSize: isDesktop ? 48 : 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Accent line
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF10B981),
                              Color(0xFF34D399),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'ابحث عن أقرب صيدلية مفتوحة أو مناوبة ليلية\nفي منطقتك بسرعة وسهولة.',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // CTA Buttons
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          // Primary CTA
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF10B981),
                                  Color(0xFF059669),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.search_rounded,
                                  size: 20),
                              label: const Text(
                                'ابحث عن صيدلية الآن',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          // Secondary CTA
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white.withOpacity(0.85),
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.25)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.phone_rounded, size: 18),
                            label: const Text(
                              'اتصل بصيدلية',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (!isDesktop) const SizedBox(height: 48),

                // ── Right: Phone Mockup ──
                _PhoneMockup(isDesktop: isDesktop),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Phone Mockup ────────────────────────────────────────────────
class _PhoneMockup extends StatelessWidget {
  final bool isDesktop;
  const _PhoneMockup({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double phoneWidth = isDesktop ? 280 : 240;
    final double phoneHeight = isDesktop ? 560 : 480;

    return Container(
      width: phoneWidth,
      height: phoneHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF374151), width: 5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.15),
            blurRadius: 60,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          color: const Color(0xFFF8FAFC),
          child: Column(
            children: [
              // Status bar
              Container(
                color: const Color(0xFF1E3B8B),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('9:41',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Icon(Icons.signal_cellular_4_bar,
                            color: Colors.white70, size: 10),
                        SizedBox(width: 4),
                        Icon(Icons.wifi, color: Colors.white70, size: 10),
                        SizedBox(width: 4),
                        Icon(Icons.battery_full,
                            color: Colors.white70, size: 10),
                      ],
                    ),
                  ],
                ),
              ),
              // App header
              Container(
                color: const Color(0xFF1E3B8B),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Icon(Icons.menu, color: Colors.white, size: 18),
                    Text('Akrab Pharma',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
              // Map area
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      color: const Color(0xFFE5E7EB),
                      child: Center(
                        child: Icon(Icons.map_rounded,
                            size: 60, color: Colors.grey.shade400),
                      ),
                    ),
                    // Pharmacy pins
                    Positioned(
                      top: 50,
                      left: 70,
                      child: _MapPin(color: const Color(0xFF10B981)),
                    ),
                    Positioned(
                      top: 120,
                      right: 45,
                      child: _MapPin(color: const Color(0xFF1E3B8B)),
                    ),
                    Positioned(
                      top: 200,
                      left: 110,
                      child: _MapPin(color: const Color(0xFFEF4444)),
                    ),
                    // Bottom card
                    Positioned(
                      bottom: 12,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12, blurRadius: 8)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Open',
                                      style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981))),
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text('صيدلية المساعدة',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF111827))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('0.3 km • قالمة',
                                style: TextStyle(
                                    fontSize: 9, color: Colors.grey.shade500)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3B8B),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text('اتصال',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3B8B)
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text('اتجاه',
                                          style: TextStyle(
                                              color: Color(0xFF1E3B8B),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Map Pin ─────────────────────────────────────────────────────
class _MapPin extends StatelessWidget {
  final Color color;
  const _MapPin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.local_pharmacy,
          color: Colors.white, size: 14),
    );
  }
}

// ─── Grid Pattern Painter ────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 60.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Stats Section ───────────────────────────────────────────────
class _StatsSection extends StatelessWidget {
  final bool isDesktop;
  const _StatsSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : 24, vertical: 50),
      color: Colors.white,
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _stats
                  .map((s) => _StatItem(
                      value: s.$1, label: s.$2, icon: s.$3))
                  .toList(),
            )
          : Wrap(
              spacing: 24,
              runSpacing: 32,
              alignment: WrapAlignment.center,
              children: _stats
                  .map((s) => SizedBox(
                        width: (MediaQuery.of(context).size.width - 72) / 2,
                        child: _StatItem(
                            value: s.$1, label: s.$2, icon: s.$3),
                      ))
                  .toList(),
            ),
    );
  }

  static const _stats = [
    ('88+', 'صيدلية مسجلة', Icons.local_pharmacy_outlined),
    ('58', 'ولاية', Icons.map_outlined),
    ('24/7', 'خدمة مستمرة', Icons.access_time_outlined),
    ('0 د.ج', 'مجاني بالكامل', Icons.volunteer_activism_outlined),
  ];
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatItem(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3B8B).withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF1E3B8B), size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E3B8B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ─── Features Section ────────────────────────────────────────────
class _FeaturesSection extends StatelessWidget {
  final bool isDesktop;
  const _FeaturesSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        Icons.location_on_outlined,
        'تحديد الموقع',
        'اعثر على أقرب صيدلية مناوبة تلقائياً عبر GPS'
      ),
      (
        Icons.nightlight_round,
        'المناوبة الليلية',
        'اعثر على صيدلية مناوبة ليلية في منطقتك'
      ),
      (
        Icons.phone_rounded,
        'اتصال مباشر',
        'اتصل بالصيدلية مباشرة بضغطة زر واحدة'
      ),
      (
        Icons.report_outlined,
        'الإبلاغ',
        'أبلغ عن أي خطأ في بيانات الصيدلية'
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : 24, vertical: 60),
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          const Text(
            'لماذا Akrab Pharma؟',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'كل ما تحتاجه للعثور على صيدلية مناوبة في مكان واحد',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 48),
          isDesktop
              ? Row(
                  children: features
                      .map((f) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: _FeatureCard(
                                  icon: f.$1, title: f.$2, desc: f.$3),
                            ),
                          ))
                      .toList(),
                )
              : Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: features
                      .map((f) => SizedBox(
                            width: (MediaQuery.of(context).size.width - 64) /
                                2,
                            child: _FeatureCard(
                                icon: f.$1, title: f.$2, desc: f.$3),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureCard(
      {required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3B8B), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 8),
          Text(desc,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500, height: 1.5)),
        ],
      ),
    );
  }
}

// ─── Footer ──────────────────────────────────────────────────────
class _FooterSection extends StatelessWidget {
  final bool isDesktop;
  const _FooterSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(top: BorderSide(color: Color(0xFF1F2937))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '© 2026 Akrab Pharma. All rights reserved.',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withOpacity(0.5)),
          ),
          Text(
            'Open Source · Built with ❤',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
