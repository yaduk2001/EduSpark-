import 'package:eduspark/Login%20Pages/login_role_selection.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          buildOnboardingPage(
            image: Icons.school,
            title: 'Welcome to Edu Spark',
            description: 'Your personal assistant for smarter learning.',
          ),
          buildOnboardingPage(
            image: Icons.people,
            title: 'Collaboration Made Easy',
            description: 'Engage with students, teachers, and parents effortlessly.',
          ),
          buildOnboardingPage(
            image: Icons.computer,
            title: 'AI-Powered Learning',
            description: 'Personalized recommendations and resources for better learning.',
          ),
          LoginRoleSelection(), // Final page takes to login role selection
        ],
      ),
    );
  }

  // Reusable widget to build each onboarding page
  Widget buildOnboardingPage({IconData? image, String? title, String? description}) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            image,
            size: 150,
            color: Colors.blueAccent,
          ),
          SizedBox(height: 30),
          Text(
            title!,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            description!,
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
