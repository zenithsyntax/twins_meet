import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:twins_meet/pages/form_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:twins_meet/pages/home_page.dart';
import 'package:twins_meet/pages/list_page.dart';
import 'firebase_options.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Twins Data Collection',
                    debugShowCheckedModeBanner: false,
          theme: ThemeData(
            // Primary colors
            primaryColor: const Color(0xFF416587),
            primarySwatch: MaterialColor(0xFF416587, {
              50: const Color(0xFFE8ECF1),
              100: const Color(0xFFC5D0E0),
              200: const Color(0xFF9FB3CD),
              300: const Color(0xFF7996BA),
              400: const Color(0xFF5D7FAB),
              500: const Color(0xFF416587), // Primary
              600: const Color(0xFF3A5D7A),
              700: const Color(0xFF32536C),
              800: const Color(0xFF2A495E),
              900: const Color(0xFF1C374B),
            }),
            
            // Secondary colors
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF416587),
              secondary: const Color(0xFF6E6588),
              background: Colors.white,
              surface: Colors.white,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onBackground: const Color(0xFF1F2937),
              onSurface: const Color(0xFF1F2937),
            ),
            
            // App bar theme
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF416587),
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
                color: Colors.white,
              ),
            ),
            
            // Card theme
            cardTheme: CardTheme(
              color: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            
            // Elevated button theme
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF416587),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              ),
            ),
            
            // Floating action button theme
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF416587),
              foregroundColor: Colors.white,
            ),
            
            // Input decoration theme
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFF416587), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              labelStyle: TextStyle(
                color: const Color(0xFF6B7280),
                fontSize: 14.sp,
              ),
              hintStyle: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: 14.sp,
              ),
            ),
            
            // Text theme
            textTheme: TextTheme(
              displayLarge: TextStyle(
                fontSize: 40.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6E6588),
              ),
              displayMedium: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF416587),
              ),
              displaySmall: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF416587),
              ),
              headlineLarge: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
              headlineMedium: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
              headlineSmall: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
              titleLarge: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
              titleMedium: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
              titleSmall: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
              bodyLarge: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF374151),
              ),
              bodyMedium: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF6B7280),
              ),
              bodySmall: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            
            useMaterial3: true,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: Colors.white,
          ),
          home: TwinsHomePage(),
        );
      },
    );
  }
}

