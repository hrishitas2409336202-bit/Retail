import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_state.dart';
import 'support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final profile = state.currentRole == UserRole.admin ? state.ownerProfile : state.staffProfile;
    _nameController = TextEditingController(text: profile['name']);
    _emailController = TextEditingController(text: profile['email']);
    _phoneController = TextEditingController(text: profile['phone']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(state.tr('Profile'),
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          TextButton(
            onPressed: () {
              if (_isEditing) {
                if (state.currentRole == UserRole.admin) {
                  state.updateSettings(
                    storeName: state.storeName,
                    upiId: state.upiId,
                    upiName: state.upiName,
                    globalThreshold: state.globalThreshold,
                    currency: state.currency,
                    taxRate: state.taxRate,
                    ownerName: _nameController.text,
                    ownerEmail: _emailController.text,
                    ownerPhone: _phoneController.text,
                  );
                } else {
                  state.updateStaffProfile(
                    name: _nameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                  );
                }
              }
              setState(() => _isEditing = !_isEditing);
            },
            child: Text(
              _isEditing ? 'Done' : 'Edit',
              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.purpleAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xFF1E293B),
                          child: Icon(LucideIcons.user, color: Colors.blueAccent.withValues(alpha: 0.8), size: 40),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.camera,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF0F172A), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Text(state.currentRole == UserRole.admin ? 'Owner / Admin' : '${state.tr('staff_role')} • Cashier',
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.storeName,
                    style: TextStyle(
                        color: isDark ? Colors.white.withOpacity(0.5) : Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.currentRole == UserRole.admin) ...[
                    // Quick Stats
                    Row(
                      children: [
                        _buildStatCard(state.tr('Today Sales'), '${state.todayBillsCount}',
                            LucideIcons.shoppingCart, Colors.blueAccent),
                        const SizedBox(width: 12),
                        _buildStatCard(
                            state.tr('Revenue'),
                            '${state.currency}${state.todayRevenue.toInt()}',
                            LucideIcons.trendingUp,
                            Colors.greenAccent),
                        const SizedBox(width: 12),
                        _buildStatCard(state.tr('Tickets'), '${state.activeTicketsCount}', LucideIcons.ticket,
                            Colors.purpleAccent, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (c) => const SupportScreen()));
                            }),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Personal Information
                  _sectionHeader(state.tr('Personal Information')),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoField(
                        state.tr('Full Name'), _nameController, LucideIcons.user),
                    Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                    _buildInfoField(
                        state.tr('Email'), _emailController, LucideIcons.mail),
                    Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                    _buildInfoField(
                        state.tr('Phone'), _phoneController, LucideIcons.phone),
                  ]),
                  const SizedBox(height: 24),

                  if (state.currentRole != UserRole.admin) ...[
                    // Work Information
                    _sectionHeader(state.tr('Work Information')),
                    const SizedBox(height: 12),
                    _buildInfoCard([
                      _buildReadonlyField(state.tr('Store'), state.storeName, LucideIcons.store),
                      Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                      _buildReadonlyField(state.tr('Role'), 'Cashier / Staff', LucideIcons.briefcase),
                      Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                      _buildReadonlyField(state.tr('Shift'), 'Morning (8AM - 4PM)', LucideIcons.clock),
                      Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                      _buildReadonlyField(state.tr('Employee ID'), 'EMP-2024-007', LucideIcons.badgeInfo),
                    ]),
                    const SizedBox(height: 24),
                  ],

                  // Account
                  _sectionHeader(state.tr('Account')),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12),
                      boxShadow: isDark ? [] : [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.logOut,
                            color: Colors.redAccent, size: 18),
                      ),
                      title: Text(state.tr('logout'),
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(state.tr('logout_subtitle'),
                          style: TextStyle(
                              color: isDark ? Colors.white.withOpacity(0.4) : Colors.black45,
                              fontSize: 12)),
                      onTap: () {
                        context.read<AppState>().logout();
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white.withOpacity(0.4) : Colors.black45,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.4) : Colors.black54, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoField(
      String label, TextEditingController controller, IconData icon) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: isDark ? Colors.white.withOpacity(0.4) : Colors.black45, fontSize: 12),
          prefixIcon: Icon(icon, color: Colors.blueAccent, size: 18),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildReadonlyField(String label, String value, IconData icon) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent.withOpacity(0.7), size: 18),
      title: Text(label,
          style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.4) : Colors.black45,
              fontSize: 11)),
      subtitle: Text(value,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
      dense: true,
    );
  }
}

