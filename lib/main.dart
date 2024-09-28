import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'Landing Pages/onboarding_page.dart'; // Import for Firebase

// Firebase configuration from your JSON file
const firebaseConfig = {
  "project_info": {
    "project_number": "1055251300642",
    "project_id": "eduspark-a0562",
    "storage_bucket": "eduspark-a0562.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:1055251300642:android:13ded8f371a4ba4ed3a57b",
        "android_client_info": {
          "package_name": "com.example.eduspark"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "AIzaSyBB3vxlYAH1-btrxdtfGQTEBkx413Nnzj0"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduSpark',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: OnboardingScreen(),
    );
  }
}


