import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../payment.dart';
 // Make sure to create this file

class CourseEnrollPage extends StatefulWidget {
  final DocumentSnapshot course;

  CourseEnrollPage({required this.course});

  @override
  _CourseEnrollPageState createState() => _CourseEnrollPageState();
}

class _CourseEnrollPageState extends State<CourseEnrollPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isEnrolled = false;
  List<String> courseOutlines = [];

  @override
  void initState() {
    super.initState();
    _checkEnrollmentStatus();
    
    _fetchCourseOutline();
  }

  Future<void> _checkEnrollmentStatus() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      List<dynamic> enrolledCourses = userDoc['enrolledCourses'] ?? [];
      setState(() {
        isEnrolled = enrolledCourses.contains(widget.course.id);
      });
    }
  }

  Future<void> _fetchCourseOutline() async {
    try {
      List<String> outlines = await fetchCourseOutline(widget.course['courseName']);
      setState(() {
        courseOutlines = outlines;
      });
    } catch (e) {
      print('Error fetching course outline: $e');
    }
  }

  Future<String?> _getUserId() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return userDoc.id;
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
    return null;
  }

  Future<void> _navigateToPaymentPage() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      String userName = userDoc['name'] ?? 'User';
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            userName: userName,
            userId: user.uid,
            courseName: widget.course['courseName'],
            courseDuration: widget.course['courseDuration'],
            difficultyLevel: widget.course['difficultyLevel'],
            courseFee: widget.course['courseFee'],
          ),
        ),
      );

      // Enroll the user in the course after returning from the payment page
      await _enrollInCourse();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Unable to fetch user data. Please try again.'),
      ));
    }
  }

  Future<void> _enrollInCourse() async {
    String? userId = await _getUserId();
    if (userId != null) {
      await _updateEnrollment(userId);
      setState(() {
        isEnrolled = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enrolled successfully!'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Unable to enroll. Please try again.'),
      ));
    }
  }

  Future<void> _updateEnrollment(String userId) async {
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    // Update user's enrolled courses
    await userRef.update({
      'enrolledCourses': FieldValue.arrayUnion([widget.course.id])
    });

    // Update the enrolled count in the course document
    DocumentReference courseRef = FirebaseFirestore.instance.collection('courses').doc(widget.course.id);
    await courseRef.update({
      'enrolled': FieldValue.increment(1) // Increment the enrolled field by 1
    });
  }

  Future<List<String>> fetchCourseOutline(String courseName) async {
    String apiKey = '1f9eb51f009d49f0ab49551c77ae8793'; // Replace with your Bing API key
    String url = 'https://api.bing.microsoft.com/v7.0/search?q=${Uri.encodeComponent(courseName)}';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Ocp-Apim-Subscription-Key': apiKey,
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      var webPages = jsonResponse['webPages']['value'] as List;

      int resultCount = webPages.length >= 4 ? 4 : webPages.length;

      List<String> outlines = [];
      for (int i = 0; i < resultCount; i++) {
        outlines.add(webPages[i]['snippet'] ?? 'No content available');
      }

      return outlines;
    } else {
      throw Exception('Failed to fetch course outline');
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final bool isPaid = course['isPaid'] ?? false;
    final double courseFee = course['courseFee'] ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.blue.shade50, // Add background color
      appBar: AppBar(
        title: Text('Enroll in ${course['courseName']}'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Title Section
            Text(
              course['courseName'],
              style: TextStyle(
                fontSize: 26.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 8.0),

            // Course Difficulty, Hours, Learners, Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${course['difficultyLevel']} • ${course['courseDuration']}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.yellow.shade600),
                    SizedBox(width: 4.0),
                    Text('${course['rating']}/5'),
                    SizedBox(width: 16.0),
                    Text('${course['enrolled']} enrolled'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.0),

            // Enroll and Premium Buttons
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: isEnrolled ? null : () async {
                      if (isPaid) {
                        await _navigateToPaymentPage();
                      } else {
                        await _enrollInCourse();
                      }
                    },
                    child: Text(
                      isEnrolled ? 'Already Enrolled' : (isPaid ? 'Go to Payment' : 'Enroll Now'),
                      style: TextStyle(color: isEnrolled ? Colors.white : Colors.blue),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnrolled ? Colors.blue : Colors.white,
                      side: BorderSide(color: Colors.blue, width: 2),
                      padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0), // Rectangular shape
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      // Premium button action
                    },
                    child: Text(
                      'Go Premium',
                      style: TextStyle(color: Colors.blue),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.blue, width: 2),
                      padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.0),

            // Course Description
            Text(
              course['description'] ?? 'No description available.',
              style: TextStyle(fontSize: 16.0, color: Colors.blueGrey),
            ),
            SizedBox(height: 24.0),

            // Certificate Demo Section
            Center(
              child: Column(
                children: [
                  Text(
                    'Certificate of Completion',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Card(
                    elevation: 4,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 200, // Adjust height according to your certificate design
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/certificate_demo.png'), // Ensure you have this image in your assets
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.0),

            // Skills you'll learn section
            Text(
              'Skills you\'ll learn',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: (course['skillsEarn'] is String
                  ? (course['skillsEarn'] as String).split(',')
                  : course['skillsEarn']).map<Widget>((skill) {
                return Chip(
                  label: Text(skill.trim()),
                  backgroundColor: Colors.blue.shade100,
                );
              }).toList(),
            ),
            SizedBox(height: 24.0),

            // Course Outline section (dynamically fetched)
            Text(
              'Course Outline',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 8.0),

            courseOutlines.isNotEmpty
                ? Column(
                    children: List.generate(
                      courseOutlines.length < 4 ? courseOutlines.length : 4,
                      (index) {
                        return ExpansionTile(
                          title: Text('Topic ${index + 1}',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.add), // Plus icon
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(courseOutlines[index]),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                : CircularProgressIndicator(), // Loading indicator

            SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
