import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- Navbar ---
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 60 : 20, vertical: 20),
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3B8B),
                            borderRadius: BorderRadius.circular(10),
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
                          const SizedBox(width: 30),
                          _navLink('الصيدليات'),
                          const SizedBox(width: 30),
                          _navLink('عن التطبيق'),
                        ],
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3B8B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text('دخول الصيادلة',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // --- Hero Section ---
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 60 : 20, vertical: 40),
                child: Flex(
                  direction: isDesktop ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Text Content
                    SizedBox(
                      width: isDesktop ? 600 : double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.access_time,
                                    size: 16, color: Color(0xFF10B981)),
                                SizedBox(width: 8),
                                Text(
                                  'صيدليات المناوبة — 22/07/2026',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Main Title
                          const Text(
                            'صيدليات المناوبة في ولاية قالمة بين يديك ✦',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E3B8B),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Description
                          const Text(
                            'ابحث عن أقرب صيدلية مفتوحة أو مناوبة ليلية في منطقتك بسرعة وسهولة. كن مستعداً لحالات الطوارئ.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF6B7280),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 30),
                          // CTA
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                ),
                                onPressed: () {},
                                icon: const Icon(Icons.search),
                                label: const Text(
                                  'ابحث عن صيدلية الآن',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isDesktop) const SizedBox(height: 40),
                    // Phone Mockup
                    Container(
                      width: 280,
                      height: 540,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(40),
                        border:
                            Border.all(color: const Color(0xFF374151), width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          color: const Color(0xFFF9FAFB),
                          child: Column(
                            children: [
                              Container(
                                color: const Color(0xFF1E3B8B),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('Akrab Pharma',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    Icon(Icons.map,
                                        color: Colors.white, size: 14),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      color: const Color(0xFFE5E7EB),
                                      child: const Center(
                                        child: Icon(Icons.map_outlined,
                                            size: 80, color: Color(0xFF9CA3AF)),
                                      ),
                                    ),
                                    const Positioned(
                                        top: 80,
                                        left: 100,
                                        child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Color(0xFF10B981),
                                            child: Icon(Icons.local_pharmacy,
                                                size: 12,
                                                color: Colors.white))),
                                    const Positioned(
                                        top: 180,
                                        right: 60,
                                        child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Color(0xFF1E3B8B),
                                            child: Icon(Icons.local_pharmacy,
                                                size: 12,
                                                color: Colors.white))),
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 5)
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text('صيدلية المساعدة قالمة',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Color(
                                                        0xFF1E3B8B))),
                                            SizedBox(height: 4),
                                            Text('Night • Closed',
                                                style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.orange,
                                                    fontWeight:
                                                        FontWeight.bold)),
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

  Widget _navLink(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }
}
