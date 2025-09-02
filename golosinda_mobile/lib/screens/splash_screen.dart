import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';
 
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
 
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
 
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    getIsLogin();
  }
 
  Future<void> getIsLogin() async {
    final userData = await UserService().getUserData();
 
    if (userData['token'] != null && userData['token'] != '') {
      // User is logged in
      Timer(
        const Duration(seconds: 4),
        () => Navigator.popAndPushNamed(context, '/home'),
      );
    } else {
      // User is not logged in
      Timer(
        const Duration(seconds: 4),
        () => Navigator.popAndPushNamed(context, '/login'),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        height: ScreenUtil().screenHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            SizedBox(
              height: ScreenUtil().setHeight(120),
              child: Image.asset(
                'assets/images/numanika.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            // Loader
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}