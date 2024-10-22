
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'AdminCourseEditPage.dart';


class AdminCourseListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Course List'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, snapshot) {
          // Add logging
          print('Connection State: ${snapshot.connectionState}');
          print('Has Error: ${snapshot.hasError}');
          print('Has Data: ${snapshot.hasData}');

          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No data available'));
          }

          var courses = snapshot.data!.docs;
          print('Number of courses: ${courses.length}');

          if (courses.isEmpty) {
            return Center(child: Text('No courses available'));
          }

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              var course = courses[index];
              print('Course ${index + 1}: ${course['courseName']}');
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(course['courseName'] ?? 'No name'),
                  subtitle: Text('Duration: ${course['courseDuration'] ?? 'Not specified'}'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminEditCoursePage(courseName: course['courseName'] ?? '', courseId: '',),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          // Navigate to course creation page
          print('Add course button pressed');
        },
      ),
    );
  }
}
