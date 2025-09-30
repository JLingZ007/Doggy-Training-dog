import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../services/chat_provider.dart';
import '../models/chat_models.dart';
import '../widgets/bottom_navbar.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.currentSessionId == null) {
        chatProvider.addWelcomeMessage();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ⬇️ ครอบคลุม: คำสั่งปิดคีย์บอร์ด
  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
    // เผื่อบางรุ่นที่ดื้อ ๆ
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _closeKeyboard();             // ⬅️ ปิดคีย์บอร์ดทันทีที่กดส่ง
    _messageController.clear();

    final chatProvider = context.read<ChatProvider>();
    await chatProvider.sendMessage(message);

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.pets,
                color: const Color(0xFF8B4513),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ผู้ช่วยฝึกสุนัข',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return Text(
                      chatProvider.error != null
                          ? 'การเชื่อมต่อผิดพลาด'
                          : 'พร้อมให้คำปรึกษา',
                      style: TextStyle(
                        fontSize: 12,
                        color: chatProvider.error != null
                            ? Colors.red[800]
                            : Colors.black54,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD2B48C),
        elevation: 0,
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'new_session':
                      _startNewSession();
                      break;
                    case 'clear':
                      _showClearConfirmDialog();
                      break;
                    case 'refresh':
                      chatProvider.clearError();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'new_session',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 18, color: const Color(0xFF8B4513)),
                        SizedBox(width: 8),
                        Text('สร้างการสนทนาใหม่',
                            style: TextStyle(color: const Color(0xFF8B4513))),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('ล้างการสนทนา',
                            style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),
                  if (chatProvider.error != null)
                    PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.sync, size: 18, color: const Color(0xFF8B4513)),
                          SizedBox(width: 8),
                          Text('ลองเชื่อมต่อใหม่',
                              style: TextStyle(color: const Color(0xFF8B4513))),
                        ],
                      ),
                    ),
                ],
                child: Icon(Icons.more_vert, color: Colors.black),
              );
            },
          ),
        ],
      ),
      // ⬇️ ครอบ Column ด้วย GestureDetector เพื่อแตะที่ว่างแล้วปิดคีย์บอร์ด
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _closeKeyboard,
        child: Column(
          children: [
            // แสดง error banner ถ้ามี
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.error != null) {
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    color: Colors.red[50],
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            chatProvider.error!,
                            style: TextStyle(color: Colors.red[700], fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red, size: 18),
                          onPressed: () => chatProvider.clearError(),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),

            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.messages.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, // ⬅️ ลากเลื่อนแล้วคีย์บอร์ดหาย
                    itemCount: chatProvider.messages.length +
                        (chatProvider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatProvider.messages.length &&
                          chatProvider.isLoading) {
                        return _buildTypingIndicator();
                      }

                      final message = chatProvider.messages[index];
                      return _buildMessageBubble(message);
                    },
                  );
                },
              ),
            ),

            // Suggested questions
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.messages.length <= 1) {
                  return _buildSuggestedQuestions();
                }
                return SizedBox.shrink();
              },
            ),

            _buildMessageInput(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFD2B48C).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              size: 60,
              color: const Color(0xFF8B4513),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'ยินดีต้อนรับสู่ผู้ช่วยฝึกสุนัข',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B4513),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ถามคำถามเกี่ยวกับการฝึกและดูแลสุนัขได้เลย!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: const Color(0xFFD2B48C).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets,
                color: const Color(0xFF8B4513),
                size: 20,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFFD2B48C) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              height: 1.4,
                            ),
                            strong: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                if (message.status == MessageStatus.error)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'ส่งไม่สำเร็จ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFD2B48C).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              color: const Color(0xFF8B4513),
              size: 20,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(const Color(0xFF8B4513)),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'กำลังตอบ...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    final suggestions = context.read<ChatProvider>().getSuggestedQuestions();

    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                suggestions[index],
                style: TextStyle(fontSize: 12, color: const Color(0xFF8B4513)),
              ),
              onPressed: () {
                _messageController.text = suggestions[index];
                _closeKeyboard();   // ⬅️ ปิดคีย์บอร์ดด้วยเวลาใช้ชิป
                _sendMessage();
              },
              backgroundColor: const Color(0xFFD2B48C).withOpacity(0.3),
              side: BorderSide(color: const Color(0xFFD2B48C)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6F8),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFFD2B48C).withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'พิมพ์คำถามของคุณ...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  textInputAction: TextInputAction.send, // ⬅️ ปุ่ม Enter = ส่ง
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            SizedBox(width: 8),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2B48C),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: chatProvider.isLoading ? null : _sendMessage,
                    icon: Icon(
                      chatProvider.isLoading ? Icons.hourglass_empty : Icons.send,
                      color: Colors.black,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startNewSession() async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.startNewSession();
  }

  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ล้างการสนทนา',
              style: TextStyle(color: const Color(0xFF8B4513))),
          content: Text('คุณต้องการล้างประวัติการสนทนาปัจจุบันหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () {
                context.read<ChatProvider>().clearMessages();
                Navigator.of(context).pop();
              },
              child: Text('ล้าง', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
