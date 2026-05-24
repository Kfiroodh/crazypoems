import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/profile_service.dart';
import '../services/modern_chat_service.dart';
import '../models/chat_room_model.dart';
import 'chat_detail_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _profileService = ProfileService();
  final _chatService = ModernChatService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  final String _myId = Supabase.instance.client.auth.currentUser!.id;

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await _profileService.searchUsers(q);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final roomId = await _chatService.getOrCreateDirectRoom(user['id']);

      final room = ChatRoom(
        id: roomId,
        isGroup: false,
        participants: [
          Participant(
            userId: user['id'],
            fullName: user['full_name'] ?? 'User',
            avatarUrl: user['avatar_url']
          ),
          Participant(userId: _myId, fullName: 'Me'),
        ],
      );

      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailScreen(room: room))
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start chat: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Chat', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search username...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                        ? 'Type to find friends'
                        : 'No users found',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (ctx, i) {
                      final u = _searchResults[i];
                      if (u['id'] == _myId) return const SizedBox.shrink();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: u['avatar_url'] != null
                            ? CachedNetworkImageProvider(u['avatar_url'])
                            : null,
                          child: u['avatar_url'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(u['full_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('@${u['username'] ?? ""}'),
                        trailing: ElevatedButton(
                          onPressed: () => _startChat(u),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF673AB7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Message'),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
