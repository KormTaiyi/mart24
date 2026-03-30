import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String? avatarAssetPath;
  final bool isOnline;

  const ChatScreen({
    super.key,
    required this.contactName,
    this.avatarAssetPath,
    this.isOnline = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottomButton = false;

  final List<_ChatMessage> _messages = <_ChatMessage>[];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollPosition);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(jump: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollPosition);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final String value = _messageController.text.trim();
    if (value.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(text: value, isMe: true, time: _formatNowTime()),
      );
      _messageController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      Future<void>.delayed(const Duration(milliseconds: 140), () {
        if (!mounted) {
          return;
        }
        _scrollToBottom();
      });
    });
  }

  void _scrollToBottom({bool jump = false}) {
    if (!_scrollController.hasClients) {
      return;
    }

    final double max = _scrollController.position.maxScrollExtent;
    if (jump) {
      _scrollController.jumpTo(max);
      return;
    }

    _scrollController.animateTo(
      max,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _handleScrollPosition() {
    if (!_scrollController.hasClients) {
      return;
    }

    final bool shouldShow = _scrollController.position.extentAfter > 220;
    if (shouldShow == _showScrollToBottomButton) {
      return;
    }

    setState(() {
      _showScrollToBottomButton = shouldShow;
    });
  }

  String _formatNowTime() {
    final DateTime now = DateTime.now();
    final int hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final String minute = now.minute.toString().padLeft(2, '0');
    final String suffix = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: Column(
        children: [
          _ChatHeader(
            name: widget.contactName,
            avatarAssetPath: widget.avatarAssetPath,
            isOnline: widget.isOnline,
          ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet.',
                      style: TextStyle(color: Color(0xFF666666), fontSize: 16),
                    ),
                  )
                : Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          10,
                          10,
                          10,
                          keyboardInset > 0 ? 26 : 18,
                        ),
                        itemCount: _messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: _DayChip(label: 'Today'),
                            );
                          }

                          final _ChatMessage message = _messages[index - 1];
                          return _MessageBubble(message: message);
                        },
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: IgnorePointer(
                          ignoring: !_showScrollToBottomButton,
                          child: AnimatedOpacity(
                            opacity: _showScrollToBottomButton ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: GestureDetector(
                              onTap: _scrollToBottom,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF5A5A5A),
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          _ChatComposer(controller: _messageController, onSend: _sendMessage),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String name;
  final String? avatarAssetPath;
  final bool isOnline;

  const _ChatHeader({
    required this.name,
    required this.avatarAssetPath,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final String initials = name.isEmpty ? '?' : name[0].toUpperCase();
    final double topInset = MediaQuery.paddingOf(context).top;

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            backgroundImage: avatarAssetPath != null
                ? AssetImage(avatarAssetPath!)
                : null,
            child: avatarAssetPath == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF2B2B2B),
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: AppTextStyles.caption.copyWith(
                    color: isOnline ? const Color(0xFF2DD66D) : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              EneftyIcons.call_outline,
              color: Colors.white,
              size: 25,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              EneftyIcons.more_outline,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;

  const _DayChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBDBDBD)),
          color: const Color(0xFFF1F1F1),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF959595),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final Alignment alignment = message.isMe
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final Color bubbleColor = message.isMe
        ? AppColors.primary
        : const Color(0xFFD9D9D9);
    final Color textColor = message.isMe
        ? Colors.white
        : const Color(0xFF2A2A2A);

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: message.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: textColor,
                  height: 1.35,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.time,
                style: const TextStyle(
                  color: Color(0xFFA1A1A1),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (message.isMe) ...[
                const SizedBox(width: 4),
                const Icon(Icons.done_all, size: 16, color: AppColors.primary),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatComposer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final double safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final double composerBottomPadding = keyboardInset > 0
        ? 8
        : (safeBottomInset > 0 ? safeBottomInset + 8 : 16);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, composerBottomPadding),
      color: const Color(0xFFF1F1F1),
      child: Row(
        children: [
          _CircleButton(icon: EneftyIcons.link_2_outline, onTap: () {}),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFDFDFDF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Message',
                        hintStyle: TextStyle(
                          color: Color(0xFFA4A4A4),
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onSend,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF63BBF0),
                      ),
                      child: const Icon(
                        EneftyIcons.send_2_outline,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _CircleButton(icon: EneftyIcons.microphone_2_outline, onTap: () {}),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFFD8D8D8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: 25),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  const _ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });
}
