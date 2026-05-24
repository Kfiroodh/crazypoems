import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    setState(() {
      _entries = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F2F7),
      appBar: AppBar(
        title: Text('My Diary', style: GoogleFonts.philosopher(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.stars_rounded, color: Colors.green), onPressed: () {}),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadEntries,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length,
              itemBuilder: (ctx, i) => _buildJournalCard(_entries[i]),
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEntryScreen())).then((_) => _loadEntries()),
        backgroundColor: const Color(0xFF673AB7),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text('New Page', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> entry) {
    final moodColor = _getMoodColor(entry['mood']);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        border: entry['visibility'] == 'close_friends' ? Border.all(color: Colors.green, width: 2) : null,
        boxShadow: [BoxShadow(color: moodColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry['image_url'] != null)
              CachedNetworkImage(imageUrl: entry['image_url'], height: 200, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: moodColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(entry['mood'], style: TextStyle(color: moodColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const Spacer(),
                      if (entry['visibility'] == 'close_friends') const Icon(Icons.stars_rounded, color: Colors.green, size: 18),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (entry['title'] != null)
                    Text(entry['title'], style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(entry['content'], style: GoogleFonts.notoSerif(fontSize: 15, height: 1.6, color: Colors.black87)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundImage: entry['profiles']['avatar_url'] != null ? NetworkImage(entry['profiles']['avatar_url']) : null),
                      const SizedBox(width: 8),
                      Text(entry['profiles']['full_name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      const Icon(Icons.favorite_border_rounded, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${entry['diary_likes'][0]['count']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Happy': return Colors.amber;
      case 'Sad': return Colors.blue;
      case 'Romantic': return Colors.pink;
      case 'Angry': return Colors.red;
      case 'Peaceful': return Colors.teal;
      case 'Lonely': return Colors.indigo;
      default: return Colors.deepPurple;
    }
  }
}
