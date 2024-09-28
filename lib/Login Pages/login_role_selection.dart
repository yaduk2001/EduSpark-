import 'package:flutter/material.dart';
import 'student_login.dart';


class LoginRoleSelection extends StatefulWidget {
  @override
  _LoginRoleSelectionState createState() => _LoginRoleSelectionState();
}

class _LoginRoleSelectionState extends State<LoginRoleSelection> {
  String _selectedRole = 'Student'; // Default value

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Login to Edu Spark',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),

            // Dropdown to select role
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Select Role',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: ['Student', 'Parent', 'Teacher', 'Admin']
                  .map((role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            SizedBox(height: 20),

            // Button to navigate to selected role's login page
            ElevatedButton(
              onPressed: () {
                if (_selectedRole == 'Student') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StudentLoginPage()),
                  );
                } else if (_selectedRole == 'Teacher') {
                 // Navigator.push(
                  //  context,
                 //  MaterialPageRoute(builder: (context) => TeacherLoginPage()),
                 // );
             //   } else if (_selectedRole == 'Parent') {
               //   Navigator.push(
                  //  context,
                   // MaterialPageRoute(builder: (context) => ParentLoginPage()),
                 // );
                //} else if (_selectedRole == 'Admin') {
                 // Navigator.push(
                  //  context,
                  //  MaterialPageRoute(builder: (context) => AdminLoginPage()),
                 // );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30), backgroundColor: Colors.blueAccent,
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
