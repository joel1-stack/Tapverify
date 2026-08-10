import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              style: GoogleFonts.inter(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or code...',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
              : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No members found',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final m = _filtered[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ConfirmScreen(member: m)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFF059669).withOpacity(0.1),
                                    child: Text(
                                      m.name[0].toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0f172a),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${m.phone}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Ksh ${m.balanceDue.toStringAsFixed(0)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: Colors.grey.shade300,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
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
