import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  // Read API key once for checks and model init (hardcoded as requested)
  static const String _apiKey = 'AIzaSyDwJeBgxa0McYyILaaeD0IlxN78WTXr4Q4';
  // Gemini model (API key injected via --dart-define=GEMINI_API_KEY=...)
  final GenerativeModel _gemini = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
  );
  bool _isLoading = false;
  final List<Map<String, dynamic>> _messages = [];

  // Jika user menyebut kota selain Malang, tolak (chatbot khusus Malang)
  bool _mentionsNonMalangCity(String text) {
    final q = text.toLowerCase();
    if (q.contains('malang')) return false;
    // daftar sederhana beberapa kota umum di Indonesia
    const others = [
      'jakarta','bandung','surabaya','yogyakarta','bali','denpasar','semarang','medan','makassar','bogor','bekasi','tangerang','depok','solo','surakarta','padang','palembang','banjarmasin','manado','kupang','jayapura'
    ];
    return others.any((c) => q.contains(c));
  }

  // Cek apakah teks menyebut Malang secara eksplisit
  bool _containsMalang(String text) => text.toLowerCase().contains('malang');

  // Query umum seputar Malang (bukan hanya wisata)
  bool _isGeneralMalangQuery(String text) {
    final q = text.toLowerCase();
    final general = [
      'malang', 'sejarah', 'budaya', 'kuliner', 'pendidikan', 'kampus', 'universitas',
      'pemerintahan', 'kesehatan', 'rumah sakit', 'transportasi', 'angkot', 'bandara',
      'stasiun', 'ekonomi', 'umkm', 'demografi', 'penduduk', 'cuaca', 'geografi', 'event',
      'acara', 'biaya hidup', 'keamanan', 'lingkungan', 'kecamatan', 'kelurahan'
    ];
    // Anggap general Malang jika mengandung salah satu kata kunci umum
    return general.any((k) => q.contains(k));
  }

  // Placeholder for future destination-related functionality

  @override
  void initState() {
    super.initState();
    
    // Listen to focus changes
    _focusNode.addListener(() {
      setState(() {
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _nowHHmm() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}';
  }

  // Fetch optional extra context from Supabase (table: knowledge)
  // Expected columns: title (text), content (text)
  Future<String> _fetchContextFromSupabase(String userQuery) async {
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('knowledge')
          .select('title, content')
          .ilike('content', '%${userQuery.replaceAll("'", "''")}%' )
          .limit(5) as List<dynamic>;

      if (rows.isNotEmpty) {
        final buf = StringBuffer();
        for (final r in rows) {
          final title = (r['title'] ?? '').toString();
          final content = (r['content'] ?? '').toString();
          buf.writeln('- ${title.isEmpty ? 'Untitled' : title}: $content');
        }
        return buf.toString();
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  // Build clear formatting instructions for Gemini and inject optional context
  String _buildInstruction(String userInput, String extraContext) {
    final ctx = extraContext.trim();
    final parts = <String>[
      'Anda adalah asisten bernama Nita. Jawablah dalam bahasa Indonesia yang sopan.',
      'Batasan wilayah: Jawab HANYA terkait Kota/Kabupaten Malang dan Malang Raya. Jika pengguna menanyakan kota lain, tolak dengan sopan.',
      if (!_containsMalang(userInput) && !_mentionsNonMalangCity(userInput))
        'Jika pengguna tidak menyebut "Malang" secara eksplisit, anggap konteks Malang dan sebutkan asumsi tersebut secara singkat di awal jawaban.',
      if (_isGeneralMalangQuery(userInput))
        'Topik terdeteksi umum tentang Malang. Berikan ringkasan terstruktur dan contoh praktis yang relevan dengan Malang.',
      'Format jawaban gunakan Markdown yang rapi:',
      '- Gunakan judul dan subjudul seperlunya',
      '- Gunakan bullet/nomor untuk daftar',
      '- Sertakan langkah-langkah singkat dan ringkas',
      '- Untuk topik umum (sejarah, budaya, kuliner, pendidikan, pemerintahan, transportasi, ekonomi, demografi, event), berikan ringkasan terstruktur dan praktis.',
    ];
    if (ctx.isNotEmpty) {
      parts.add('Konteks tambahan dari basis data:\n$ctx');
    }
    parts.add('Pertanyaan pengguna: "$userInput"');
    parts.add('Jika informasi tidak cukup, katakan dengan jujur dan minta klarifikasi.');
    return parts.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
        appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade600,
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nita',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: Colors.green,
                        size: 8,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        // actions removed for cleaner mobile UI
        ),
        body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Bot Introduction Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE3F2FD),
                          Color(0xFFF5F5F5),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.blue.shade600,
                          child: const Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Halo! Saya Nita',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Asisten virtual Anda untuk informasi dan layanan. Ada yang bisa saya bantu?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Menu chips removed for cleaner UI
                        const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Chat Messages
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: message['isBot']
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                          children: [
                            if (message['isBot']) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue.shade600,
                                child: const Icon(
                                  Icons.smart_toy,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: message['isBot']
                                      ? Colors.white
                                      : Colors.blue.shade600,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: message['isBot'] 
                                        ? const Radius.circular(4)
                                        : const Radius.circular(18),
                                    bottomRight: message['isBot']
                                        ? const Radius.circular(18)
                                        : const Radius.circular(4),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (message['isBot'])
                                      MarkdownBody(
                                        data: message['text'] ?? '',
                                        selectable: true,
                                        styleSheet: MarkdownStyleSheet(
                                          p: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.35),
                                          h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                          h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                          h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                          listBullet: const TextStyle(color: Colors.black87),
                                        ),
                                      )
                                    else
                                      Text(
                                        message['text'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    // Destination cards section removed
                                    const SizedBox(height: 4),
                                    Text(
                                      message['time'],
                                      style: TextStyle(
                                        color: message['isBot']
                                            ? Colors.grey
                                            : Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!message['isBot']) ...[
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey.shade300,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  // Input container with flexible width
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _focusNode,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Ketik pesan Anda...',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          // Attachment button hidden (placeholder removed)
                        ],
                      ),
                    ),
                  ),
                  // Always-visible send button, enabled only when text is present
                  SizedBox(
                    width: 64,
                    child: Opacity(
                      opacity: _messageController.text.trim().isNotEmpty && !_isLoading ? 1.0 : 0.5,
                      child: GestureDetector(
                              onTap: () async {
                                final input = _messageController.text.trim();
                                if (input.isEmpty || _isLoading) return;

                                // Append user message
                                setState(() {
                                  _messages.add({
                                    'text': input,
                                    'isBot': false,
                                    'time': _nowHHmm(),
                                  });
                                  _isLoading = true;
                                });

                                _messageController.clear();
                                _focusNode.unfocus();

                                // Add typing placeholder
                                int botIndex = -1;
                                setState(() {
                                  _messages.add({
                                    'text': 'Sedang mengetik...'
                                        ,
                                    'isBot': true,
                                    'time': _nowHHmm(),
                                  });
                                  botIndex = _messages.length - 1;
                                });

                                // Enforce Malang-only scope
                                if (_mentionsNonMalangCity(input)) {
                                  setState(() {
                                    _messages[botIndex >= 0 ? botIndex : _messages.length - 1] = {
                                      'text': 'Maaf, Nita hanya melayani informasi untuk wilayah Malang.',
                                      'isBot': true,
                                      'time': _nowHHmm(),
                                    };
                                    _isLoading = false;
                                  });
                                  return;
                                }

                                // Try to fetch extra context from Supabase to enrich the answer
                                String extraContext = '';
                                try {
                                  extraContext = await _fetchContextFromSupabase(input);
                                } catch (_) {
                                  // ignore errors and continue without context
                                }

                                // API key guard
                                if (_apiKey.isEmpty) {
                                  setState(() {
                                    _messages[botIndex >= 0 ? botIndex : _messages.length - 1] = {
                                      'text': 'API key belum diset. Jalankan aplikasi dengan --dart-define=GEMINI_API_KEY=YOUR_KEY',
                                      'isBot': true,
                                      'time': _nowHHmm(),
                                    };
                                    _isLoading = false;
                                  });
                                  return;
                                }

                                // Build Gemini chat history
                                final history = _messages
                                    .where((m) => (m['text'] as String).isNotEmpty && (m['text'] as String) != 'Sedang mengetik...')
                                    .map((m) => Content(
                                          m['isBot'] == true ? 'model' : 'user',
                                          [TextPart(m['text'] as String)],
                                        ))
                                    .toList();

                                // Inject formatting instructions and optional RAG context before sending the latest user input
                                final instruction = _buildInstruction(input, extraContext);
                                history.add(Content('user', [TextPart(instruction)]));

                                try {
                                  // Start chat with history and send latest user input
                                  final chat = _gemini.startChat(history: history);
                                  final response = await chat.sendMessage(Content.text(input));
                                  final answer = response.text ?? '';
                                  setState(() {
                                    _messages[botIndex >= 0 ? botIndex : _messages.length - 1] = {
                                      'text': answer.isEmpty ? 'Tidak ada jawaban.' : answer,
                                      'isBot': true,
                                      'time': _nowHHmm(),
                                    };
                                  });
                                } catch (e) {
                                  setState(() {
                                    _messages[botIndex >= 0 ? botIndex : _messages.length - 1] = {
                                      'text': 'Terjadi kesalahan jaringan: $e',
                                      'isBot': true,
                                      'time': _nowHHmm(),
                                    };
                                  });
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              },
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue.shade600,
                                child: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}