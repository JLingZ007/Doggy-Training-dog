import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import 'gemini_service.dart';
import 'firebase_chat_service.dart';

class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final GeminiService _geminiService = GeminiService();
  final FirebaseChatService _firebaseChatService = FirebaseChatService();
  
  bool _isLoading = false;
  String? _error;
  String? _currentSessionId;
  List<ChatSession> _chatSessions = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentSessionId => _currentSessionId;
  List<ChatSession> get chatSessions => List.unmodifiable(_chatSessions);

  ChatProvider() {
    _initializeChat();
  }

  // เริ่มต้นการแชท
  Future<void> _initializeChat() async {
    try {
      _loadChatSessions();
    } catch (e) {
      print('Error initializing chat: $e');
      _error = 'ไม่สามารถเชื่อมต่อ Firebase ได้';
      notifyListeners();
    }
  }

  // โหลด chat sessions จาก Firebase
  void _loadChatSessions() {
    try {
      _firebaseChatService.getChatSessions().listen((sessions) {
        _chatSessions = sessions;
        notifyListeners();
      });
    } catch (e) {
      print('Error loading chat sessions: $e');
      _error = 'ไม่สามารถโหลดประวัติการสนทนาได้';
      notifyListeners();
    }
  }

  // สร้าง session ใหม่
  Future<void> startNewSession({String? title}) async {
    try {
      _currentSessionId = await _firebaseChatService.createChatSession(
        title: title ?? 'แชทเกี่ยวกับสุนัข'
      );
      
      _messages.clear();
      addWelcomeMessage();
      notifyListeners();
    } catch (e) {
      print('Error starting new session: $e');
      _error = 'ไม่สามารถสร้างการสนทนาใหม่ได้';
      notifyListeners();
    }
  }

  // โหลด session ที่มีอยู่
  Future<void> loadSession(String sessionId) async {
    try {
      _currentSessionId = sessionId;
      _messages.clear();
      
      // ฟัง messages จาก Firebase real-time
      _firebaseChatService.getMessages(sessionId).listen((messages) {
        _messages.clear();
        _messages.addAll(messages);
        notifyListeners();
      });
      
      notifyListeners();
    } catch (e) {
      print('Error loading session: $e');
      _error = 'ไม่สามารถโหลดการสนทนาได้';
      notifyListeners();
    }
  }

  // ส่งข้อความ
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // สร้าง session ใหม่ถ้าไม่มี
    if (_currentSessionId == null) {
      await startNewSession();
    }

    // Clear any previous errors
    _error = null;
    
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    _messages.add(userMessage);
    notifyListeners();

    // บันทึกข้อความ user
    await _saveMessage(userMessage);

    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      // Get response from Gemini API
      final response = await _geminiService.sendMessage(content);
      
      // Add bot response
      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );
      
      _messages.add(botMessage);
      
      // บันทึกข้อความ bot
      await _saveMessage(botMessage);
      
    } catch (e) {
      // Set error state
      _error = 'เกิดข้อผิดพลาดในการส่งข้อความ';
      
      // Add error message
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'ขออภัย เกิดข้อผิดพลาดในการติดต่อ กรุณาลองใหม่อีกครั้ง\n\nError: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.error,
      );
      
      _messages.add(errorMessage);
      
      print('Error sending message: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // บันทึกข้อความ
  Future<void> _saveMessage(ChatMessage message) async {
    if (_currentSessionId == null) return;

    try {
      await _firebaseChatService.saveMessage(
        sessionId: _currentSessionId!,
        message: message,
      );
    } catch (e) {
      print('Error saving message: $e');
      _error = 'ไม่สามารถบันทึกข้อความได้';
      notifyListeners();
    }
  }

  // ลบการสนทนาปัจจุบัน
  Future<void> clearMessages() async {
    try {
      if (_currentSessionId != null) {
        await _firebaseChatService.deleteChatSession(_currentSessionId!);
      }
      
      _messages.clear();
      _currentSessionId = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('Error clearing messages: $e');
      _error = 'ไม่สามารถลบการสนทนาได้';
      notifyListeners();
    }
  }

  // ลบ session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _firebaseChatService.deleteChatSession(sessionId);
      _chatSessions.removeWhere((session) => session.id == sessionId);
      
      if (sessionId == _currentSessionId) {
        _messages.clear();
        _currentSessionId = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error deleting session: $e');
      _error = 'ไม่สามารถลบการสนทนาได้';
      notifyListeners();
    }
  }

  // อัปเดตชื่อ session
  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    try {
      await _firebaseChatService.updateSessionTitle(sessionId, newTitle);
      
      // อัปเดต local list
      final index = _chatSessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        _chatSessions[index] = ChatSession(
          id: _chatSessions[index].id,
          userId: _chatSessions[index].userId,
          title: newTitle,
          messageCount: _chatSessions[index].messageCount,
          lastMessage: _chatSessions[index].lastMessage,
          createdAt: _chatSessions[index].createdAt,
          updatedAt: DateTime.now(),
          isActive: _chatSessions[index].isActive,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error updating session title: $e');
      _error = 'ไม่สามารถเปลี่ยนชื่อการสนทนาได้';
      notifyListeners();
    }
  }

  // ลบข้อความเดียว
  Future<void> removeMessage(String messageId) async {
    try {
      if (_currentSessionId != null) {
        await _firebaseChatService.deleteMessage(_currentSessionId!, messageId);
      }
      
      _messages.removeWhere((message) => message.id == messageId);
      notifyListeners();
    } catch (e) {
      print('Error removing message: $e');
      _error = 'ไม่สามารถลบข้อความได้';
      notifyListeners();
    }
  }

  // ดึงสถิติ
  Future<ChatStatistics?> getChatStatistics() async {
    try {
      return await _firebaseChatService.getChatStatistics();
    } catch (e) {
      print('Error getting statistics: $e');
      return null;
    }
  }

  // Get suggested questions
  List<String> getSuggestedQuestions() {
    return _geminiService.getSuggestedQuestions();
  }

  // Add a welcome message if no messages exist
  void addWelcomeMessage() {
    if (_messages.isEmpty) {
      final welcomeMessage = ChatMessage(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        content: 'สวัสดีครับ! ผมคือผู้ช่วยด้านการฝึกสุนัข 🐕\n\nผมพร้อมตอบคำถามเกี่ยวกับ:\n• การฝึกพฤติกรรมสุนัข\n• การดูแลสุขภาพ\n• โภชนาการและอาหาร\n• การแก้ปัญหาพฤติกรรม\n\nมีคำถามอะไรเกี่ยวกับน้องหมาไหมครับ?',
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      _messages.add(welcomeMessage);
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}