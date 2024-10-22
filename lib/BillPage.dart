import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:firebase_storage/firebase_storage.dart';

class BillPage extends StatefulWidget {
  final String userName;
  final String userId;
  final String courseName;
  final double amount;

  const BillPage({
    Key? key,
    required this.userName,
    required this.userId,
    required this.courseName,
    required this.amount, required String courseDuration, required difficultyLevel, required courseFee,
  }) : super(key: key);

  @override
  _BillPageState createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  String? userEmail;
  String? userPhone;
  late String invoiceNumber;
  late String currentDate;
  bool isLoading = true;

  // Color scheme
  final Color primaryColor = Color(0xFF1565C0); // Deep Blue
  final Color accentColor = Color(0xFF00897B); // Teal
  final Color backgroundColor = Color(0xFFF5F5F5); // Light Grey

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
    currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _delayedFetchUserDetails();
  }

  void _generateInvoiceNumber() {
    final random = Random();
    invoiceNumber = 'INV-${random.nextInt(10000).toString().padLeft(4, '0')}';
  }

  Future<void> _delayedFetchUserDetails() async {
    // Add a 20-second delay
    await Future.delayed(Duration(seconds: 20));
    await _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      setState(() {
        userEmail = userDoc['email'] as String?;
        userPhone = userDoc['phone'] as String?;
        isLoading = false;
      });
      
      // Automatically save the invoice to Firebase after fetching user details
      await _saveInvoiceToFirebase();
    } catch (e) {
      print('Error fetching user details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveInvoiceToFirebase() async {
    try {
      await FirebaseFirestore.instance.collection('invoices').add({
        'userId': widget.userId,
        'userName': widget.userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'invoiceNumber': invoiceNumber,
        'invoiceDate': currentDate,
        'courseName': widget.courseName,
        'amount': widget.amount,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Invoice saved successfully');
    } catch (e) {
      print('Error saving invoice to Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Payment Receipt'),
          backgroundColor: primaryColor,
        ),
        body: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Receipt'),
        backgroundColor: primaryColor,
      ),
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'INVOICE',
                        style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Image.asset('assets/eduspark_logo.png', height: 50),
                          Text('EduSpark Inc.', 
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            )
                          ),
                          Text('Invoice No: $invoiceNumber'),
                          Text('Invoice Date: $currentDate'),
                        ],
                      ),
                    ],
                  ),
                  Divider(color: primaryColor, thickness: 2),
                  SizedBox(height: 20),
                  Text('INVOICE TO:', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    )
                  ),
                  Text(widget.userName),
                  if (userEmail != null) Text(userEmail!),
                  if (userPhone != null) Text(userPhone!),
                  SizedBox(height: 20),
                  Table(
                    border: TableBorder.all(color: primaryColor),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: primaryColor),
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('AMOUNT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(currentDate),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(widget.courseName),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('₹${widget.amount.toStringAsFixed(2)}'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'TOTAL: ₹${widget.amount.toStringAsFixed(2)}', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Terms & Conditions:', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                  Text('• The course fee will be stated in the offer letter and is not refundable.'),
                  Text('• In order to get the certificate and pass the course, the given criteria should be followed.'),
                  SizedBox(height: 20),
                  Text('CONTACT US', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                  Text('EduSpark, Kottayam, Kerala'),
                  Text('Phone: 6238859116'),
                  Text('Email: yaduk874685@gmail.com'),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Image.asset('assets/sign.png', height: 50),
                        Text('Signature'),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.download, color: Colors.white),
                      label: Text(
                        'Download PDF',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => _downloadPdf(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final pdf = pw.Document();

    final image = pw.MemoryImage(
      (await rootBundle.load('assets/eduspark_logo.png')).buffer.asUint8List(),
    );

    final signatureImage = pw.MemoryImage(
      (await rootBundle.load('assets/sign.png')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 28, 
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Image(image, height: 50),
                      pw.Text('EduSpark Inc.', 
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal,
                        )
                      ),
                      pw.Text('Invoice No: $invoiceNumber'),
                      pw.Text('Invoice Date: $currentDate'),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.blue800),
              pw.SizedBox(height: 20),
              pw.Text('INVOICE TO:', 
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal,
                )
              ),
              pw.Text(widget.userName),
              if (userEmail != null) pw.Text(userEmail!),
              if (userPhone != null) pw.Text(userPhone!),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.blue800),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue800),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8.0),
                        child: pw.Text('DATE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8.0),
                        child: pw.Text('DESCRIPTION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8.0),
                        child: pw.Text('AMOUNT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8.0),
                        child: pw.Text(currentDate),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8.0),
                        child: pw.Text(widget.courseName),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8.0),
                        child: pw.Text('₹${widget.amount.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Padding(
                  padding: pw.EdgeInsets.all(8.0),
                  child: pw.Text(
                    'TOTAL: ₹${widget.amount.toStringAsFixed(2)}', 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal),
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.Text('• The course fee will be stated in the offer letter and is not refundable.'),
              pw.Text('• In order to get the certificate and pass the course, the given criteria should be followed.'),
              pw.SizedBox(height: 20),
              pw.Text('CONTACT US', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.Text('EduSpark, Kottayam, Kerala'),
              pw.Text('Phone: 6238859116'),
              pw.Text('Email: yaduk874685@gmail.com'),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Image(signatureImage, height: 50),
                    pw.Text('Signature'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File("${output.path}/EduSpark_Invoice_${DateTime.now().millisecondsSinceEpoch}.pdf");
      
      await file.writeAsBytes(await pdf.save());

      final storageRef = FirebaseStorage.instance.ref().child('invoices/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await storageRef.putFile(file);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF downloaded successfully')),
      );

      // Navigate back with enrollment status
      Navigator.of(context).pop({'enrolled': true});
    } catch (e) {
      print('Error downloading PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download PDF. Please try again.')),
      );
    }
  }}