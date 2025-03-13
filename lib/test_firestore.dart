import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDebugPage extends StatelessWidget {
  const FirestoreDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore Debug')),
      body: FutureBuilder(
        future: _testFirestore(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Firestore Collections:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (snapshot.data != null) Text(snapshot.data.toString()),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<String> _testFirestore() async {
    StringBuffer result = StringBuffer();

    try {
      // Check all possible collections
      result.writeln('Checking all collections...\n');
      
      // Check 'events' collection
      final eventsCollection = await FirebaseFirestore.instance.collection('events').get();
      result.writeln('Events collection has ${eventsCollection.docs.length} documents');
      
      // Check 'rtvd' collection
      final rtvdCollection = await FirebaseFirestore.instance.collection('rtvd').get();
      result.writeln('RTVD collection has ${rtvdCollection.docs.length} documents');
      
      // Check if there's an 'events' subcollection in 'rtvd'
      if (rtvdCollection.docs.isNotEmpty) {
        final rtvdEventsCollection = await FirebaseFirestore.instance
            .collection('rtvd')
            .doc(rtvdCollection.docs.first.id)
            .collection('events')
            .get();
        result.writeln('RTVD/${rtvdCollection.docs.first.id}/events has ${rtvdEventsCollection.docs.length} documents');
      }
      
      // Print details of each document in events collection
      if (eventsCollection.docs.isNotEmpty) {
        result.writeln('\n--- EVENTS COLLECTION DETAILS ---');
        for (var doc in eventsCollection.docs) {
          result.writeln('\nDocument ID: ${doc.id}');
          result.writeln('Data: ${_prettyPrintMap(doc.data())}');
        }
      }
      
      // Print details of each document in rtvd collection
      if (rtvdCollection.docs.isNotEmpty) {
        result.writeln('\n--- RTVD COLLECTION DETAILS ---');
        for (var doc in rtvdCollection.docs) {
          result.writeln('\nDocument ID: ${doc.id}');
          result.writeln('Data: ${_prettyPrintMap(doc.data())}');
        }
      }
      
      return result.toString();
    } catch (e) {
      return 'Error testing Firestore: $e';
    }
  }
  
  String _prettyPrintMap(Map<String, dynamic> map) {
    StringBuffer sb = StringBuffer();
    sb.writeln('{');
    map.forEach((key, value) {
      if (value is Map) {
        sb.writeln('  $key: ${_prettyPrintMap(value as Map<String, dynamic>)}');
      } else if (value is List) {
        sb.writeln('  $key: [');
        for (var item in value) {
          if (item is Map) {
            sb.writeln('    ${_prettyPrintMap(item as Map<String, dynamic>)},');
          } else {
            sb.writeln('    $item,');
          }
        }
        sb.writeln('  ]');
      } else {
        sb.writeln('  $key: $value,');
      }
    });
    sb.writeln('}');
    return sb.toString();
  }
}
