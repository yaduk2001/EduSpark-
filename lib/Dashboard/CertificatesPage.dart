import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CertificatesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Certificates'),
        backgroundColor: Colors.blueAccent,
      ),
      body: CertificatesList(),
    );
  }
}

class CertificatesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Center(child: Text('Please log in to view your certificates.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('certificates')
          .where('userId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No certificates to show.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var certificate = snapshot.data!.docs[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text((certificate.data() as Map<String, dynamic>)['courseName'] as String? ?? 'Unnamed Course'),
                subtitle: Text('Completed on: ${_formatDate((certificate.data() as Map<String, dynamic>)['completionDate'] as Timestamp?)}'),
                trailing: Icon(Icons.card_membership),
                onTap: () {
                  // TODO: Implement certificate viewing functionality
                  // This could open a detailed view of the certificate or download it
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date not available';
    DateTime date = timestamp.toDate();
    return '${date.day}-${date.month}-${date.year}';
  }
}
