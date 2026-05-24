import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/journal_service.dart';
import 'create_entry_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _journalService = JournalService();
  final _myId = Supabase.instance.client.auth.currentUser?.id;
  bool _isLoading = true;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final data = await _journalService.fetchJournalFeed();
    if (mounted) setState(() { _entries = data; _isLoading = false; });
  }

  void _showMenu(Map<String, dynamic> entry) {
    final bool isOwner = entry['user_id'] == _myId;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Entry'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEntryScreen(entryToEdit: entry))).then((v) => if (v == true) _loadEntries());
                },
              ),
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Entry', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await _journalService.deleteEntry(entry['id']);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadEntries();
                  }
                },
              ),
            ListTile(leading: const Icon(Icons.share_outlined), title: const Text('Share Link'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.orange), title: const Text('Report'), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFF),
      appBar: AppBar(
        title: Text('Heart\'s Journal', style: GoogleFonts.philosopher(fontWeight: FontWeight.bold, fontSize: 26, color: const Color(0xFF673AB7))),
        backgroundColor: Colors.transparent, elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.stars_rounded, color: Colors.green), onPressed: () {}),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF673AB7)))
        : RefreshIndicator(
            onRefresh: _loadEntries,
            child: _entries.isEmpty ? _buildEmptyState() : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _entries.length,
              itemBuilder: (ctx, i) => _buildJournalCard(_entries[i]),
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEntryScreen())).then((v) => if (v == true) _loadEntries()),
        backgroundColor: const Color(0xFF673AB7),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text('Spill Feelings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> entry) {
    final moodColor = _getMoodColor(entry['mood']);
    final bool isPrivate = entry['visibility'] == 'private';
    final bool isCloseFriends = entry['visibility'] == 'close_friends';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry['image_url'] != null)
              CachedNetworkImage(imageUrl: entry['image_url'], height: 220, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: moodColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(entry['mood'] ?? 'Peaceful', style: TextStyle(color: moodColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                      ),
                      const Spacer(),
                      if (isPrivate) const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
                      if (isCloseFriends) const Icon(Icons.stars_rounded, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.more_horiz, color: Colors.grey), onPressed: () => _showMenu(entry), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (entry['title'] != null && entry['title'].isNotEmpty)
                    Text(entry['title'], style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Text(entry['content'], style: GoogleFonts.notoSerif(fontSize: 16, height: 1.6, color: Colors.black.withOpacity(0.75))),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(radius: 14, backgroundColor: Colors.grey[100], backgroundImage: entry['profiles']['avatar_url'] != null ? NetworkImage(entry['profiles']['avatar_url']) : null),
                      const SizedBox(width: 10),
                      Text(entry['profiles']['full_name'] ?? 'Poet', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      _actionIcon(Icons.favorite_border_rounded, '${entry['diary_likes']?[0]['count'] ?? 0}'),
                      const SizedBox(width: 16),
                      _actionIcon(Icons.chat_bubble_outline_rounded, 'Reply'),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _actionIcon(IconData icon, String count) {
    return Row(children: [Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 4), Text(count, style: const TextStyle(fontSize: 12, color: Colors.grey))]);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_rounded, size: 100, color: Colors.grey[200]),
          const SizedBox(height: 20),
          Text('Your story begins here.', style: GoogleFonts.philosopher(fontSize: 20, color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getMoodColor(String? mood) {
    switch (mood) {
      case 'Happy': return Colors.amber;
      case 'Sad': return Colors.blue;
      case 'Romantic': return Colors.pink;
      case 'Angry': return Colors.red;
      case 'Peaceful': return Colors.teal;
      case 'Lonely': return Colors.indigo;
      case 'Motivated': return Colors.orange;
      case 'Broken': return Colors.redAccent;
      default: return const Color(0xFF673AB7);
    }
  }
}
