import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              size: 100,
              color: AppTheme.gold,
            ).animate().fade(duration: 800.ms).scale(delay: 400.ms),
            const SizedBox(height: 24),
            Text(
              'MEMORY\nDETECTIVE',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppTheme.gold,
                height: 1.1,
              ),
            ).animate().fade(delay: 800.ms).slideY(),
            const SizedBox(height: 16),
            Text(
              'TRAIN YOUR BRAIN',
              style: GoogleFonts.inter(
                fontSize: 16,
                letterSpacing: 2,
                color: AppTheme.textPrimary,
              ),
            ).animate().fade(delay: 1200.ms),
            const SizedBox(height: 60),
            const CircularProgressIndicator(color: AppTheme.gold)
                .animate()
                .fade(delay: 1600.ms),
          ],
        ),
      ),
    );
  }
}
