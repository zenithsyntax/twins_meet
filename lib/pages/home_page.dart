import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twins_meet/pages/list_page.dart';

class TwinsHomePage extends StatelessWidget {
  const TwinsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFdaedfc),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 60.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Twins Directory',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Text(
                    'SS. Gervasis & Prothasis Forane\nChurch, Kothanalloor',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 18.sp,
                      color: const Color(0xFF416587),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Image fixed at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/home.png', // only bottom part of the church
              width: 1.sw, // full screen width
              fit: BoxFit.fitWidth,
            ),
          ),

          // Optional arrow button
          Positioned(
            bottom: 24.h,
            right: 24.w,
            child: GestureDetector(
              onTap: () {
                // Navigate to the twins listing page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TwinListPage(),
                  ),
                );
              },
              child: Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF416587),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF416587).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
