import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_models.dart';

class FirebaseChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _chatSessionsCollection => 
      _firestore.collection('chat_sessions');
  
  CollectionReference get _chatMessagesCollection => 
      _firestore.collection('chat_messages');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // สร้าง chat session ใหม่
  Future<String> createChatSession({String? title}) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final sessionData = {
      'userId': currentUserId,
      'title': title ?? 'แชทเกี่ยวกับสุนัข',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'messageCount': 0,
      'isActive': true,
    };

    final docRef = await _chatSessionsCollection.add(sessionData);
    return docRef.id;
  }

  // บันทึกข้อความ
  Future<void> saveMessage({
    required String sessionId,
    required ChatMessage message,
  }) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final messageData = {
      'sessionId': sessionId,
      'userId': currentUserId,
      'messageId': message.id,
      'content': message.content,
      'isUser': message.isUser,
      'timestamp': Timestamp.fromDate(message.timestamp),
      'status': message.status.toString(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    // บันทึกข้อความ
    await _chatMessagesCollection.add(messageData);

    // อัปเดต session
    await _chatSessionsCollection.doc(sessionId).update({
      'updatedAt': FieldValue.serverTimestamp(),
      'messageCount': FieldValue.increment(1),
      'lastMessage': message.content.length > 100 
          ? '${message.content.substring(0, 100)}...'
          : message.content,
    });
  }

  // ดึงข้อความทั้งหมดใน session
  Stream<List<ChatMessage>> getMessages(String sessionId) {
    return _chatMessagesCollection
        .where('sessionId', isEqualTo: sessionId)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapDocumentToChatMessage(doc))
            .toList());
  }

  // ดึง chat sessions ของ user
  Stream<List<ChatSession>> getChatSessions() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _chatSessionsCollection
        .where('userId', isEqualTo: currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapDocumentToChatSession(doc))
            .toList());
  }

  // ลบ chat session
  Future<void> deleteChatSession(String sessionId) async {
    if (currentUserId == null) throw Exception('User not logged in');

    // ลบข้อความทั้งหมดใน session
    final messagesQuery = await _chatMessagesCollection
        .where('sessionId', isEqualTo: sessionId)
        .where('userId', isEqualTo: currentUserId)
        .get();

    final batch = _firestore.batch();
    
    for (var doc in messagesQuery.docs) {
      batch.delete(doc.reference);
    }

    // ลบ session
    batch.update(_chatSessionsCollection.doc(sessionId), {
      'isActive': false,
      'deletedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // อัปเดตชื่อ session
  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    if (currentUserId == null) throw Exception('User not logged in');

    await _chatSessionsCollection.doc(sessionId).update({
      'title': newTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ลบข้อความเดียว
  Future<void> deleteMessage(String sessionId, String messageId) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final messageQuery = await _chatMessagesCollection
        .where('sessionId', isEqualTo: sessionId)
        .where('messageId', isEqualTo: messageId)
        .where('userId', isEqualTo: currentUserId)
        .get();

    final batch = _firestore.batch();
    
    for (var doc in messageQuery.docs) {
      batch.delete(doc.reference);
    }

    // อัปเดตจำนวนข้อความใน session
    batch.update(_chatSessionsCollection.doc(sessionId), {
      'messageCount': FieldValue.increment(-messageQuery.docs.length),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // แปลง Document เป็น ChatMessage
  ChatMessage _mapDocumentToChatMessage(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatMessage(
      id: data['messageId'] ?? doc.id,
      content: data['content'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  // แปลง Document เป็น ChatSession
  ChatSession _mapDocumentToChatSession(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'แชทเกี่ยวกับสุนัข',
      messageCount: data['messageCount'] ?? 0,
      lastMessage: data['lastMessage'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // สำหรับสถิติการใช้งาน
  Future<ChatStatistics> getChatStatistics() async {
    if (currentUserId == null) throw Exception('User not logged in');

    // นับจำนวน sessions
    final sessionsSnapshot = await _chatSessionsCollection
        .where('userId', isEqualTo: currentUserId)
        .where('isActive', isEqualTo: true)
        .get();

    // นับจำนวนข้อความทั้งหมด
    final messagesSnapshot = await _chatMessagesCollection
        .where('userId', isEqualTo: currentUserId)
        .get();

    // นับข้อความของ user vs bot
    int userMessages = 0;
    int botMessages = 0;
    
    for (var doc in messagesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isUser'] == true) {
        userMessages++;
      } else {
        botMessages++;
      }
    }

    return ChatStatistics(
      totalSessions: sessionsSnapshot.docs.length,
      totalMessages: messagesSnapshot.docs.length,
      userMessages: userMessages,
      botMessages: botMessages,
    );
  }
}

// Model สำหรับ Chat Session
class ChatSession {
  final String id;
  final String userId;
  final String title;
  final int messageCount;
  final String? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.messageCount,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });
}

// Model สำหรับสถิติ
class ChatStatistics {
  final int totalSessions;
  final int totalMessages;
  final int userMessages;
  final int botMessages;

  ChatStatistics({
    required this.totalSessions,
    required this.totalMessages,
    required this.userMessages,
    required this.botMessages,
  });
}