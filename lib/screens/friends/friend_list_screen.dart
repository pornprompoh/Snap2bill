import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ดึงรายชื่อเพื่อนมาแสดงเมื่อเปิดหน้าจอ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadFriends();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('สมุดรายชื่อเพื่อน'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'พิมพ์ชื่อเพื่อนที่นี่...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.trim().isNotEmpty) {
                      await userProvider.addFriend(_nameController.text.trim());
                      _nameController.clear();
                    }
                  },
                  child: const Text('เพิ่ม'),
                ),
              ],
            ),
          ),
          Expanded(
            child: userProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : userProvider.friends.isEmpty
                    ? const Center(child: Text('ยังไม่มีเพื่อนในสมุดรายชื่อ'))
                    : ListView.builder(
                        itemCount: userProvider.friends.length,
                        itemBuilder: (context, index) {
                          final friend = userProvider.friends[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(friend.friendName ?? 'ไม่มีชื่อ'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}