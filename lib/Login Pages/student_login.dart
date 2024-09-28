// student_login_page.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Dashboard/StudentDashboardPage.dart';
import '../Registration Pages/StudentRegistrationPage.dart'; //Student Registraion Page
import 'otp_page.dart'; // For OTP handling
// Dashboard Page
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StudentLoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<StudentLoginPage> {
  final _auth = FirebaseAuth.instance;
  String _emailOrID = '';
  String _password = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(30.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo or any trendy header
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
                      'Login to Edu Spark',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),

                    // Email or Student ID TextField
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        _emailOrID = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Email or Student ID',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Password TextField
                    TextField(
                      obscureText: true,
                      onChanged: (value) {
                        _password = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Login Button (Email/Password)
                    ElevatedButton(
                      onPressed: () async {
                        // Start loading
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          // Sign in with email and password
                          UserCredential userCredential = await _auth.signInWithEmailAndPassword(
                            email: _emailOrID,
                            password: _password,
                          );

                          User? user = userCredential.user;

                          if (user != null) {
                            if (user.emailVerified) {
                              // Navigate to Student Dashboard
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => StudentDashboardPage()),
                              );
                            } else {
                              // Prompt user to verify email
                              Fluttertoast.showToast(
                                msg: "Please verify your email before logging in.",
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.orange,
                                textColor: Colors.white,
                              );

                              // Optionally, resend verification email
                              bool resend = await _showResendVerificationDialog();
                              if (resend) {
                                await user.sendEmailVerification();
                                Fluttertoast.showToast(
                                  msg: "Verification email resent. Please check your inbox.",
                                  toastLength: Toast.LENGTH_LONG,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                );
                              }
                            }
                          }
                        } on FirebaseAuthException catch (e) {
                          String errorMessage = 'An error occurred. Please try again.';
                          if (e.code == 'user-not-found') {
                            errorMessage = 'No user found for that email.';
                          } else if (e.code == 'wrong-password') {
                            errorMessage = 'Wrong password provided.';
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

                        // Stop loading
                        setState(() {
                          _isLoading = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Google Sign-In Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          final googleUser = await GoogleSignIn().signIn();
                          if (googleUser != null) {
                            final googleAuth = await googleUser.authentication;
                            final credential = GoogleAuthProvider.credential(
                              accessToken: googleAuth.accessToken,
                              idToken: googleAuth.idToken,
                            );
                            UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
                            User? user = userCredential.user;

                            if (user != null && user.emailVerified) {
                              // Navigate to Student Dashboard
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => StudentDashboardPage()),
                              );
                            } else if (user != null && !user.emailVerified) {
                              Fluttertoast.showToast(
                                msg: "Please verify your email before logging in.",
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.orange,
                                textColor: Colors.white,
                              );
                              bool resend = await _showResendVerificationDialog();
                              if (resend) {
                                await user.sendEmailVerification();
                                Fluttertoast.showToast(
                                  msg: "Verification email resent. Please check your inbox.",
                                  toastLength: Toast.LENGTH_LONG,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                );
                              }
                            }
                          }
                        } catch (e) {
                          print(e); // Handle Google sign-in error
                          Fluttertoast.showToast(
                            msg: "Google sign-in failed. Please try again.",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                          );
                        }
                        setState(() {
                          _isLoading = false;
                        });
                      },
                      icon: FaIcon(FontAwesomeIcons.google, color: Colors.white),
                      label: Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                    SizedBox(height: 20),

                    // OTP Login Options
                    TextButton(
                      onPressed: () {
                        _showOTPOptions(context); // Choose OTP method
                      },
                      child: Text(
                        'Login with OTP',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Register Button
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StudentRegistrationPage()),
                        );
                      },
                      child: Text(
                        'Don\'t have an account? Register',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Dialog to choose between Email OTP or Mobile OTP
  void _showOTPOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.email, color: Colors.blueAccent),
                title: Text('Login with Email OTP'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OTPPage(isEmail: true),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text('Login with Mobile OTP'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OTPPage(isEmail: false),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialog to resend email verification
  Future<bool> _showResendVerificationDialog() async {
    bool resend = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Email Not Verified'),
        content: Text('Would you like to resend the verification email?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resend = false;
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resend = true;
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
    return resend;
  }
}
