import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import '../Login Pages/student_login.dart';

class StudentDashboardPage extends StatefulWidget {
  @override
  _StudentDashboardPageState createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? _currentUser;
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;

  XFile? _profileImage; // For storing locally picked image
  String? _profileImageUrl; // For storing image URL from Firebase Storage

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  // Fetch student data and load profile picture from Firebase Storage if available
  Future<void> _fetchStudentData() async {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      DocumentSnapshot doc =
          await _firestore.collection('students').doc(_currentUser!.uid).get();
      if (doc.exists) {
        setState(() {
          _studentData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });

        // Load profile image from Firebase Storage
        try {
          String downloadUrl = await _storage
              .ref('profile_pictures/${_currentUser!.uid}')
              .getDownloadURL();
          setState(() {
            _profileImageUrl = downloadUrl;
          });
        } catch (e) {
          // Handle if no profile picture found
          print("No profile picture found.");
        }
      } else {
        _handleNoStudentData();
      }
    } else {
      _navigateToLogin();
    }
  }

  Future<void> _handleNoStudentData() async {
    setState(() {
      _isLoading = false;
    });
    Fluttertoast.showToast(
      msg: "No student data found. Please register again.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StudentLoginPage()),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    _navigateToLogin();
  }

  // Pick and upload profile image to Firebase Storage
  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = pickedImage;
      });
      // Upload to Firebase Storage
      try {
        await _storage
            .ref('profile_pictures/${_currentUser!.uid}')
            .putFile(File(pickedImage.path));
        String downloadUrl = await _storage
            .ref('profile_pictures/${_currentUser!.uid}')
            .getDownloadURL();
        setState(() {
          _profileImageUrl = downloadUrl;
        });
        Fluttertoast.showToast(
          msg: "Profile picture updated.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } catch (e) {
        print(e);
        Fluttertoast.showToast(
          msg: "Failed to upload profile picture.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Dashboard'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildNavigationDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _studentData != null
              ? _buildStudentDetails()
              : Center(
                  child: Text(
                    'No student data found.',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Build Navigation Drawer with more options
  Drawer _buildNavigationDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : AssetImage('assets/default_profile.png') as ImageProvider,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _studentData != null ? _studentData!['name'] : 'Student',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.edit, 'Edit Profile', () {}),
          _buildDrawerItem(Icons.verified, 'Certificates', () {}),
          _buildDrawerItem(Icons.support, 'Support', () {}),
          _buildDrawerItem(Icons.feedback, 'Feedback', () {}),
          _buildDrawerItem(Icons.card_giftcard, 'Rewards', () {}),
          _buildDrawerItem(Icons.insights, 'Progress', () {}),
          _buildDrawerItem(Icons.star, 'Premium Subscription', () {}),
          _buildDrawerItem(Icons.logout, 'Logout', _logout),
        ],
      ),
    );
  }

  // Build drawer item with icon and label
  ListTile _buildDrawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }

  // Build Student Details UI
  Widget _buildStudentDetails() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blue[50]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : AssetImage('assets/default_profile.png') as ImageProvider,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Welcome, ${_studentData!['name']}!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow('Student ID', _studentData!['studentID']),
                      SizedBox(height: 10),
                      _buildDetailRow('Email', _studentData!['email']),
                      SizedBox(height: 10),
                      _buildDetailRow('Phone', _studentData!['phone']),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Divider(),
              _buildEnrolledCoursesSection(),
            ],
          ),
        ),
      ],
    );
  }

  // Build a row for student details
  Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
        ),
      ],
    );
  }

  // Build Enrolled Courses Section
  Widget _buildEnrolledCoursesSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enrolled Courses',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Expanded(
            child: _studentData!['enrolledCourses'] != null
                ? ListView.builder(
                    itemCount: _studentData!['enrolledCourses'].length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.book, color: Colors.blueAccent),
                          title: Text(_studentData!['enrolledCourses'][index]),
                          subtitle: Text('Track your progress'),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
                          onTap: () {
                            // Navigate to Course Detail Page
                          },
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'Enrolled courses will be displayed here.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Build Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.blueAccent,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Courses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      onTap: (index) {
        // Handle navigation between different sections
      },
    );
  }
}
