import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_provider.dart';
import '../services/firebase_chat_service.dart';
import '../routes/app_routes.dart';

class ChatHistoryPage extends StatefulWidget {
  @override
  _ChatHistoryPageState createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ตรวจสอบการ login ก่อน
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        // ถ้ายังไม่ได้ login ให้ login แบบ anonymous
        await FirebaseAuth.instance.signInAnonymously();
        print('Signed in anonymously');
      }

      // รอ delay เล็กน้อยให้ Firebase initialization เสร็จ
      await Future.delayed(Duration(milliseconds: 500));

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print('Error initializing page: $e');
      setState(() {
        _error = 'ไม่สามารถโหลดข้อมูลได้: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        title: Text(
          'ประวัติการสนทนา',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD2B48C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.black),
            onPressed: () => _startNewChat(),
            tooltip: 'เริ่มการสนทนาใหม่',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: () => _initializePage(),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startNewChat(),
        backgroundColor: const Color(0xFFD2B48C),
        foregroundColor: Colors.black,
        child: Icon(Icons.add),
        tooltip: 'เริ่มการสนทนาใหม่',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFD2B48C)),
            ),
            SizedBox(height: 16),
            Text(
              'กำลังโหลดประวัติการสนทนา...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Column(
          children: [
            // แสดงสถานะ Firebase
            _buildFirebaseStatusIndicator(chatProvider),
            
            // สถิติการใช้งาน
            _buildStatisticsCard(chatProvider),
            
            // รายการ sessions
            Expanded(
              child: _buildSessionsList(chatProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializePage,
              icon: Icon(Icons.refresh),
              label: Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2B48C),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseStatusIndicator(ChatProvider chatProvider) {
    final user = FirebaseAuth.instance.currentUser;
    final isConnected = user != null;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: chatProvider.error != null 
        ? Colors.red[50] 
        : isConnected 
          ? Colors.green[50] 
          : Colors.orange[50],
      child: Row(
        children: [
          Icon(
            chatProvider.error != null 
              ? Icons.cloud_off 
              : isConnected 
                ? Icons.cloud_done 
                : Icons.cloud_queue,
            size: 16,
            color: chatProvider.error != null 
              ? Colors.red 
              : isConnected 
                ? Colors.green 
                : Colors.orange,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              chatProvider.error != null 
                ? 'Error: ${chatProvider.error}'
                : isConnected
                  ? 'เชื่อมต่อ Firebase สำเร็จ (${user?.uid?.substring(0, 8)}...)'
                  : 'กำลังเชื่อมต่อ Firebase...',
              style: TextStyle(
                fontSize: 12,
                color: chatProvider.error != null 
                  ? Colors.red[700] 
                  : isConnected 
                    ? Colors.green[700] 
                    : Colors.orange[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chatProvider.error != null)
            IconButton(
              icon: Icon(Icons.close, size: 16),
              onPressed: () => chatProvider.clearError(),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(ChatProvider chatProvider) {
    if (chatProvider.chatSessions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: chatProvider.chatSessions.length,
      itemBuilder: (context, index) {
        final session = chatProvider.chatSessions[index];
        return _buildSessionCard(session, chatProvider);
      },
    );
  }

  Widget _buildSessionCard(ChatSession session, ChatProvider chatProvider) {
    final isCurrentSession = session.id == chatProvider.currentSessionId;
    
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentSession 
          ? BorderSide(color: const Color(0xFFD2B48C), width: 2)
          : BorderSide.none,
      ),
      color: isCurrentSession ? const Color(0xFFD2B48C).withOpacity(0.1) : Colors.white,
      child: InkWell(
        onTap: () => _openSession(session.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCurrentSession ? const Color(0xFF8B4513) : Colors.black87,
                      ),
                    ),
                  ),
                  if (isCurrentSession)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2B48C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'กำลังใช้งาน',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleSessionAction(value, session, chatProvider),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: const Color(0xFF8B4513)),
                            SizedBox(width: 8),
                            Text('เปลี่ยนชื่อ', style: TextStyle(color: const Color(0xFF8B4513))),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('ลบ', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (session.lastMessage != null) ...[
                SizedBox(height: 8),
                Text(
                  session.lastMessage!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    _formatDateTime(session.updatedAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.message, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    '${session.messageCount} ข้อความ',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
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
              color: const Color(0xFFD2B48C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: const Color(0xFF8B4513),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'ยังไม่มีประวัติการสนทนา',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B4513),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'เริ่มต้นการสนทนาใหม่เพื่อสอบถามเกี่ยวกับสุนัข',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _startNewChat(),
            icon: Icon(Icons.add, color: Colors.black),
            label: Text('เริ่มการสนทนาใหม่', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD2B48C),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(ChatProvider chatProvider) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD2B48C),
            const Color(0xFF8B4513),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD2B48C).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FutureBuilder<ChatStatistics?>(
        future: chatProvider.getChatStatistics(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final stats = snapshot.data!;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('การสนทนา', '${stats.totalSessions}', Icons.chat),
                _buildStatItem('ข้อความ', '${stats.totalMessages}', Icons.message),
                _buildStatItem('คำถาม', '${stats.userMessages}', Icons.help),
                _buildStatItem('คำตอบ', '${stats.botMessages}', Icons.smart_toy),
              ],
            );
          }
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('การสนทนา', '${chatProvider.chatSessions.length}', Icons.chat),
              _buildStatItem('ข้อความ', '${chatProvider.messages.length}', Icons.message),
              _buildStatItem('คำถาม', '0', Icons.help),
              _buildStatItem('คำตอบ', '0', Icons.smart_toy),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'วันนี้ ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'เมื่อวาน ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  void _startNewChat() async {
    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.startNewSession();
      Navigator.pushReplacementNamed(context, AppRoutes.chat);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถสร้างการสนทนาใหม่ได้: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openSession(String sessionId) async {
    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.loadSession(sessionId);
      Navigator.pushReplacementNamed(context, AppRoutes.chat);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถโหลดการสนทนาได้: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleSessionAction(String action, ChatSession session, ChatProvider chatProvider) {
    switch (action) {
      case 'rename':
        _showRenameDialog(session, chatProvider);
        break;
      case 'delete':
        _showDeleteConfirmDialog(session, chatProvider);
        break;
    }
  }

  void _showRenameDialog(ChatSession session, ChatProvider chatProvider) {
    final controller = TextEditingController(text: session.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('เปลี่ยนชื่อการสนทนา', style: TextStyle(color: const Color(0xFF8B4513))),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'ชื่อใหม่',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFD2B48C)),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await chatProvider.updateSessionTitle(session.id, controller.text.trim());
                Navigator.pop(context);
                
                if (chatProvider.error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เปลี่ยนชื่อเรียบร้อยแล้ว'),
                      backgroundColor: const Color(0xFFD2B48C),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD2B48C),
              foregroundColor: Colors.black,
            ),
            child: Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(ChatSession session, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ลบการสนทนา', style: TextStyle(color: const Color(0xFF8B4513))),
        content: Text('คุณต้องการลบการสนทนา "${session.title}" หรือไม่?\n\nการกระทำนี้ไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              await chatProvider.deleteSession(session.id);
              Navigator.pop(context);
              
              if (chatProvider.error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ลบการสนทนาเรียบร้อยแล้ว'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('ลบ'),
          ),
        ],
      ),
    );
  }
}