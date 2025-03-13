import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final List<Alert> alerts;
  final List<User> users;
  final String status;
  final Location location;
  final DateTime createdAt;
  final DateTime eventTime;
  final String camNo;
  final String message;

  Event({
    required this.id,
    required this.alerts,
    required this.users,
    required this.status,
    required this.location,
    required this.createdAt,
    required this.eventTime,
    required this.camNo,
    required this.message,
  });

  factory Event.fromFirestore(Map<String, dynamic> data, String docId) {
    print('Creating Event from data: $data');

    try {
      // Initialize with default values
      List<Alert> alertsList = [];
      List<User> usersList = [];
      String status = '';
      Location location = Location(latitude: 0, longitude: 0);
      DateTime createdAt = DateTime.now();
      DateTime eventTime = DateTime.now();
      String camNo = data['cam_no'] ?? '';
      String message = '';

      // Parse location
      if (data['location'] is Map<String, dynamic>) {
        location = Location.fromMap(data['location'] as Map<String, dynamic>);
        print('Parsed location: ${location.latitude}, ${location.longitude}');
      }

      // Parse alerts array
      if (data['alerts'] is List) {
        alertsList =
            (data['alerts'] as List).map((alertData) {
              if (alertData is Map<String, dynamic>) {
                // Parse users within each alert
                List<User> alertUsers = [];
                if (alertData['users'] is List) {
                  alertUsers =
                      (alertData['users'] as List)
                          .map(
                            (userData) =>
                                User.fromMap(userData as Map<String, dynamic>),
                          )
                          .toList();
                }

                // Create alert with its users
                Alert alert = Alert(
                  alertId: docId,
                  alertTime: _parseTimestamp(alertData['alert_time']),
                  message: alertData['message'] ?? '',
                  status: alertData['status'] ?? '',
                  users: alertUsers,
                );
                print(
                  'Parsed alert: ${alert.message}, Status: ${alert.status}',
                );
                return alert;
              }
              throw Exception('Invalid alert data format');
            }).toList();
      }

      // Parse timestamps
      createdAt = _parseTimestamp(data['created_at']);
      eventTime = _parseTimestamp(data['event_time']);
      print('Timestamps - Created: $createdAt, Event: $eventTime');

      // Get message from first alert if available
      if (alertsList.isNotEmpty) {
        message = alertsList.first.message;
        status = alertsList.first.status;
      }

      return Event(
        id: docId,
        alerts: alertsList,
        users: usersList,
        status: status,
        location: location,
        createdAt: createdAt,
        eventTime: eventTime,
        camNo: camNo,
        message: message,
      );
    } catch (e) {
      print('Error parsing event data: $e');
      rethrow;
    }
  }

  // Helper method to parse timestamps from various formats
  static DateTime _parseTimestamp(dynamic value) {
    print('Parsing timestamp value: $value (${value.runtimeType})');

    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      // Try parsing as ISO date
      DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }

    print('Failed to parse timestamp, using current time');
    return DateTime.now();
  }
}

class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  String toString() => '($latitude, $longitude)';
}

class Alert {
  final String alertId;
  final DateTime alertTime;
  final String message;
  final String status;
  final List<User> users;

  Alert({
    required this.alertId,
    required this.alertTime,
    required this.message,
    required this.status,
    this.users = const [],
  });

  factory Alert.fromMap(Map<String, dynamic> map) {
    List<User> users = [];
    if (map['users'] is List) {
      users =
          (map['users'] as List)
              .map((userData) => User.fromMap(userData as Map<String, dynamic>))
              .toList();
    }

    return Alert(
      alertId: map['alert_id']?.toString() ?? '',
      alertTime: Event._parseTimestamp(map['alert_time']),
      message: map['message'] ?? '',
      status: map['status'] ?? '',
      users: users,
    );
  }
}

class User {
  final DateTime createdAt;
  final String email;
  final String name;
  final String phone;

  User({
    required this.createdAt,
    required this.email,
    required this.name,
    required this.phone,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      createdAt: Event._parseTimestamp(map['created_at']),
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}
