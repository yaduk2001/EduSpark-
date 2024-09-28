import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math';

class StudentRegistrationPage extends StatefulWidget {
  @override
  _StudentRegistrationPageState createState() =>
      _StudentRegistrationPageState();
}

class _StudentRegistrationPageState extends State<StudentRegistrationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordValid = false;

  // Password validation regex pattern
  final String passwordPattern =
      r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%\^&\*]).{8,}$';

  // Function to generate random Student ID
  Future<String> _generateUniqueStudentID() async {
    String studentID = '';
    bool isUnique = false;

    while (!isUnique) {
      studentID = 'S' + Random().nextInt(999999).toString().padLeft(6, '0');

      // Check Firestore to ensure the Student ID is unique
      QuerySnapshot result = await _firestore
          .collection('students')
          .where('studentID', isEqualTo: studentID)
          .get();

      if (result.docs.isEmpty) {
        isUnique = true;
      }
    }

    return studentID;
  }

  // Function to send email verification
  Future<void> _sendEmailVerification(User user) async {
    await user.sendEmailVerification();
  }

  // Password validation function
  bool _validatePassword(String password) {
    RegExp regExp = RegExp(passwordPattern);
    return regExp.hasMatch(password);
  }

  // Registration function
  Future<void> _registerStudent() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create user with Firebase Authentication
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null) {
          // Generate unique Student ID
          String studentID = await _generateUniqueStudentID();

          // Store user data in Firestore (users collection)
          await _firestore.collection('users').doc(user.uid).set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': 'student',
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Store student-specific data in Firestore (students collection)
          await _firestore.collection('students').doc(user.uid).set({
            'studentID': studentID,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Send email verification
          await _sendEmailVerification(user);

          // Show success toast
          Fluttertoast.showToast(
            msg: "Registration successful! Please verify your email.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          // Redirect to login page after successful registration
          Navigator.of(context).pop(); // Navigate back to login
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'An error occurred. Please try again.';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already in use.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        }
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: "An unexpected error occurred.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordListener);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePasswordListener);
    _passwordController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePasswordListener() {
    setState(() {
      _isPasswordValid = _validatePassword(_passwordController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Registration'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Logo or Header
                    Hero(
                      tag: 'logo',
                      child: Icon(
                        Icons.school,
                        size: 100,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      'Register to Edu Spark',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                            .hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (!RegExp(r'^\+?\d{10,15}$')
                            .hasMatch(value.trim())) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: _isPasswordValid
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.cancel, color: Colors.red),
                      ),
                      style: TextStyle(
                        color: _isPasswordValid ? Colors.green : Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (!_isPasswordValid) {
                          return 'Password must be at least 8 characters,\nstart with a capital letter,\ninclude numbers and special characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // Password Criteria Feedback
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPasswordCriteria(
                            'At least 8 characters',
                            _passwordController.text.length >= 8),
                        _buildPasswordCriteria(
                            'Starts with a capital letter',
                            RegExp(r'^[A-Z]')
                                .hasMatch(_passwordController.text)),
                        _buildPasswordCriteria('Contains a number',
                            RegExp(r'[0-9]').hasMatch(_passwordController.text)),
                        _buildPasswordCriteria(
                            'Contains a special character',
                            RegExp(r'[!@#\$%\^&\*]')
                                .hasMatch(_passwordController.text)),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Register Button
                    ElevatedButton(
                      onPressed: _registerStudent,
                      child: Text('Register'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Login Redirect
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Navigate back to login
                      },
                      child: Text('Already have an account? Login'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPasswordCriteria(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check : Icons.close,
          color: isMet ? Colors.green : Colors.red,
        ),
        SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: isMet ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
