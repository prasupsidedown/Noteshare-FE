import 'package:flutter/material.dart';
import '../pages/chatbot_page.dart';

class FloatingChatButton extends StatelessWidget {
  const FloatingChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => const ChatbotPage(),
        );
      },
      child: const Icon(Icons.chat_bubble_outline),
      elevation: 2,
    );
  }
}