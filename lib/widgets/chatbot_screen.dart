import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/generated/l10n.dart';
import 'package:expense_tracker/services/ai_service.dart';
import 'package:expense_tracker/database/database_helper.dart';
import 'package:expense_tracker/providers/theme_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with SingleTickerProviderStateMixin {
  final AIService _aiService = AIService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final List<Map<String, dynamic>> _chatHistory = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isTyping = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _chatHistory.add({
      'role': 'bot',
      'message': 'Hi! I’m your financial assistant. Ask me about your spending, budgets, or get tips to save money! Try something like "How much did I spend this month?" or "Get budget tips."',
      'timestamp': DateTime.now(),
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _goalController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendQuery(String query, {String? userGoal}) async {
    if (query.trim().isEmpty) return;

    if (mounted) {
      setState(() {
        _chatHistory.add({
          'role': 'user',
          'message': query,
          'timestamp': DateTime.now(),
        });
        _isLoading = true;
        _isTyping = true;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    String response;
    if (query.toLowerCase().contains('budget tip') || query.toLowerCase().contains('save')) {
      final tips = await _aiService.generateBudgetTips(userGoal);
      response = 'Here are your budget tips:\n${tips.map((tip) => '- $tip').join('\n')}';
      _chatHistory.add({
        'role': 'bot',
        'message': response,
        'timestamp': DateTime.now(),
        'tips': tips,
      });
    } else {
      response = await _aiService.handleChatQuery(query);
      _chatHistory.add({
        'role': 'bot',
        'message': response,
        'timestamp': DateTime.now(),
      });
    }

    if (mounted) {
      setState(() {
        _isTyping = false;
        _isLoading = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    _queryController.clear();
  }

  void _sendQuickReply(String reply) {
    HapticFeedback.mediumImpact();
    _queryController.text = reply;
    _sendQuery(reply);
  }

  Future<void> _saveFeedback(String tip, bool isPositive) async {
    HapticFeedback.mediumImpact();
    await _dbHelper.insertFeedback(tip, isPositive);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPositive ? 'Thanks for your feedback!' : 'Noted, we’ll improve!',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isPositive ? Colors.green[600] : Colors.red[600],
      ),
    );
  }

  Future<void> _showGoalDialog() async {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [const Color(0xFF2E2E2E), const Color(0xFF424242)]
                  : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Set Your Financial Goal',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _goalController,
                  decoration: InputDecoration(
                    labelText: 'E.g., Save for a trip, Pay off debt',
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF37474F) : const Color(0xFFE1F5FE),
                  ),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        final goal = _goalController.text.trim();
                        if (goal.isNotEmpty) {
                          _sendQuery('Get budget tips', userGoal: goal);
                        }
                        Navigator.pop(context);
                        _goalController.clear();
                      },
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                : [const Color(0xFFE8F5E9), const Color(0xFFF3E5F5)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [const Color(0xFF2E2E2E), const Color(0xFF424242)]
                        : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Financial Assistant',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                        shadows: [
                          Shadow(
                            blurRadius: 2,
                            color: isDarkMode ? Colors.black26 : Colors.grey[300]!,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatHistory.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == _chatHistory.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                                child: Icon(
                                  Icons.smart_toy,
                                  size: 20,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 2,
                                      color: isDarkMode ? Colors.black26 : Colors.grey[300]!,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Typing...',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final message = _chatHistory[index];
                    final isUser = message['role'] == 'user';
                    final tips = message['tips'] as List<String>?;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser)
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                              child: Icon(
                                Icons.smart_toy,
                                size: 20,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2,
                                    color: isDarkMode ? Colors.black26 : Colors.grey[300]!,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (tips != null)
                                  ...tips.map((tip) => Card(
                                        elevation: 5,
                                        shadowColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: isDarkMode
                                                  ? [const Color(0xFF263238), const Color(0xFF37474F)]
                                                  : [Colors.white, const Color(0xFFE1F5FE)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            title: Text(
                                              tip,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isDarkMode ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.thumb_up,
                                                    color: isDarkMode ? Colors.green[300] : Colors.green[600],
                                                    size: 22,
                                                    shadows: [
                                                      Shadow(
                                                        blurRadius: 2,
                                                        color: isDarkMode ? Colors.black26 : Colors.grey[300]!,
                                                        offset: const Offset(1, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  onPressed: () => _saveFeedback(tip, true),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.thumb_down,
                                                    color: isDarkMode ? Colors.red[300] : Colors.red[600],
                                                    size: 22,
                                                    shadows: [
                                                      Shadow(
                                                        blurRadius: 2,
                                                        color: isDarkMode ? Colors.black26 : Colors.grey[300]!,
                                                        offset: const Offset(1, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  onPressed: () => _saveFeedback(tip, false),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ))
                                else
                                  Card(
                                    elevation: 5,
                                    shadowColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: isUser
                                              ? (isDarkMode
                                                  ? [const Color(0xFF1B5E20), const Color(0xFF4CAF50)]
                                                  : [const Color(0xFFDCEDC8), const Color(0xFFDCE775)])
                                              : (isDarkMode
                                                  ? [const Color(0xFF263238), const Color(0xFF37474F)]
                                                  : [Colors.white, const Color(0xFFE1F5FE)]),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          message['message'],
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('hh:mm a').format(message['timestamp']),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isUser) const SizedBox(width: 8),
                          if (isUser)
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isDarkMode ? Colors.green[300] : Colors.green[600],
                              child: Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2,
                                    color: isDarkMode ? Colors.black26 : Colors.grey[300]!,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (!_isLoading && _chatHistory.length <= 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        elevation: 5,
                        shadowColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.transparent,
                        onPressed: () => _sendQuickReply('How much did I spend this month?'),
                        label: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDarkMode
                                  ? [const Color(0xFF263238), const Color(0xFF37474F)]
                                  : [Colors.white, const Color(0xFFE1F5FE)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            'Monthly spending?',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      ActionChip(
                        elevation: 5,
                        shadowColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.transparent,
                        onPressed: () => _showGoalDialog(),
                        label: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDarkMode
                                  ? [const Color(0xFF263238), const Color(0xFF37474F)]
                                  : [Colors.white, const Color(0xFFE1F5FE)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            'Get budget tips',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      ActionChip(
                        elevation: 5,
                        shadowColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.transparent,
                        onPressed: () => _sendQuickReply('What are my top spending categories?'),
                        label: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDarkMode
                                  ? [const Color(0xFF263238), const Color(0xFF37474F)]
                                  : [Colors.white, const Color(0xFFE1F5FE)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            'Top categories?',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [const Color(0xFF263238), const Color(0xFF37474F)]
                        : [Colors.white, const Color(0xFFE1F5FE)],
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        decoration: InputDecoration(
                          labelText: l10n.title,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: isDarkMode ? const Color(0xFF37474F) : const Color(0xFFE1F5FE),
                          labelStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.amber[300] : Colors.deepPurple[800],
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        onSubmitted: (_) => _sendQuery(_queryController.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDarkMode ? Colors.teal[400]! : Colors.teal[600]!,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: isDarkMode ? Colors.teal[400] : Colors.teal[600],
                              size: 24,
                              shadows: [
                                Shadow(
                                  blurRadius: 2,
                                  color: isDarkMode ? Colors.black26 : Colors.grey[300]!,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                      onPressed: _isLoading ? null : () => _sendQuery(_queryController.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}