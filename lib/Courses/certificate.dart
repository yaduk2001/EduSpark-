import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CertificatePage extends StatefulWidget {
  final String userID;
  final String courseName;

  CertificatePage({required this.userID, required this.courseName});

  @override
  _CertificatePageState createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  String? userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    // Fetch user name from Firestore
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userID)
        .get();

    if (snapshot.exists) {
      var userData = snapshot.data() as Map<String, dynamic>;
      setState(() {
        userName = userData['name'] ?? 'Student';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Certificate'),
      ),
      body: userName == null
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return CertificateWidget(
                              userName: userName!,
                              courseName: widget.courseName,
                              maxWidth: constraints.maxWidth,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _downloadAndSavePDF(),
                      child: Text('Download and Save Certificate'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _downloadAndSavePDF() async {
    final pdf = await _generatePDF();
    await _savePDFToFirebase(pdf);
    await Printing.sharePdf(bytes: pdf, filename: 'certificate.pdf');
  }

  Future<Uint8List> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              width: 350,
              height: 250,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1E3A8A'),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Stack(
                children: [
                  // ... Recreate the certificate design here using pw widgets
                  // This will be similar to the Flutter widget structure
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _savePDFToFirebase(Uint8List pdfBytes) async {
    final storage = FirebaseStorage.instance;
    final certificateRef = storage.ref('certificates/${widget.userID}_${widget.courseName}.pdf');

    try {
      await certificateRef.putData(pdfBytes);
      final downloadUrl = await certificateRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .collection('certificates')
          .add({
        'courseName': widget.courseName,
        'downloadUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Certificate saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save certificate: $e')),
      );
    }
  }
}

class CertificateWidget extends StatelessWidget {
  final String userName;
  final String courseName;
  final double maxWidth;

  CertificateWidget({
    required this.userName,
    required this.courseName,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final certificateWidth = maxWidth * 0.9; // 90% of available width
    final certificateHeight = certificateWidth * 0.7; // Maintain aspect ratio

    return Center(
      child: Container(
        width: certificateWidth,
        height: certificateHeight,
        decoration: BoxDecoration(
          color: Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: certificateWidth * 0.3,
                height: certificateWidth * 0.3,
                decoration: BoxDecoration(
                  color: Color(0xFFFBBF24).withOpacity(0.2),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomRight: Radius.circular(100),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(certificateWidth * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        'CERTIFICATE',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: certificateWidth * 0.08,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'OF ACHIEVEMENT',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: certificateWidth * 0.06,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'THIS CERTIFICATE IS AWARDED TO',
                        style: TextStyle(color: Colors.white70, fontSize: certificateWidth * 0.03),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: certificateWidth * 0.02),
                      Text(
                        userName,
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: certificateWidth * 0.09,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: certificateWidth * 0.02),
                      Text(
                        'for their outstanding achievement in',
                        style: TextStyle(color: Colors.white70, fontSize: certificateWidth * 0.03),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        courseName,
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: certificateWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            'HANNAH MORALES',
                            style: TextStyle(color: Colors.white, fontSize: certificateWidth * 0.025),
                          ),
                          Text(
                            'HEAD MASTER',
                            style: TextStyle(color: Colors.white70, fontSize: certificateWidth * 0.02),
                          ),
                        ],
                      ),
                      FaIcon(
                        FontAwesomeIcons.medal,
                        color: Color(0xFFFBBF24),
                        size: certificateWidth * 0.08,
                      ),
                      Column(
                        children: [
                          Text(
                            'LARS PETERS',
                            style: TextStyle(color: Colors.white, fontSize: certificateWidth * 0.025),
                          ),
                          Text(
                            'MENTOR',
                            style: TextStyle(color: Colors.white70, fontSize: certificateWidth * 0.02),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
