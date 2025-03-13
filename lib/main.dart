import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'models/event_model.dart';
import 'package:intl/intl.dart';
import 'test_firestore.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully for web');
    } else {
      await Firebase.initializeApp();
      print('Firebase initialized successfully for mobile');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Detection Events',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF6C63FF), // Modern purple
          secondary: Color(0xFF8F88FF), // Lighter purple
          surface: Color(0xFF1E1E1E), // Darker surface
          background: Color(0xFF121212), // Dark background
          error: Color(0xFFFF6B6B), // Modern red
        ),
        scaffoldBackgroundColor: Color(0xFF121212),
        cardTheme: CardTheme(
          elevation: 8,
          shadowColor: Color(0xFF6C63FF).withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Color(0xFF1E1E1E),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          titleMedium: TextStyle(
            color: Colors.grey.shade300,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade300,
            letterSpacing: 0.2,
          ),
          bodyMedium: TextStyle(
            color: Colors.grey.shade400,
            letterSpacing: 0.1,
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Color(0xFF6C63FF).withOpacity(0.2),
          thickness: 1,
        ),
        iconTheme: IconThemeData(color: Color(0xFF6C63FF), size: 24),
        useMaterial3: true,
      ),
      home: const EventListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  bool isLoading = true;
  String errorMessage = '';
  List<QueryDocumentSnapshot> eventDocs = [];

  @override
  void initState() {
    super.initState();
    _loadFirestoreData();
  }

  Future<void> _loadFirestoreData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('Starting to load Firestore data...');

      final firestore = FirebaseFirestore.instance;
      print('Firestore instance created');

      // Get the violence detection events
      print('Attempting to fetch violence detection events...');
      final violenceDoc = await firestore
          .collection('violence')
          .doc('detections')
          .get(const GetOptions(source: Source.server));

      if (!violenceDoc.exists) {
        print('Violence detections document not found');
        setState(() {
          eventDocs = [];
          isLoading = false;
        });
        return;
      }

      print('Violence detections document found. Processing data...');
      final data = violenceDoc.data() ?? {};

      // Get the ViolenceDetectionEvents array
      final events = data['ViolenceDetectionEvents'] as List<dynamic>? ?? [];
      print('Found ${events.length} violence detection events');

      List<Map<String, dynamic>> allEvents = [];

      // Process each event in the array
      for (int i = 0; i < events.length; i++) {
        final eventData = events[i] as Map<String, dynamic>;
        print('Processing event $i: $eventData');

        // Add the event with an ID
        Map<String, dynamic> processedEvent = {
          ...eventData,
          '_docId': 'event_$i',
          'id': '$i',
        };

        allEvents.add(processedEvent);
      }

      print('Total events processed: ${allEvents.length}');

      // Sort events by creation time (newest first)
      allEvents.sort((a, b) {
        final aTime = _parseTimestamp(a['created_at']);
        final bTime = _parseTimestamp(b['created_at']);
        return bTime.compareTo(aTime);
      });

      if (allEvents.isNotEmpty) {
        // Create custom QueryDocumentSnapshot-like objects
        final customDocs =
            allEvents
                .map((data) => _CustomQueryDocumentSnapshot(data))
                .toList();

        setState(() {
          eventDocs = customDocs;
          isLoading = false;
        });
        return;
      }

      // No data found
      print('No violence detection events found');
      setState(() {
        eventDocs = [];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading Firestore data: $e');
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
    }
  }

  // Helper method to parse timestamps
  DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }

    return DateTime.now();
  }

  void _showEventDetails(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.deepPurple.shade200,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Detection Details #${event.id}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Divider(color: Colors.deepPurple.shade700),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDetailSection('Event Information', [
                            if (event.message.isNotEmpty)
                              _buildDetailRow('Message', event.message),
                            _buildDetailRow('Status', event.status),
                            _buildDetailRow(
                              'Location',
                              event.location.toString(),
                            ),
                            _buildDetailRow('Camera', event.camNo),
                            _buildDetailRow(
                              'Created At',
                              DateFormat(
                                'dd/MM/yy HH:mm',
                              ).format(event.createdAt),
                            ),
                            _buildDetailRow(
                              'Event Time',
                              DateFormat(
                                'dd/MM/yy HH:mm',
                              ).format(event.eventTime),
                            ),
                          ]),
                          if (event.alerts.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildDetailSection('Alerts', [
                              for (var alert in event.alerts)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color:
                                          alert.status.toLowerCase() == 'red'
                                              ? Colors.red.shade700
                                              : Colors.orange.shade700,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 16,
                                            color:
                                                alert.status.toLowerCase() ==
                                                        'red'
                                                    ? Colors.red.shade300
                                                    : Colors.orange.shade300,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              alert.message,
                                              style: TextStyle(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  alert.status.toLowerCase() ==
                                                          'red'
                                                      ? Colors.red.withOpacity(
                                                        0.2,
                                                      )
                                                      : Colors.orange
                                                          .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              alert.status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color:
                                                    alert.status
                                                                .toLowerCase() ==
                                                            'red'
                                                        ? Colors.red.shade300
                                                        : Colors
                                                            .orange
                                                            .shade300,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Alert Time: ${DateFormat('HH:mm').format(alert.alertTime)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (alert.users.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        for (var user in alert.users)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black12,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.name,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade300,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  'Email: ${user.email}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  'Phone: ${user.phone}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text(
              'SECURITY MONITOR',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('Manual refresh triggered');
              _loadFirestoreData();
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirestoreDebugPage(),
                ),
              );
            },
            tooltip: 'Debug Firestore',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          print('Force refresh with cache clearing');
          FirebaseFirestore.instance
              .clearPersistence()
              .then((_) {
                print('Persistence cleared');
                _loadFirestoreData();
              })
              .catchError((error) {
                print('Error clearing persistence: $error');
                _loadFirestoreData();
              });
        },
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text(
          'Force Refresh',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF6C63FF).withOpacity(0.1)],
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child:
              isLoading
                  ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      backgroundColor: Color(0xFF2D2D2D),
                    ),
                  )
                  : errorMessage.isNotEmpty
                  ? _buildErrorView()
                  : eventDocs.isEmpty
                  ? _buildEmptyView()
                  : _buildEventsList(eventDocs),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.security_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'No Events Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The system is monitoring for security events',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;

        try {
          final event = Event.fromFirestore(data, doc.id);

          return Hero(
            tag: 'event_${event.id}',
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => _showEventDetails(context, event),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color:
                            event.status.toLowerCase() == 'pending'
                                ? Color(0xFFFFB74D)
                                : Color(0xFF4CAF50),
                        width: 4,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (event.status.toLowerCase() == 'pending'
                                      ? Color(0xFFFFB74D)
                                      : Color(0xFF4CAF50))
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color:
                                  event.status.toLowerCase() == 'pending'
                                      ? Color(0xFFFFB74D)
                                      : Color(0xFF4CAF50),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detection #${event.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy HH:mm',
                                  ).format(event.eventTime),
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (event.status.toLowerCase() == 'pending'
                                      ? Color(0xFFFFB74D)
                                      : Color(0xFF4CAF50))
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    event.status.toLowerCase() == 'pending'
                                        ? Color(0xFFFFB74D).withOpacity(0.5)
                                        : Color(0xFF4CAF50).withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              event.status.toUpperCase(),
                              style: TextStyle(
                                color:
                                    event.status.toLowerCase() == 'pending'
                                        ? Color(0xFFFFB74D)
                                        : Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (event.message.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.message_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.message,
                                  style: TextStyle(
                                    color: Colors.grey.shade300,
                                    fontSize: 14,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).cardColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${event.location}',
                                      style: TextStyle(
                                        color: Colors.grey.shade300,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).cardColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.videocam,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.camNo,
                                      style: TextStyle(
                                        color: Colors.grey.shade300,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (event.alerts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_active,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${event.alerts.length} Alert${event.alerts.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        } catch (e) {
          print('Error parsing event: $e');
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(
                'Error parsing event: ${doc.id}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '$e',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: Theme.of(context).cardColor,
                          title: Text(
                            'Raw Data for ${doc.id}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          content: SingleChildScrollView(
                            child: Text(
                              data.toString(),
                              style: TextStyle(color: Colors.grey.shade300),
                            ),
                          ),
                          actions: [
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.shade700),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.deepPurple.shade200,
            ),
          ),
          Divider(color: Colors.deepPurple.shade700),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.deepPurple.shade200,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade400)),
          ),
        ],
      ),
    );
  }
}

class _CustomQueryDocumentSnapshot implements QueryDocumentSnapshot {
  final Map<String, dynamic> _data;

  _CustomQueryDocumentSnapshot(this._data);

  @override
  Map<String, dynamic> data() => _data;

  @override
  String get id => _data['_docId'] ?? 'unknown';

  @override
  DocumentReference get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  bool get exists => true;

  @override
  dynamic get(Object field) => _data[field];

  @override
  dynamic operator [](Object field) => _data[field];
}
