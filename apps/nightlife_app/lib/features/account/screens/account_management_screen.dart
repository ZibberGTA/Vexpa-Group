import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/account_self_service.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deleteReasonController = TextEditingController();

  bool _pushDeals = true;
  bool _pushEvents = true;
  bool _emailUpdates = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _deleteReasonController.dispose();
    super.dispose();
  }

  Future<void> _run(String successMessage, Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage My Account')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Display name')),
                    const SizedBox(height: 12),
                    TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number')),
                    const SizedBox(height: 12),
                    TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'City')),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _run(
                        'Profile updated',
                        () => AccountSelfService.updateProfileDetails(
                          displayName: _nameController.text,
                          phone: _phoneController.text,
                          city: _cityController.text,
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('Save profile'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Login & security', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Current email: ${user?.email ?? 'Unknown'}'),
                    const SizedBox(height: 12),
                    TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'New email address')),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _run('Verification email sent to your new address', () => AccountSelfService.updateEmailAddress(_emailController.text)),
                      icon: const Icon(Icons.mark_email_read),
                      label: const Text('Change email'),
                    ),
                    const Divider(height: 28),
                    TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _run('Password updated', () => AccountSelfService.updatePassword(_passwordController.text)),
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Change password'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For security, Firebase may ask you to log in again before changing email or password.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notifications & privacy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SwitchListTile(
                      value: _pushDeals,
                      onChanged: (value) => setState(() => _pushDeals = value),
                      title: const Text('Push notifications for deals'),
                    ),
                    SwitchListTile(
                      value: _pushEvents,
                      onChanged: (value) => setState(() => _pushEvents = value),
                      title: const Text('Push notifications for events'),
                    ),
                    SwitchListTile(
                      value: _emailUpdates,
                      onChanged: (value) => setState(() => _emailUpdates = value),
                      title: const Text('Email updates'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _run(
                        'Notification preferences saved',
                        () => AccountSelfService.saveNotificationPreferences(
                          pushDeals: _pushDeals,
                          pushEvents: _pushEvents,
                          emailUpdates: _emailUpdates,
                        ),
                      ),
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Save preferences'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delete account request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 8),
                    const Text('This sends a deletion request to the staff team. Some records may need to be retained for legal, billing, safety, or dispute reasons.'),
                    const SizedBox(height: 12),
                    TextField(controller: _deleteReasonController, maxLines: 3, decoration: const InputDecoration(labelText: 'Reason, optional')),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDeletionRequest(context),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Request account deletion'),
                    ),
                  ],
                ),
              ),
            ),
            if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeletionRequest(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request account deletion?'),
        content: const Text('Your request will be reviewed by staff. You can still use your account while the request is pending.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Request deletion')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run('Account deletion request submitted', () => AccountSelfService.requestAccountDeletion(reason: _deleteReasonController.text));
  }
}
