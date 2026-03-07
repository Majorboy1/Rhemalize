import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SermonManagementPage extends StatelessWidget {
  const SermonManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sermons')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            return ListTile(
              leading: Image.network(doc['imageUrl'],
                  width: 50, height: 50, fit: BoxFit.cover),
              title: Text(doc['title']),
              subtitle: Text(doc['speaker']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editSermon(context, doc),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _confirmDelete(context, doc.id, doc['fileName']),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String docId, String storagePath) {
    // Logic to show a dialog and delete from both Firestore and Firebase Storage
  }

  void _editSermon(BuildContext context, DocumentSnapshot doc) {
    // Logic to open a modal with the current data filled in for editing
  }
}
