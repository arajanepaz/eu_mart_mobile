import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  bool _changingPassword = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDocument() async {
    final User? user = currentUser;

    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController currentPasswordController =
        TextEditingController();

    final TextEditingController newPasswordController = TextEditingController();

    final TextEditingController confirmPasswordController =
        TextEditingController();

    bool hideCurrentPassword = true;
    bool hideNewPassword = true;
    bool hideConfirmPassword = true;

    String? errorMessage;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> changePassword() async {
              final String currentPassword = currentPasswordController.text
                  .trim();

              final String newPassword = newPasswordController.text.trim();

              final String confirmPassword = confirmPasswordController.text
                  .trim();

              setDialogState(() {
                errorMessage = null;
              });

              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                setDialogState(() {
                  errorMessage = 'Please complete all password fields.';
                });
                return;
              }

              if (newPassword.length < 6) {
                setDialogState(() {
                  errorMessage =
                      'The new password must contain at least 6 characters.';
                });
                return;
              }

              if (newPassword != confirmPassword) {
                setDialogState(() {
                  errorMessage = 'The new passwords do not match.';
                });
                return;
              }

              final User? user = currentUser;

              if (user == null || user.email == null) {
                setDialogState(() {
                  errorMessage = 'Unable to load the current account.';
                });
                return;
              }

              setDialogState(() {
                _changingPassword = true;
              });

              try {
                final AuthCredential credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: currentPassword,
                );

                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword);

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } on FirebaseAuthException catch (error) {
                String message = 'Unable to change password.';

                if (error.code == 'wrong-password' ||
                    error.code == 'invalid-credential') {
                  message = 'The current password is incorrect.';
                } else if (error.code == 'weak-password') {
                  message = 'The new password is too weak.';
                } else if (error.code == 'requires-recent-login') {
                  message = 'Please log out, log in again, and retry.';
                }

                setDialogState(() {
                  errorMessage = message;
                });
              } catch (error) {
                setDialogState(() {
                  errorMessage = 'Error: $error';
                });
              } finally {
                setDialogState(() {
                  _changingPassword = false;
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.lock_reset, color: Color(0xFF1565C0)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Change Password',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: hideCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              hideCurrentPassword = !hideCurrentPassword;
                            });
                          },
                          icon: Icon(
                            hideCurrentPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: newPasswordController,
                      obscureText: hideNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.password),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              hideNewPassword = !hideNewPassword;
                            });
                          },
                          icon: Icon(
                            hideNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: hideConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.password_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              hideConfirmPassword = !hideConfirmPassword;
                            });
                          },
                          icon: Icon(
                            hideConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _changingPassword
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _changingPassword ? null : changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                  child: _changingPassword
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Password'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<bool> _confirmLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _logout() async {
    final bool confirmed = await _confirmLogout();

    if (!confirmed) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _informationTile({
    required IconData icon,
    required String label,
    required String value,
    Color color = const Color(0xFF1565C0),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'My Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getUserDocument(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Text(
                  'Unable to load account information.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Account information was not found.'),
            );
          }

          final Map<String, dynamic> data =
              snapshot.data!.data() ?? <String, dynamic>{};

          final String fullName = (data['fullName'] ?? 'User').toString();

          final String email =
              (data['email'] ?? currentUser?.email ?? 'No email available')
                  .toString();

          final String phone = (data['phone'] ?? 'Not provided').toString();

          final String role = (data['role'] ?? 'user').toString();

          final bool isActive = data['isActive'] is bool
              ? data['isActive'] as bool
              : true;

          final String roleText = role.isEmpty
              ? 'User'
              : '${role[0].toUpperCase()}${role.substring(1)}';

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 65,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        roleText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Account Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 13),
                _informationTile(
                  icon: Icons.person_outline,
                  label: 'Full Name',
                  value: fullName,
                ),
                _informationTile(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: email,
                ),
                _informationTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: phone,
                ),
                _informationTile(
                  icon: Icons.badge_outlined,
                  label: 'Account Role',
                  value: roleText,
                  color: Colors.deepPurple,
                ),
                _informationTile(
                  icon: isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  label: 'Account Status',
                  value: isActive ? 'Active' : 'Disabled',
                  color: isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Security',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 13),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE3F2FD),
                      child: Icon(Icons.lock_reset, color: Color(0xFF1565C0)),
                    ),
                    title: const Text(
                      'Change Password',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Update your account password.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  height: 53,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'LOGOUT',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
