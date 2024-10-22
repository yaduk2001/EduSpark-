import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

class UpiPayment {
  // Your UPI ID
  static const String receiverUpiId = 'yaduk874685-1@okicici';
  static const String receiverName = 'EduSpark'; // You can change this to your preferred name

  static final _appLinks = AppLinks();

  static Future<void> initiateTransaction({
    required double amount,
    required String note,
  }) async {
    final upiUrl = Uri.encodeFull(
      'upi://pay?pa=$receiverUpiId&pn=$receiverName&am=${amount.toStringAsFixed(2)}&tn=$note'
    );
    
    if (await canLaunch(upiUrl)) {
      await launch(upiUrl);
    } else {
      throw 'Could not launch UPI app';
    }
  }

  static void handleIncomingLinks(BuildContext context) {
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleLink(uri, context);
      }
    });
  }

  static void _handleLink(Uri uri, BuildContext context) {
    final status = uri.queryParameters['Status'];
    final txnId = uri.queryParameters['txnId'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${status ?? 'Unknown'}'),
            Text('Transaction ID: ${txnId ?? 'Not available'}'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
