import 'dart:math';
import 'package:dr_ai/utils/constant/color.dart';
import 'package:dr_ai/utils/constant/image.dart';
import 'package:dr_ai/utils/helper/extention.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';

class NFCScreen extends StatefulWidget {
  const NFCScreen({super.key});

  @override
  State<NFCScreen> createState() => _NFCScreenState();
}

class _NFCScreenState extends State<NFCScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _isScanning = false);
      _showHardwareDialog();
    });
  }

  void _showHardwareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.nfc_rounded, color: ColorManager.green, size: 24.r),
            Gap(8.w),
            const Text("NFC Not Available"),
          ],
        ),
        content: const Text(
          "NFC card scanning requires compatible NFC hardware. "
          "This feature will be fully functional on supported devices "
          "with an NFC-enabled patient card.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Got it",
                style: TextStyle(color: ColorManager.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Gap(context.height * 0.06),
              Text(
                "NFC Patient Card",
                style: context.textTheme.titleLarge?.copyWith(
                  fontSize: 22.spMin,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gap(8.h),
              Text(
                "Scan your patient card to instantly load your medical profile",
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 14.spMin,
                  color: ColorManager.grey,
                ),
              ),
              Gap(context.height * 0.06),

              // Animated NFC icon with ripple rings
              SizedBox(
                height: context.width * 0.72,
                width: context.width * 0.72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple rings
                    if (_isScanning) ...[
                      _RippleRing(delay: 0, color: ColorManager.green),
                      _RippleRing(delay: 600, color: ColorManager.green),
                      _RippleRing(delay: 1200, color: ColorManager.green),
                    ],
                    // Pulsing icon container
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: context.width * 0.42,
                        height: context.width * 0.42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorManager.green.withOpacity(0.08),
                          border: Border.all(
                            color: ColorManager.green.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            ImageManager.nfcIcon,
                            width: context.width / 4,
                            height: context.width / 4,
                            color: _isScanning
                                ? ColorManager.green
                                : ColorManager.green.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Gap(context.height * 0.02),

              // Status text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isScanning
                    ? Column(
                        key: const ValueKey('scanning'),
                        children: [
                          Text(
                            "Scanning...",
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: ColorManager.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 16.spMin,
                            ),
                          ),
                          Gap(6.h),
                          Text(
                            "Hold your NFC card near the back of your device",
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: ColorManager.grey,
                              fontSize: 13.spMin,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('idle'),
                        children: [
                          Text(
                            "Ready to Scan",
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: ColorManager.grey,
                              fontWeight: FontWeight.w500,
                              fontSize: 16.spMin,
                            ),
                          ),
                          Gap(6.h),
                          Text(
                            "Tap the button below to begin",
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: ColorManager.grey,
                              fontSize: 13.spMin,
                            ),
                          ),
                        ],
                      ),
              ),

              const Spacer(),

              // Info cards
              _InfoCard(
                icon: Icons.credit_card_rounded,
                title: "Patient Card",
                subtitle: "Stores your medical profile and emergency contacts",
              ),
              Gap(12.h),
              _InfoCard(
                icon: Icons.lock_rounded,
                title: "Secure & Encrypted",
                subtitle: "Your data is protected with AES-256 encryption",
              ),
              Gap(24.h),

              // Scan button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isScanning ? null : _startScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.green,
                    disabledBackgroundColor: ColorManager.green.withOpacity(0.5),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isScanning ? "Scanning..." : "Start NFC Scan",
                    style: TextStyle(
                      color: ColorManager.white,
                      fontSize: 16.spMin,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Gap(24.h),
            ],
          ),
        ),
      ),
    );
  }
}

// Ripple ring animation widget
class _RippleRing extends StatefulWidget {
  final int delay;
  final Color color;
  const _RippleRing({required this.delay, required this.color});

  @override
  State<_RippleRing> createState() => _RippleRingState();
}

class _RippleRingState extends State<_RippleRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: context.width * 0.68,
              height: context.width * 0.68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Info card widget
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ColorManager.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorManager.green.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: ColorManager.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ColorManager.green, size: 20.r),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.spMin,
                  ),
                ),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: ColorManager.grey,
                    fontSize: 12.spMin,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
