import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../models/user_model.dart';
import '../data/faq_repository.dart';
import '../domain/gemini_service.dart';
import '../domain/keyword_chatbot_engine.dart';
import 'chatbot_controller.dart';
import 'widgets/chatbot_header.dart';
import 'widgets/message_bubble.dart';
import 'widgets/quick_reply_chips.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/chat_input_bar.dart';

/// Callback para navegar a una pestaña por índice:
/// 0=Inicio, 1=Bosque, 2=Cursos, 3=Perfil
typedef NavigateTabCallback = void Function(int index);

class ChatbotScreen extends StatefulWidget {
  final NavigateTabCallback? onNavigateTab;

  const ChatbotScreen({super.key, this.onNavigateTab});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  late ChatbotController _controller;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOffline = false;

  String _getRoleString(UserRole role) {
    return switch (role) {
      UserRole.coordinador => 'coordinador',
      UserRole.admin => 'admin',
      UserRole.campista => 'campista',
    };
  }

  @override
  void initState() {
    super.initState();
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);

    _controller = ChatbotController(
      aiEngine: GeminiService(),
      localEngine: KeywordChatbotEngine(repository: FaqRepository()),
      currentRole: () {
        final role = authProvider.user?.role ?? UserRole.campista;
        return _getRoleString(role);
      },
    );

    _checkInitialConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectivity);

    _controller.addListener(_onControllerUpdate);
    _controller.start();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectivity(results);
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final offline = !results.any((r) => r != ConnectivityResult.none);
    if (mounted && _isOffline != offline) {
      setState(() {
        _isOffline = offline;
      });
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleAction(String? action) {
    if (action == null || widget.onNavigateTab == null) return;
    final idx = switch (action) {
      'ir_inicio' => 0,
      'ir_bosque' => 1,
      'ir_cursos' => 2,
      'ir_perfil' => 3,
      _ => -1,
    };
    if (idx >= 0) widget.onNavigateTab!(idx);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatbotHeader(isOffline: _isOffline),
      body: Column(
        children: [
          // Privacy footer banner
          Container(
            width: double.infinity,
            color: const Color(0xFFF6FAF4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Text(
              'El asistente responde sobre CampJu. Para casos urgentes de salud o seguridad, comunícate con tu coordinador.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF5F6B65),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1),
          // Messages list
          Expanded(
            child: _controller.messages.isEmpty && !_controller.isTyping
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: _controller.messages.length +
                        (_controller.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _controller.messages.length &&
                          _controller.isTyping) {
                        return const TypingIndicator();
                      }

                      final msg = _controller.messages[index];
                      final isLast = index == _controller.messages.length - 1;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MessageBubble(
                            message: msg,
                            onActionTap: msg.action != null
                                ? () => _handleAction(msg.action)
                                : null,
                          ),
                          // Show chips only on last bot message
                          if (isLast &&
                              msg.isBot &&
                              msg.chips.isNotEmpty &&
                              !_controller.isTyping)
                            QuickReplyChips(
                              chips: msg.chips,
                              onChipTap: (chip) => _controller.send(chip),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          ChatInputBar(
            onSend: _controller.send,
            enabled: !_controller.isTyping,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
