import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:golosinda_advmobprog/screens/chat_screen.dart';
import 'package:golosinda_advmobprog/screens/profile_screen.dart';
import 'package:golosinda_advmobprog/screens/settings_screen.dart';
import 'package:golosinda_advmobprog/services/user_service.dart'; // import UserService
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'article_screen.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  final PageController pageController = PageController();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: CustomText(
          text: selectedIndex == 0
              ? 'Home'
              : selectedIndex == 1
              ? 'Chat'
              : 'Profile',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: pageController,
        children: const <Widget>[
          ArticleScreen(),
          ChatScreen(),
          ProfileScreen(),
        ],
        onPageChanged: (page) {
          setState(() {
            selectedIndex = page;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: onTappedBar,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: selectedIndex,
      ),
    );
  }

  void onTappedBar(int value) {
    setState(() {
      selectedIndex = value;
    });
    pageController.jumpToPage(value);
  }
}
