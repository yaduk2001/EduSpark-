import 'package:flutter/material.dart';
import 'upi_payment.dart';


import 'BillPage.dart';

class PaymentPage extends StatelessWidget {
  final String courseName;
  final String userId;
  final double courseFee;
  final String userName;
  final String courseDuration;

  const PaymentPage({
    Key? key,
    required this.courseName,
    required this.userId,
    required this.courseFee,
    required this.userName,
    required this.courseDuration, required difficultyLevel,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: Colors.blue[800],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.white],
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    courseName,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Duration: $courseDuration',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Amount to Pay:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '₹${courseFee.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: Icon(Icons.payment),
                    label: Text('Pay with UPI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    onPressed: () => _initiatePayment(context),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Only UPI payments are accepted',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _initiatePayment(BuildContext context) {
    UpiPayment.initiateTransaction(
      amount: courseFee,
      note: 'Payment for $courseName',
    ).then((_) {
      // Simulate successful payment (in a real app, you'd verify the payment)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BillPage(
            userName: userName,
            courseName: courseName,
            courseDuration: courseDuration,
            amount: courseFee, userId: '', difficultyLevel: null, courseFee: null,

          ),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }
}
