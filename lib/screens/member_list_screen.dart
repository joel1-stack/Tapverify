import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';
import 'confirm_screen.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  List<Member> _members = [];
  List<Member> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final staff = HiveService.getStaff();
    final wsId = staff?['workspace']?['id'] ?? '';
    final members = await ApiService.fetchMembers(wsId);
    setState(() {
      _members = members;
      _filtered = members;
      _loading = false;
    });
  }

  void _filter(String q) {
    setState(() {
      _filtered = _members.where((m) =>
        m.name.toLowerCase().contains(q.toLowerCase()) ||
        m.phone.contains(q) ||
        m.memberCode.toLowerCase().contains(q.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Member')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or code...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final m = _filtered[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2D6A4F),
                        child: Text(m.name[0], style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(m.name),
                      subtitle: Text('${m.phone} • Balance: Ksh ${m.balanceDue.toStringAsFixed(0)}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ConfirmScreen(member: m)),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
