import 'package:dr_ai/utils/constant/image.dart';
import 'package:dr_ai/utils/constant/routes.dart';
import 'package:dr_ai/utils/helper/extention.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import '../../../utils/constant/color.dart';
import '../../../logic/chat/chat_cubit.dart';
import '../../widget/contact_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(40.h),
                  _buildHeader(context),
                  Gap(24.h),
                  _buildChatCard(context),
                  Gap(24.h),
                  _buildSectionTitle(context, "Quick Stats"),
                  Gap(12.h),
                  _buildStatsRow(context),
                  Gap(24.h),
                  _buildSectionTitle(context, "Health Tips"),
                  Gap(12.h),
                  _buildHealthTips(context),
                  Gap(24.h),
                  _buildSectionTitle(context, "Emergency Contacts"),
                  Gap(12.h),
                  _buildContactsCard(),
                  Gap(32.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good day 👋",
              style: context.textTheme.bodySmall?.copyWith(
                color: ColorManager.grey,
                fontSize: 13.spMin,
              ),
            ),
            Gap(2.h),
            Text(
              "Doctor AI",
              style: context.textTheme.displayLarge?.copyWith(
                fontSize: 24.spMin,
                fontWeight: FontWeight.bold,
                color: ColorManager.black,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: ColorManager.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.asset(
            ImageManager.userIcon,
            width: 22.w,
            height: 22.w,
            color: ColorManager.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.textTheme.bodyMedium?.copyWith(
        fontSize: 15.spMin,
        fontWeight: FontWeight.w700,
        color: ColorManager.black,
      ),
    );
  }

  Widget _buildChatCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.bloc<ChatCubit>().initHive();
        Navigator.pushNamed(context, RouteManager.chat);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorManager.green,
              ColorManager.green.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ColorManager.green.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: EdgeInsets.all(20.r),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: ColorManager.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "AI Powered",
                      style: TextStyle(
                        color: ColorManager.white,
                        fontSize: 11.spMin,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Gap(10.h),
                  Text(
                    "Chat with\nDoctor AI",
                    style: context.textTheme.displayLarge?.copyWith(
                      fontSize: 20.spMin,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.white,
                      height: 1.2,
                    ),
                  ),
                  Gap(8.h),
                  Text(
                    "Ask medical questions & get\npersonalized health guidance",
                    style: context.textTheme.bodySmall?.copyWith(
                      color: ColorManager.white.withOpacity(0.85),
                      fontSize: 12.spMin,
                      height: 1.4,
                    ),
                  ),
                  Gap(16.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 18.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: ColorManager.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Start Chat",
                          style: TextStyle(
                            color: ColorManager.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.spMin,
                          ),
                        ),
                        Gap(6.w),
                        Icon(Icons.arrow_forward_rounded,
                            color: ColorManager.green, size: 16.r),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Image.asset(
                ImageManager.robotIcon,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(
          context,
          icon: Icons.favorite_rounded,
          label: "Heart Rate",
          value: "72 bpm",
          color: const Color(0xffF85555),
        ),
        Gap(12.w),
        _buildStatCard(
          context,
          icon: Icons.water_drop_rounded,
          label: "Blood O2",
          value: "98%",
          color: ColorManager.darkBlue,
        ),
        Gap(12.w),
        _buildStatCard(
          context,
          icon: Icons.thermostat_rounded,
          label: "Temp",
          value: "36.6°",
          color: ColorManager.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: ColorManager.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18.r),
            ),
            Gap(8.h),
            Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13.spMin,
                color: ColorManager.black,
              ),
            ),
            Gap(2.h),
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 10.spMin,
                color: ColorManager.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTips(BuildContext context) {
    final tips = [
      _HealthTip(
        icon: Icons.local_drink_rounded,
        color: ColorManager.darkBlue,
        title: "Stay Hydrated",
        subtitle: "Drink 8 glasses of water daily",
      ),
      _HealthTip(
        icon: Icons.directions_walk_rounded,
        color: ColorManager.green,
        title: "Daily Steps",
        subtitle: "Aim for 10,000 steps per day",
      ),
      _HealthTip(
        icon: Icons.bedtime_rounded,
        color: ColorManager.orange,
        title: "Quality Sleep",
        subtitle: "Get 7–9 hours every night",
      ),
    ];

    return SizedBox(
      height: 100.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tips.length,
        separatorBuilder: (_, __) => Gap(12.w),
        itemBuilder: (context, index) => _buildTipCard(context, tips[index]),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, _HealthTip tip) {
    return Container(
      width: 160.w,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: tip.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tip.color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color: tip.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tip.icon, color: tip.color, size: 18.r),
          ),
          Gap(10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tip.title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.spMin,
                    color: ColorManager.black,
                  ),
                ),
                Gap(4.h),
                Text(
                  tip.subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 10.spMin,
                    color: ColorManager.grey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsCard() {
    return const Row(
      children: [
        ContactCard(
          image: ImageManager.ambulanceIcon,
          title: "Ambulance",
          number: "123",
          color: ColorManager.green,
        ),
        ContactCard(
          image: ImageManager.policeIcon,
          title: "Emergency",
          number: "112",
          color: ColorManager.darkBlue,
        ),
        ContactCard(
          image: ImageManager.firefightingIcon,
          title: "Firefighting",
          number: "180",
          color: ColorManager.orange,
        ),
      ],
    );
  }
}

class _HealthTip {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _HealthTip({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
