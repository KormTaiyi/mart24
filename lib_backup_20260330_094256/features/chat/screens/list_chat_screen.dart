import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/features/chat/screens/chat_screen.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';

class ListChatScreen extends StatefulWidget {
  const ListChatScreen({super.key});

  @override
  State<ListChatScreen> createState() => _ListChatScreenState();
}

class _ListChatScreenState extends State<ListChatScreen> {
  final TextEditingController _searchController = TextEditingController();

  late List<_ChatPreview> _chats;
  String _searchQuery = '';
  bool _isEditing = false;
  final Set<int> _selectedChatIds = <int>{};

  List<_ChatPreview> get _filteredChats {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _chats;
    }

    return _chats.where((chat) {
      return chat.name.toLowerCase().contains(query) ||
          chat.message.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _chats = <_ChatPreview>[];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _selectedChatIds.clear();
      }
    });
  }

  void _toggleSelectChat(int chatId) {
    setState(() {
      if (_selectedChatIds.contains(chatId)) {
        _selectedChatIds.remove(chatId);
      } else {
        _selectedChatIds.add(chatId);
      }
    });
  }

  void _deleteChatById(int chatId) {
    setState(() {
      _chats.removeWhere((chat) => chat.id == chatId);
      _selectedChatIds.remove(chatId);
    });
  }

  void _deleteSelectedChats() {
    if (_selectedChatIds.isEmpty) {
      return;
    }

    setState(() {
      _chats.removeWhere((chat) => _selectedChatIds.contains(chat.id));
      _selectedChatIds.clear();
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double cardWidth = size.width > 440 ? 390 : size.width;
    final double topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFF1F1E1D),
      body: Center(
        child: Container(
          width: cardWidth,
          height: size.height,
          decoration: const BoxDecoration(color: Color(0xFFF1F1F1)),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(0),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(16, topInset + 18, 16, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: _toggleEditMode,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isEditing
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _isEditing ? 'Done' : 'Edit',
                              style: AppTextStyles.subtitle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Chats',
                          style: AppTextStyles.title.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _isEditing && _selectedChatIds.isNotEmpty
                              ? _deleteSelectedChats
                              : null,
                          child: SizedBox(
                            width: 58,
                            child: Text(
                              _isEditing && _selectedChatIds.isNotEmpty
                                  ? 'Delete'
                                  : '',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            color: Color(0xFF232323),
                            fontSize: 18,
                          ),
                          prefixIcon: Icon(
                            EneftyIcons.search_normal_2_outline,
                            color: Colors.black,
                            size: 22,
                          ),
                          border: InputBorder.none,
                          // contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _filteredChats.isEmpty
                    ? const Center(
                        child: Text(
                          'No chats found.',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 5,
                        ),
                        itemCount: _filteredChats.length,
                        itemBuilder: (context, index) {
                          final _ChatPreview chat = _filteredChats[index];
                          return _buildDismissibleChat(chat);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleChat(_ChatPreview chat) {
    final Widget tile = _ChatTile(
      chat: chat,
      isEditing: _isEditing,
      isSelected: _selectedChatIds.contains(chat.id),
      onTap: () {
        if (_isEditing) {
          _toggleSelectChat(chat.id);
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatScreen(contactName: chat.name)),
        );
      },
    );

    if (_isEditing) {
      return tile;
    }

    return Slidable(
      key: ValueKey('chat-${chat.id}'),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.30,
        dismissible: DismissiblePane(
          onDismissed: () => _deleteChatById(chat.id),
          confirmDismiss: () async {
            return true;
          },
        ),
        children: [
          SlidableAction(
            onPressed: (_) => _deleteChatById(chat.id),
            backgroundColor: const Color(0xFFE04646),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
      child: tile,
    );
  }
}

class _ChatTile extends StatelessWidget {
  final _ChatPreview chat;
  final bool isEditing;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chat,
    required this.isEditing,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEditing)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 12),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF9A9A9A),
                ),
              ),
            _ChatAvatar(chat: chat),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F0F0F),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFA8A8A8)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chat.time,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final _ChatPreview chat;

  const _ChatAvatar({required this.chat});

  @override
  Widget build(BuildContext context) {
    final String initials = chat.name.isEmpty ? '?' : chat.name[0];

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFD4D4D4),
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF2B2B2B),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChatPreview {
  final int id;
  final String name;
  final String message;
  final String time;

  const _ChatPreview({
    required this.id,
    required this.name,
    required this.message,
    required this.time,
  });
}
