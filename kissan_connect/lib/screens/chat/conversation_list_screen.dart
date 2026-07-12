import 'package:flutter/material.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/screens/chat/chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final response = await ApiService.get('chat/conversations/');
      if (response is List) {
        setState(() {
          _conversations.clear();
          _conversations.addAll(List<Map<String, dynamic>>.from(response));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to load conversations: $e')));
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('No conversations yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    final lastMessageTime = conversation['last_message_time'];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF2E7D32),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(conversation['participant_name'] ?? 'Conversation'),
                        subtitle: Text(conversation['last_message']?.toString().isNotEmpty == true ? conversation['last_message'] : 'Tap to start a conversation'),
                        trailing: lastMessageTime != null
                            ? Text(
                                DateTime.parse(lastMessageTime.toString()).toLocal().toString().split(' ').first,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: conversation['id'],
                                otherUserId: conversation['other_user_id'],
                                otherUserName: conversation['participant_name'] ?? 'Support',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
