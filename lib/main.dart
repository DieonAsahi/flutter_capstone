import 'package:aplikasi/pages/addclothes.dart';
import 'package:aplikasi/pages/bodyshape.dart';
import 'package:aplikasi/pages/chatbot.dart';
import 'package:aplikasi/pages/customoutfit.dart';
import 'package:aplikasi/pages/detectskintone.dart';
import 'package:aplikasi/pages/editprofile.dart';
import 'package:aplikasi/pages/explorepage.dart';
// import 'package:aplikasi/pages/favoritepage.dart';
import 'package:aplikasi/pages/feedback.dart';
import 'package:aplikasi/pages/homepage.dart';
import 'package:aplikasi/pages/loginpage.dart';
import 'package:aplikasi/pages/profilepage.dart';
import 'package:aplikasi/pages/recommendation.dart';
import 'package:aplikasi/pages/registerpage.dart';
import 'package:aplikasi/pages/searchpage.dart';
import 'package:aplikasi/pages/settings.dart';
import 'package:aplikasi/pages/styleanalist.dart';
import 'package:aplikasi/pages/wardrobepage.dart';
import 'package:aplikasi/pages/landingpage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stylo',
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      home: LandingPage(),
  
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => MainPage(),
        '/profile': (context) => ProfilePage(),
        '/bodyshape': (context) => BodyShapePage(),
        '/addclothes': (context) => AddClothPage(),
        '/skintone': (context) => SkinDetectPage(),
        '/analysis': (context) => StylePage(),
        '/recommendation': (context) => RecommendationPage(),
        '/custom': (context) => CustomOutfitPage(),
        '/chatbot': (context) => ChatbotPage(),
        '/explore': (context) => ExplorePage(),
        '/wardrobe': (context) => WardrobePage(),
        // '/favorite': (context) => FavoritePage(),
        '/settings': (context) => SettingsPage(),
        '/editprofile': (context) => EditProfilePage(),
        '/feedback': (context) => FeedbackPage(),

      },
    );
  }
}


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final Color primaryColor = Color(0xFFA79277);

  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    WardrobePage(),
    ExplorePage(),
    ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Cari',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom),
            label: 'Lemari',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Jelajah',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
