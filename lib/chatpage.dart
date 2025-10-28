import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'email_service.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    try {
      _scrollController.addListener(() {});
      
      // Add welcome message
      messages.add(ChatMessage(
        message: "🤖 Hello! I'm your AI Email Assistant.\n\n📧 Available Commands:\n• Type 'GET_UNREAD' to fetch unread emails\n• Type 'REPLY:emailId' to reply to an email\n• Type 'MARK_AS_READ:emailId' to mark an email as read\n• Type 'TEST_NETWORK' to test network connectivity\n• Type 'PING' for a quick network test\n\n💡 Example: REPLY:1989e61a46af16ce",
        isUser: false,
      ));
    } catch (e) {
      // Handle initialization errors
      messages.add(ChatMessage(
        message: "Error initializing chat: $e",
        isUser: false,
      ));
    }
  }

  @override
  void dispose() {
    try {
      _controller.dispose();
      _scrollController.dispose();
    } catch (e) {
      // Handle disposal errors
    }
    super.dispose();
  }

  // Function to scroll to the bottom
  void _scrollToBottom() {
    try {
      if (_scrollController.hasClients && _scrollController.position.hasPixels) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      // Ignore scroll errors
    }
  }

  // Handle message sending
  void _handleSendMessage() async {
    try {
      if (_controller.text.trim().isEmpty) return;

      final userMessage = _controller.text.trim();
      _controller.clear();

      // Add user message
      setState(() {
        messages.add(ChatMessage(message: _sanitizeText(userMessage), isUser: true));
      });
      _scrollToBottom();

      // Process the message
      await _processMessage(userMessage);
    } catch (e) {
      setState(() {
        messages.add(ChatMessage(
          message: "❌ Error sending message: $e",
          isUser: false,
        ));
      });
    }
  }

  // Process different types of messages
  Future<void> _processMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final trimmedMessage = message.trim();
      
      if (trimmedMessage.toUpperCase() == 'GET_UNREAD') {
        await _handleGetUnreadEmails();
      } else if (trimmedMessage.toUpperCase().startsWith('REPLY:')) {
        final emailId = trimmedMessage.substring(6).trim();
        await _handleReplyEmail(emailId);
      } else if (trimmedMessage.toUpperCase().startsWith('MARK_AS_READ:')) {
        final emailId = trimmedMessage.substring(13).trim();
        await _handleMarkAsRead(emailId);
      } else if (trimmedMessage.toUpperCase() == 'TEST_NETWORK') {
        await _testNetworkConnectivity();
      } else if (trimmedMessage.toUpperCase() == 'PING') {
        await _pingTest();
      } else {
        // Default AI response
        setState(() {
          messages.add(ChatMessage(
            message: "💬 I understand you said: '${_sanitizeText(trimmedMessage)}'\n\n📧 To interact with emails, please use these commands:\n• GET_UNREAD - to fetch unread emails\n• REPLY:emailId - to reply to an email\n• MARK_AS_READ:emailId - to mark an email as read\n• TEST_NETWORK - to test network connectivity\n• PING - for a quick network test\n\n💡 Example: REPLY:1989e61a46af16ce",
            isUser: false,
          ));
        });
      }
    } catch (e) {
      setState(() {
        messages.add(ChatMessage(
          message: "❌ Error processing message: $e",
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // Handle GET_UNREAD action
  Future<void> _handleGetUnreadEmails() async {
    try {
      print('🔍 Starting GET_UNREAD request...');
      
      // First test basic network connectivity
      final networkTest = await EmailService.testConnection();
      if (!networkTest) {
        setState(() {
          messages.add(ChatMessage(
            message: "❌ Network connectivity test failed. Please check your internet connection and try again.",
            isUser: false,
          ));
        });
        return;
      }
      
      print('✅ Network test passed, proceeding with email request...');
      
      final emails = await EmailService.getUnreadEmails();
      
      if (emails.isEmpty) {
        setState(() {
          messages.add(ChatMessage(
            message: "No unread emails found.",
            isUser: false,
          ));
        });
        return;
      }

      String responseMessage = "📧 Found ${emails.length} unread email(s):\n\n";
      
      for (int i = 0; i < emails.length; i++) {
        final email = emails[i];
        responseMessage += "📬 Email ${i + 1}:\n";
        responseMessage += "📬 id ${_sanitizeText(email.id)}:\n";
        responseMessage += "From: ${_sanitizeText(email.from)}\n";
        responseMessage += "Subject: ${_sanitizeText(email.subject)}\n";
        responseMessage += "Snippet: ${_sanitizeText(email.snippet)}\n";
        responseMessage += "Size: ${email.sizeEstimate} bytes\n";
        responseMessage += "Date: ${_formatEmailDate(email.internalDate)}\n";
        responseMessage += "Labels: ${email.labels.isNotEmpty ? email.labels.join(', ') : 'No labels'}\n";
        if (i < emails.length - 1) responseMessage += "─" * 40 + "\n";
      }

      setState(() {
        messages.add(ChatMessage(
          message: responseMessage,
          isUser: false,
          isEmailData: true,
          emailData: emails,
        ));
      });
    } catch (e) {
      print("❌ Error fetching unread emails: $e");
      
      String errorMessage = "❌ Error fetching unread emails: $e\n\n";
      
      // Add helpful debugging information
      if (e.toString().contains('SocketException')) {
        errorMessage += "🔧 Troubleshooting tips:\n";
        errorMessage += "• Check your internet connection\n";
        errorMessage += "• Make sure you're not on a restricted network\n";
        errorMessage += "• Try using mobile data instead of WiFi\n";
        errorMessage += "• Restart the app\n";
      } else if (e.toString().contains('timeout')) {
        errorMessage += "🔧 Troubleshooting tips:\n";
        errorMessage += "• Check your internet speed\n";
        errorMessage += "• Try again in a few moments\n";
        errorMessage += "• Check if the server is responding\n";
      }
      
      setState(() {
        messages.add(ChatMessage(
          message: errorMessage,
          isUser: false,
        ));
      });
    }
  }

  // Sanitize text to prevent UTF-16 errors
  String _sanitizeText(String text) {
    if (text.isEmpty) return '';
    try {
      // Remove any invalid UTF-16 characters and control characters
      String sanitized = text.replaceAll(RegExp(r'[\uFFFD\u0000-\u001F\u007F-\u009F]'), '');
      
      // Remove any other problematic characters
      sanitized = sanitized.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
      
      // Ensure the string is not empty after sanitization
      if (sanitized.trim().isEmpty) {
        return 'No content';
      }
      
      return sanitized.trim();
    } catch (e) {
      return 'Invalid text';
    }
  }

  // Handle REPLY action
  Future<void> _handleReplyEmail(String emailId) async {
    if (emailId.isEmpty) {
      setState(() {
        messages.add(ChatMessage(
          message: "❌ Please provide a valid email ID. Format: REPLY:emailId",
          isUser: false,
        ));
      });
      return;
    }

    try {
      print('🔍 Starting REPLY request for email: $emailId');
      
      // First test basic network connectivity
      final networkTest = await EmailService.testConnection();
      if (!networkTest) {
        setState(() {
          messages.add(ChatMessage(
            message: "❌ Network connectivity test failed. Please check your internet connection and try again.",
            isUser: false,
          ));
        });
        return;
      }
      
      print('✅ Network test passed, proceeding with reply request...');
      
      final response = await EmailService.replyToEmail(emailId);
      
      setState(() {
        messages.add(ChatMessage(
          message: "✅ Reply sent successfully!\n📧 Email ID: ${response.id}\n🧵 Thread ID: ${response.threadId}\n🏷️ Labels: ${response.labelIds.join(', ')}",
          isUser: false,
        ));
      });
    } catch (e) {
      print("❌ Error replying to email: $e");
      
      String errorMessage = "❌ Error replying to email: $e\n\n";
      
      // Add helpful debugging information
      if (e.toString().contains('SocketException')) {
        errorMessage += "🔧 Troubleshooting tips:\n";
        errorMessage += "• Check your internet connection\n";
        errorMessage += "• Make sure you're not on a restricted network\n";
        errorMessage += "• Try using mobile data instead of WiFi\n";
        errorMessage += "• Restart the app\n";
      } else if (e.toString().contains('timeout')) {
        errorMessage += "🔧 Troubleshooting tips:\n";
        errorMessage += "• Check your internet speed\n";
        errorMessage += "• Try again in a few moments\n";
        errorMessage += "• Check if the server is responding\n";
      }
      
      setState(() {
        messages.add(ChatMessage(
          message: errorMessage,
          isUser: false,
        ));
      });
    }
  }

  // Handle MARK_AS_READ action
  Future<void> _handleMarkAsRead(String emailId) async {
    if (emailId.isEmpty) {
      setState(() {
        messages.add(ChatMessage(
          message: "❌ Please provide a valid email ID. Format: MARK_AS_READ:emailId",
          isUser: false,
        ));
      });
      return;
    }

    try {
      print('🔍 Starting MARK_AS_READ request for email: $emailId');
      
      // First test basic network connectivity
      final networkTest = await EmailService.testConnection();
      if (!networkTest) {
        setState(() {
          messages.add(ChatMessage(
            message: "❌ Network connectivity test failed. Please check your internet connection and try again.",
            isUser: false,
          ));
        });
        return;
      }
      
      print('✅ Network test passed, proceeding with mark as read request...');
      
      final response = await EmailService.markEmailAsRead(emailId);
      
      setState(() {
        messages.add(ChatMessage(
          message: "✅ Email marked as read successfully!\n📧 Email ID: ${response.id}\n🧵 Thread ID: ${response.threadId}\n🏷️ Labels: ${response.labelIds.join(', ')}",
          isUser: false,
        ));
      });
    } catch (e) {
      print("❌ Error marking email as read: $e");
      
      String errorMessage = "❌ Error marking email as read: $e\n\n";
      
      // Add helpful debugging information
      if (e.toString().contains('SocketException')) {
        errorMessage += "🔧 Troubleshooting tips:\n";
        errorMessage += "• Check your internet connection\n";
        errorMessage += "• Make sure you're not on a restricted network\n";
        errorMessage += "• Try using mobile data instead of WiFi\n";
        errorMessage += "• Restart the app\n";
      } else if (e.toString().contains('timeout')) {
        errorMessage += "🔧 Troubleshooting tips:\n";
        errorMessage += "• Check your internet speed\n";
        errorMessage += "• Try again in a few moments\n";
        errorMessage += "• Check if the server is responding\n";
      }
      
      setState(() {
        messages.add(ChatMessage(
          message: errorMessage,
          isUser: false,
        ));
      });
    }
  }

  // Format email date
  String _formatEmailDate(String timestamp) {
    try {
      if (timestamp.isEmpty) return 'Unknown date';
      
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      
      // Check if the date is valid
      if (date.year < 1900 || date.year > 2100) {
        return 'Invalid date';
      }
      
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Copy text to clipboard
  void _copyToClipboard(String text) {
    try {
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nothing to copy'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: ${text.length > 30 ? text.substring(0, 30) + '...' : text}'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy: $e'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build copyable field widget
  Widget _buildCopyableField(String label, String value) {
    // Sanitize the value to prevent display issues
    final sanitizedValue = _sanitizeText(value);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              sanitizedValue,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _copyToClipboard(sanitizedValue),
            icon: Icon(
              Icons.copy,
              color: Colors.blue,
              size: 16,
            ),
            tooltip: 'Copy $label',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      return SafeArea(
        child: Scaffold(
            backgroundColor: Colors.black87,
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(141, 91, 244, 1),
                          Color.fromRGBO(245, 91, 245, 1),
                          Color.fromRGBO(34, 167, 246, 1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        topLeft: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0,right: 20,top: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Lottie.asset(
                            'assets/Animation_loading.json',
                            height: 100,
                            width: 100,
                            repeat: true,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 25.0),
                            child: Text(
                              "AI Chatbot...",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Spacer(),
                          Lottie.asset(
                            'assets/Animation_robot.json',
                            height: 100,
                            width: 100,
                            repeat: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height:MediaQuery.of(context).size.height,
                    decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(20),
                            topRight:Radius.circular(20) )
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              try {
                                var message = messages[index];

                                return Align(
                                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Row(
                                    mainAxisAlignment:
                                    message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!message.isUser)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8.0, left: 8.0, top: 10.0),
                                          child: Icon(
                                            Icons.smart_toy,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          margin: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            color: message.isUser ? Colors.greenAccent : Colors.transparent,
                                            borderRadius: message.isUser
                                                ? BorderRadius.only(
                                              topRight: Radius.circular(15.0),
                                              topLeft: Radius.circular(15.0),
                                              bottomLeft: Radius.circular(15.0),
                                            )
                                                : BorderRadius.only(
                                              topRight: Radius.circular(15.0),
                                              topLeft: Radius.circular(15.0),
                                              bottomRight: Radius.circular(15.0),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _splitMessage(message.message, 30),
                                                style: TextStyle(
                                                  color: message.isUser ? Colors.black : Colors.white,
                                                ),
                                                softWrap: true,
                                              ),
                                              if (message.isEmailData && message.emailData != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '📋 Copy individual data:',
                                                        style: TextStyle(
                                                          color: Colors.blue,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),
                                                      ...message.emailData!.asMap().entries.map((entry) {
                                                        try {
                                                          final index = entry.key;
                                                          final email = entry.value;
                                                          return Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                'Email ${index + 1}:',
                                                                style: TextStyle(
                                                                  color: Colors.yellow,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                              SizedBox(height: 4),
                                                              _buildCopyableField('id', email.id)  ,                                                         _buildCopyableField('From', email.from),
                                                              _buildCopyableField('Subject', email.subject),
                                                              _buildCopyableField('Snippet', email.snippet),
                                                              _buildCopyableField('To', email.to),
                                                              _buildCopyableField('Date', _formatEmailDate(email.internalDate)),
                                                              _buildCopyableField('Labels', email.labels.isNotEmpty ? email.labels.join(', ') : 'No labels'),
                                                              if (index < message.emailData!.length - 1)
                                                                Divider(color: Colors.grey, height: 16),
                                                            ],
                                                          );
                                                        } catch (e) {
                                                          print('Error displaying message: $e');
                                                          return Text(
                                                            'Error displaying email: $e',
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                              fontSize: 12,
                                                            ),
                                                          );
                                                        }
                                                      }).toList(),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (message.isUser)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8.0, left: 8.0, top: 10.0),
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              } catch (e) {
                                print('Error displaying message: $e');
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Error displaying message: $e',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        if (_isLoading)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Processing...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          margin: EdgeInsets.only(top: 12.0),
                          decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(20),
                                  topRight:Radius.circular(20) )
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 5.0,bottom: 5.0),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: (){},
                                  icon: const Icon(Icons.mic, color: Colors.white),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: 'Send a message...',
                                      hintStyle: TextStyle(color: Colors.white54),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _handleSendMessage(),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _handleSendMessage,
                                  icon: const Icon(Icons.send, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
        ),
      );
    } catch (e) {
      return Scaffold(
        body: Center(
          child: Text('Error building chat: $e'),
        ),
      );
    }
  }

  String _splitMessage(String message, int maxLength) {
    try {
      if (message.isEmpty || maxLength <= 0) return message;
      
      StringBuffer newMessage = StringBuffer();
      for (int i = 0; i < message.length; i += maxLength) {
        if (i + maxLength < message.length) {
          newMessage.write(message.substring(i, i + maxLength) + '\n');
        } else {
          newMessage.write(message.substring(i));
        }
      }
      return newMessage.toString();
    } catch (e) {
      return message;
    }
  }

  // Test network connectivity
  Future<void> _testNetworkConnectivity() async {
    try {
      print('🔍 Testing network connectivity...');
      
      setState(() {
        messages.add(ChatMessage(
          message: "🔍 Testing network connectivity...",
          isUser: false,
        ));
      });
      
      final response = await EmailService.testConnection();
      
      if (response) {
        print('✅ Network test successful');
        setState(() {
          messages.add(ChatMessage(
            message: "✅ Network connectivity test successful!\n\n🌐 Basic internet connection is working.\n\n📡 Now testing specific API endpoint...",
            isUser: false,
          ));
        });
        
        // Test the specific API endpoint
        try {
          print('🔍 Testing specific API endpoint...');
          final testResponse = await EmailService.getUnreadEmails();
          setState(() {
            messages.add(ChatMessage(
              message: "✅ API endpoint test successful!\n\n📧 Server is responding correctly.\n\n🎯 You can now use email commands.",
              isUser: false,
            ));
          });
        } catch (apiError) {
          print('❌ API endpoint test failed: $apiError');
          setState(() {
            messages.add(ChatMessage(
              message: "⚠️ API endpoint test failed: $apiError\n\n🔧 The server might be down or there could be a configuration issue.",
              isUser: false,
            ));
          });
        }
      } else {
        print('❌ Network test failed');
        setState(() {
          messages.add(ChatMessage(
            message: "❌ Network connectivity test failed!\n\n🔧 Troubleshooting tips:\n• Check your internet connection\n• Make sure you're not on a restricted network\n• Try using mobile data instead of WiFi\n• Restart the app\n• Check if you're behind a firewall or proxy",
            isUser: false,
          ));
        });
      }
    } catch (e) {
      print('❌ Network test error: $e');
      setState(() {
        messages.add(ChatMessage(
          message: "❌ Network test error: $e\n\n🔧 Please check your internet connection and try again.",
          isUser: false,
        ));
      });
    }
  }

  // Simple ping test
  Future<void> _pingTest() async {
    try {
      print('🔍 Testing basic network connectivity...');
      setState(() {
        messages.add(ChatMessage(
          message: "🔍 Testing basic network connectivity...",
          isUser: false,
        ));
      });

      final response = await EmailService.testConnection();

      if (response) {
        print('✅ Basic network connectivity test successful');
        setState(() {
          messages.add(ChatMessage(
            message: "✅ Basic network connectivity test successful!\n\n🌐 Your device is connected to the internet.",
            isUser: false,
          ));
        });
      } else {
        print('❌ Basic network connectivity test failed');
        setState(() {
          messages.add(ChatMessage(
            message: "❌ Basic network connectivity test failed!\n\n🔧 Troubleshooting tips:\n• Check your internet connection\n• Make sure you're not on a restricted network\n• Try using mobile data instead of WiFi\n• Restart the app\n• Check if you're behind a firewall or proxy",
            isUser: false,
          ));
        });
      }
    } catch (e) {
      print('❌ Basic network connectivity test error: $e');
      setState(() {
        messages.add(ChatMessage(
          message: "❌ Basic network connectivity test error: $e\n\n🔧 Please check your internet connection and try again.",
          isUser: false,
        ));
      });
    }
  }
}

class ChatMessage {
  final String message;
  final bool isUser;
  final bool isEmailData;
  final List<EmailData>? emailData;

  ChatMessage({
    required this.message, 
    required this.isUser, 
    this.isEmailData = false,
    this.emailData,
  });
}
