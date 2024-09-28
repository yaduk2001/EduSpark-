// otp_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../Dashboard/StudentDashboardPage.dart';
 // Dashboard Page

class OTPPage extends StatefulWidget {
  final bool isEmail; // Determines if it's Email OTP or Mobile OTP
  final String phoneNumber; // Phone number for Mobile OTP

  OTPPage({required this.isEmail, this.phoneNumber = ''});

  @override
  _OTPPageState createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  String _verificationId = '';
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    if (!widget.isEmail) {
      _startPhoneNumberVerification();
    }
  }

  // Function to start phone number verification
  Future<void> _startPhoneNumberVerification() async {
    if (widget.phoneNumber.isEmpty) {
      Fluttertoast.showToast(
        msg: "Phone number is required for OTP verification.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      Navigator.pop(context);
      return;
    }

    _phoneNumber = widget.phoneNumber;

    setState(() {
      _isLoading = true;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: _phoneNumber,
      timeout: Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval or instant verification
        await _auth.signInWithCredential(credential);
        _navigateToDashboard();
      },
      verificationFailed: (FirebaseAuthException e) {
        Fluttertoast.showToast(
          msg: "Phone number verification failed. ${e.message}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() {
          _isLoading = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        setState(() {
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  // Function to verify OTP entered by user
  Future<void> _verifyOTP() async {
    String smsCode = _otpController.text.trim();

    if (smsCode.length != 6) {
      Fluttertoast.showToast(
        msg: "Please enter a 6-digit OTP.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);
      _navigateToDashboard();
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to verify OTP. ${e.message}",
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

  // Navigate to Student Dashboard
  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StudentDashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEmail ? 'Email OTP Login' : 'Mobile OTP Login'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: widget.isEmail
                  ? _buildEmailOTPLogin()
                  : _buildMobileOTPLogin(),
            ),
    );
  }

  // Placeholder for Email OTP Login (Not Implemented)
  Widget _buildEmailOTPLogin() {
    return Center(
      child: Text(
        'Email OTP Login is not implemented.\nPlease use email/password or Google Sign-In.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  // UI for Mobile OTP Login
  Widget _buildMobileOTPLogin() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Enter the OTP sent to $_phoneNumber',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'OTP',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _verifyOTP,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            backgroundColor: Colors.teal,
          ),
          child: Text(
            'Verify OTP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
