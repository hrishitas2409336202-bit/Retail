import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Billing Issue';

  final List<Map<String, dynamic>> _tickets = [
    {
      'id': 'TKT-001',
      'subject': 'Barcode scanner not responding',
      'category': 'Technical',
      'status': 'Open',
      'date': '15 Mar, 10:32 AM',
      'priority': 'High',
    },
    {
      'id': 'TKT-002',
      'subject': 'Stock count mismatch in Dairy section',
      'category': 'Inventory',
      'status': 'In Progress',
      'date': '14 Mar, 3:45 PM',
      'priority': 'Medium',
    },
    {
      'id': 'TKT-003',
      'subject': 'UPI payment failed for customer',
      'category': 'Billing Issue',
      'status': 'Resolved',
      'date': '13 Mar, 11:10 AM',
      'priority': 'Low',
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submitTicket() {
    if (_formKey.currentState!.validate()) {
      final state = context.read<AppState>();
      final now = DateTime.now();
      final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final ampm = now.hour >= 12 ? 'PM' : 'AM';
      final month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][now.month - 1];
      
      final newTicket = {
          'id': 'TKT-${(1001 + state.tickets.length).toString()}',
          'subject': _subjectController.text,
          'category': _selectedCategory,
          'status': 'Open',
          'date': '${now.day} $month, $hour:${now.minute.toString().padLeft(2, '0')} $ampm',
          'priority': 'Medium',
          'desc': _descController.text,
      };

      state.addTicket(newTicket);
      _subjectController.clear();
      _descController.clear();
      
      // Email simulation
      final emailUri = Uri(
        scheme: 'mailto',
        path: 'admin@${state.storeName.toLowerCase().replaceAll(' ', '')}.in',
        query: 'subject=[${_selectedCategory}] ${newTicket['subject']}&body=${newTicket['desc']}',
      );
      launchUrl(emailUri).catchError((_) => false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.checkCircle, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Ticket logged & forwarded to Admin!')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _modifyTicket(Map<String, dynamic> ticket) {
    String currentStatus = ticket['status'];
    String currentPriority = ticket['priority'];
    final state = context.read<AppState>();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Modify Ticket ${ticket['id']}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Status', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: ['Open', 'Accepted', 'In Progress', 'Resolved', 'Completed'].map((st) => ChoiceChip(
                  label: Text(st),
                  selected: currentStatus == st,
                  onSelected: (s) => setMState(() {
                    currentStatus = st;
                    state.updateTicketStatus(ticket['id'], st);
                  }),
                )).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Priority', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: ['Low', 'Medium', 'High'].map((pr) => ChoiceChip(
                  label: Text(pr),
                  selected: currentPriority == pr,
                  onSelected: (s) => setMState(() {
                    currentPriority = pr;
                    state.updateTicketPriority(ticket['id'], pr);
                  }),
                )).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text('Update Ticket'),
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
    final state = context.watch<AppState>();
    final tickets = state.tickets;
    final isAdmin = state.currentRole == UserRole.admin;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isAdmin ? 'Support Management' : 'Support Center',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAdmin) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1), const Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.25), blurRadius: 14, spreadRadius: 1),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Admin Console',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${tickets.where((t) => t['status'] != 'Resolved' && t['status'] != 'Completed').length} tickets pending',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (!isAdmin) ...[
              // Create New Ticket
              const Text('Create Ticket', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Category', LucideIcons.tag),
                        items: ['Billing Issue', 'Inventory', 'Technical', 'Payment', 'Other']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _subjectController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Subject', LucideIcons.fileText),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter a subject' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: _inputDecoration('Description (optional)', LucideIcons.messageSquare),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submitTicket,
                          icon: const Icon(LucideIcons.send, size: 16),
                          label: const Text('SUBMIT TICKET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Tickets List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAdmin ? 'Pending Tickets' : 'My Tickets', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '${tickets.where((t) => t['status'] != 'Resolved' && t['status'] != 'Completed').length} Active',
                    style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tickets.map((t) => _buildTicketCard(t, isAdmin)).toList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.purpleAccent, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purpleAccent)),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, bool isAdmin) {
    Color statusColor;
    IconData statusIcon;
    switch (ticket['status']) {
      case 'Accepted': statusColor = Colors.cyanAccent; statusIcon = LucideIcons.thumbsUp; break;
      case 'In Progress': statusColor = Colors.orangeAccent; statusIcon = LucideIcons.loader; break;
      case 'Resolved': statusColor = Colors.greenAccent; statusIcon = LucideIcons.checkCircle; break;
      case 'Completed': statusColor = Colors.greenAccent; statusIcon = LucideIcons.checkCircle2; break;
      default: statusColor = Colors.blueAccent; statusIcon = LucideIcons.clock;
    }

    Color priorityColor;
    switch (ticket['priority']) {
      case 'High': priorityColor = Colors.redAccent; break;
      case 'Medium': priorityColor = Colors.orangeAccent; break;
      default: priorityColor = Colors.greenAccent;
    }

    return GestureDetector(
      onTap: isAdmin ? () => _modifyTicket(ticket) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ticket['id'], style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontFamily: 'monospace')),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: priorityColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(ticket['priority'], style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(ticket['status'], style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 16),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(ticket['subject'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            if (isAdmin && (ticket['desc']?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 6),
              Text(ticket['desc'], style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.tag, size: 12, color: Colors.white.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text(ticket['category'], style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                const Spacer(),
                Icon(LucideIcons.clock, size: 12, color: Colors.white.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text(ticket['date'], style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

