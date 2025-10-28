import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class EmailService {
  static const String baseUrl = 'https://mausami.app.n8n.cloud/webhook-test/emailchat';
  
  // HTTP client with timeout
  static final http.Client _client = http.Client();
  
  // Get unread emails
  static Future<List<EmailData>> getUnreadEmails() async {
    try {
      print('🔍 Attempting to connect to: $baseUrl');
      
      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter/1.0',
        },
        body: jsonEncode({
          'action': 'GET_UNREAD',
        }),
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => EmailData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get unread emails: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      print('🌐 Socket Exception: $e');
      throw Exception('Network error: Unable to connect to server. Please check your internet connection.');
    } on HttpException catch (e) {
      print('🌐 HTTP Exception: $e');
      throw Exception('HTTP error: $e');
    } on FormatException catch (e) {
      print('🌐 Format Exception: $e');
      throw Exception('Data format error: Invalid response from server');
    } catch (e) {
      print('🌐 General Exception: $e');
      throw Exception('Error getting unread emails: $e');
    }
  }

  // Reply to an email
  static Future<ReplyResponse> replyToEmail(String emailId) async {
    try {
      print('🔍 Attempting to reply to email: $emailId');
      
      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter/1.0',
        },
        body: jsonEncode({
          'action': 'REPLY',
          'emailId': emailId,
        }),
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      print('📡 Reply response status: ${response.statusCode}');
      print('📡 Reply response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReplyResponse.fromJson(data);
      } else {
        throw Exception('Failed to reply to email: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      print('🌐 Socket Exception: $e');
      throw Exception('Network error: Unable to connect to server. Please check your internet connection.');
    } on HttpException catch (e) {
      print('🌐 HTTP Exception: $e');
      throw Exception('HTTP error: $e');
    } on FormatException catch (e) {
      print('🌐 Format Exception: $e');
      throw Exception('Data format error: Invalid response from server');
    } catch (e) {
      print('🌐 General Exception: $e');
      throw Exception('Error replying to email: $e');
    }
  }

  // Mark email as read
  static Future<MarkAsReadResponse> markEmailAsRead(String emailId) async {
    try {
      print('🔍 Attempting to mark email as read: $emailId');
      
      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter/1.0',
        },
        body: jsonEncode({
          'action': 'MARK_AS_READ',
          'emailId': emailId,
        }),
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      print('📡 Mark as read response status: ${response.statusCode}');
      print('📡 Mark as read response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MarkAsReadResponse.fromJson(data);
      } else {
        throw Exception('Failed to mark email as read: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      print('🌐 Socket Exception: $e');
      throw Exception('Network error: Unable to connect to server. Please check your internet connection.');
    } on HttpException catch (e) {
      print('🌐 HTTP Exception: $e');
      throw Exception('HTTP error: $e');
    } on FormatException catch (e) {
      print('🌐 Format Exception: $e');
      throw Exception('Data format error: Invalid response from server');
    } catch (e) {
      print('🌐 General Exception: $e');
      throw Exception('Error marking email as read: $e');
    }
  }

  // Test network connectivity
  static Future<bool> testConnection() async {
    try {
      print('🔍 Testing network connectivity...');
      
      final response = await _client.get(
        Uri.parse('https://httpbin.org/get'),
        headers: {
          'User-Agent': 'Flutter/1.0',
        },
      ).timeout(Duration(seconds: 10));
      
      print('✅ Network test successful: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Network test failed: $e');
      return false;
    }
  }

  // Dispose the HTTP client
  static void dispose() {
    _client.close();
  }
}

class EmailData {
  final String id;
  final String threadId;
  final String snippet;
  final String from;
  final String subject;
  final String to;
  final String sizeEstimate;
  final String internalDate;
  final List<String> labels;

  EmailData({
    required this.id,
    required this.threadId,
    required this.snippet,
    required this.from,
    required this.subject,
    required this.to,
    required this.sizeEstimate,
    required this.internalDate,
    required this.labels,
  });

  factory EmailData.fromJson(Map<String, dynamic> json) {
    return EmailData(
      id: json['id'] ?? '',
      threadId: json['threadId'] ?? '',
      snippet: json['snippet'] ?? '',
      from: json['From'] ?? '',
      subject: json['Subject'] ?? '',
      to: json['To'] ?? '',
      sizeEstimate: json['sizeEstimate']?.toString() ?? '',
      internalDate: json['internalDate']?.toString() ?? '',
      labels: (json['labels'] as List<dynamic>?)
              ?.map((label) => label['name'] as String)
              .toList() ??
          [],
    );
  }

  String get formattedEmail {
    return '''
From: $from
Subject: $subject
To: $to
Snippet: $snippet
Size: $sizeEstimate bytes
Date: ${_formatDate(internalDate)}
Labels: ${labels.join(', ')}
''';
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return timestamp;
    }
  }
}

class ReplyResponse {
  final String id;
  final String threadId;
  final List<String> labelIds;

  ReplyResponse({
    required this.id,
    required this.threadId,
    required this.labelIds,
  });

  factory ReplyResponse.fromJson(Map<String, dynamic> json) {
    return ReplyResponse(
      id: json['id'] ?? '',
      threadId: json['threadId'] ?? '',
      labelIds: (json['labelIds'] as List<dynamic>?)
              ?.map((label) => label as String)
              .toList() ??
          [],
    );
  }
}

class MarkAsReadResponse {
  final String id;
  final String threadId;
  final List<String> labelIds;

  MarkAsReadResponse({
    required this.id,
    required this.threadId,
    required this.labelIds,
  });

  factory MarkAsReadResponse.fromJson(Map<String, dynamic> json) {
    return MarkAsReadResponse(
      id: json['id'] ?? '',
      threadId: json['threadId'] ?? '',
      labelIds: (json['labelIds'] as List<dynamic>?)
              ?.map((label) => label as String)
              .toList() ??
          [],
    );
  }
}
