import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kissan_connect/core/utils/route_const.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';

//Data Model
class _OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}

const List<_OnboardingPage> _pages = [
  _OnboardingPage(
    title: 'Welcome to',
    subtitle: 'KissanConnect',
    description:
        'Empowering farmers with modern technology. Connect, grow, and thrive with the smartest agricultural platform built just for you.',
    icon: Icons.agriculture_rounded,
    gradient: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
  ),
  _OnboardingPage(
    title: 'Smart Crop',
    subtitle: 'Advisory',
    description:
        'Get real-time expert advice on crop health, weather forecasts, and best farming practices tailored to your region and season.',
    icon: Icons.eco_rounded,
    gradient: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)],
  ),
  _OnboardingPage(
    title: 'Sell Your',
    subtitle: 'Produce Directly',
    description:
        'Cut out the middlemen! List your harvest and connect directly with buyers, getting the best price for all your hard work.',
    icon: Icons.storefront_rounded,
    gradient: [Color(0xFFE65100), Color(0xFFF57C00), Color(0xFFFFA726)],
  ),
  _OnboardingPage(
    title: 'Community',
    subtitle: '& Support',
    description:
        'Join thousands of farmers on KissanConnect. Share knowledge, ask questions, and grow together as one strong farming community.',
    icon: Icons.people_alt_rounded,
    gradient: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
  ),
];


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _animController.reset();
    _animController.forward();
  }

  void _next() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _skip() => _goToLogin();

  void _goToLogin() {
    RouteGenerator.navigateToPageWithoutStack(context, Routes.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentIndex];
    final size = MediaQuery.of(context).size;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: page.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, right: 20),
                  child: _currentIndex < _pages.length - 1
                      ? GestureDetector(
                          onTap: _skip,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.4)),
                            ),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 36),
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (_, index) =>
                      _PageContent(page: _pages[index], size: size),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${page.title} ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  TextSpan(
                                    text: page.subtitle,
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.75),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentIndex ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentIndex
                                ? Colors.white
                                : Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    GestureDetector(
                      onTap: _next,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentIndex == _pages.length - 1
                                ? 'Get Started 🌱'
                                : 'Next →',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: page.gradient.first,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Login shortcut (last page)
                    if (_currentIndex == _pages.length - 1)
                      GestureDetector(
                        onTap: _goToLogin,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Already have an account? ',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text: 'Log In',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                ),
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

//Page Content
class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  final Size size;

  const _PageContent({required this.page, required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Glowing icon circle
        Container(
          width: size.width * 0.55,
          height: size.width * 0.55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: size.width * 0.38,
              height: size.width * 0.38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
              ),
              child: Icon(
                page.icon,
                size: size.width * 0.22,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Small decorative dots row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.4 - i * 0.1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
