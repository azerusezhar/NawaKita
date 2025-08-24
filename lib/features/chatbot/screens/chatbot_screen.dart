import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isInputFocused = false;
  final String _baseUrl = 'https://malang-chat-backend-865303528514.asia-southeast2.run.app';
  bool _isLoading = false;
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Bagaimana cara mengurus KTP yang hilang?',
      'isBot': false,
      'time': '14:32'
    },
    {
      'text': 'Untuk mengurus KTP yang hilang, Anda perlu:\n\n1. Buat surat kehilangan di kepolisian\n2. Siapkan fotokopi KK dan akta lahir\n3. Datang ke Disdukcapil terdekat\n\nApakah ada yang ingin Anda tanyakan lebih lanjut?',
      'isBot': true,
      'time': '14:33'
    }
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.credit_card,
      'label': 'Layanan KTP',
      'color': Colors.blue,
    },
    {
      'icon': Icons.account_balance,
      'label': 'Info Pajak',
      'color': Colors.green,
    },
    {
      'icon': Icons.location_on,
      'label': 'Rekomendasi Wisata',
      'color': Colors.orange,
    },
    {
      'icon': Icons.store,
      'label': 'UMKM Lokal',
      'color': Colors.purple,
    },
    {
      'icon': Icons.school,
      'label': 'Info Pendidikan',
      'color': Colors.indigo,
    },
    {
      'icon': Icons.local_hospital,
      'label': 'Layanan Kesehatan',
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Listen to focus changes
    _focusNode.addListener(() {
      setState(() {
        _isInputFocused = _focusNode.hasFocus;
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
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}';
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
                  const Row(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
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
                      vertical: 24,
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
                          radius: 40,
                          backgroundColor: Colors.blue.shade600,
                          child: const Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Halo! Saya Nita',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Asisten virtual Anda untuk informasi dan layanan. Ada yang bisa saya bantu?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Menu Wrap
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _menuItems.map((item) {
                            return GestureDetector(
                              onTap: () {
                                // Handle menu item tap
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: item['color'].withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        item['icon'],
                                        color: item['color'],
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item['label'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
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
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['text'],
                                      style: TextStyle(
                                        color: message['isBot']
                                            ? Colors.black87
                                            : Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
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
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.attach_file,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                          ),
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

                                // Build messages payload
                                final payloadMessages = _messages.map((m) => {
                                      'role': m['isBot'] == true
                                          ? 'assistant'
                                          : 'user',
                                      'content': m['text'] as String,
                                    }).toList();

                                try {
                                  final resp = await http.post(
                                    Uri.parse('$_baseUrl/chat'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({
                                      'messages': payloadMessages,
                                      'city': 'Malang',
                                    }),
                                  );

                                  if (resp.statusCode == 200) {
                                    final data = jsonDecode(resp.body) as Map<String, dynamic>;
                                    final answer = (data['answer'] ?? '').toString();
                                    setState(() {
                                      _messages[botIndex >= 0 ? botIndex : _messages.length - 1] = {
                                        'text': answer.isEmpty ? 'Tidak ada jawaban.' : answer,
                                        'isBot': true,
                                        'time': _nowHHmm(),
                                      };
                                    });
                                  } else {
                                    setState(() {
                                      _messages[botIndex >= 0 ? botIndex : _messages.length - 1] = {
                                        'text': 'Gagal memproses (${resp.statusCode}).',
                                        'isBot': true,
                                        'time': _nowHHmm(),
                                      };
                                    });
                                  }
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