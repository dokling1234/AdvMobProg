import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

enum LoginType { firebase, backend, none }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;
  LoginType _loginType = LoginType.none;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _userService.getUserData();
      print("DEBUG: Retrieved user data: $userData");
      
      // Use the isFirebaseAuth flag to determine login type
      if (userData['isFirebaseAuth'] == true) {
        _loginType = LoginType.firebase;
        print("DEBUG: Detected Firebase authentication");
      } else if ((userData['token'] ?? '').isNotEmpty || (userData['_id'] ?? '').isNotEmpty) {
        _loginType = LoginType.backend;
        print("DEBUG: Detected MongoDB authentication");
      }

      print("DEBUG: Final login type: $_loginType");
      print("DEBUG: isFirebaseAuth: ${userData['isFirebaseAuth']}");
      print("DEBUG: token: ${userData['token']}");
      print("DEBUG: _id: ${userData['_id']}");

      if (_loginType != LoginType.none) {
        setState(() {
          _user = User.fromJson(userData);
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUsername() async {
    final controller = TextEditingController(text: _user?.username ?? "");
    final newUsername = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Username"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "New Username"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text("Update")),
        ],
      ),
    );

    if (newUsername != null && newUsername.isNotEmpty) {
      try {
        if (_loginType == LoginType.firebase) {
          await _userService.updateUsername(username: newUsername);
        } else if (_loginType == LoginType.backend) {
          final userId = _user?.uid ?? '';
          await _userService.updateUsernameMongoDB(userId: userId, username: newUsername);
        }
        await _loadUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username updated successfully")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e")));
      }
    }
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentController, obscureText: true, decoration: const InputDecoration(labelText: "Current Password")),
            const SizedBox(height: 16),
            TextField(controller: newController, obscureText: true, decoration: const InputDecoration(labelText: "New Password")),
            const SizedBox(height: 16),
            TextField(controller: confirmController, obscureText: true, decoration: const InputDecoration(labelText: "Confirm New Password")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Change")),
        ],
      ),
    );

    if (confirmed == true && _user != null) {
      // Validate password confirmation
      if (newController.text != confirmController.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New passwords do not match")));
        }
        return;
      }

      try {
        if (_loginType == LoginType.firebase) {
          await _userService.resetPasswordFromCurrentPassword(
            currentPassword: currentController.text,
            newPassword: newController.text,
            email: _user!.email,
          );
        } else if (_loginType == LoginType.backend) {
          final userId = _user?.uid ?? '';
          await _userService.changePasswordMongoDB(
            userId: userId,
            currentPassword: currentController.text,
            newPassword: newController.text,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed successfully")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password change failed: $e")));
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (_user == null) return;
    
    // Ask for password confirmation for security
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("This action cannot be undone. Please enter your password to confirm account deletion.", 
                     style: TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.isNotEmpty) {
      try {
        if (_loginType == LoginType.firebase) {
          await _userService.deleteAccount(email: _user!.email, password: passwordController.text);
        } else if (_loginType == LoginType.backend) {
          final userId = _user?.uid ?? '';
          await _userService.deleteUserMongoDB(userId);
        }

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text("No user data found"))
              : SafeArea(
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(),
                      // Details + Settings
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            _buildInfoTile("Email", _user!.email, Icons.email),
                            _buildInfoTile("Username", _user!.username, Icons.person),
                            _buildInfoTile("Contact Number", _user!.contactNumber, Icons.phone),
                            _buildInfoTile("Age", _user!.age, Icons.cake),
                            _buildInfoTile("Gender", _user!.gender, Icons.people),
                            _buildInfoTile("Address", _user!.address, Icons.location_on),
                            _buildInfoTile(
                              "Status",
                              _user!.isActive ? "Active" : "Inactive",
                              _user!.isActive ? Icons.check_circle : Icons.cancel,
                              isStatus: true,
                            ),
                            const Divider(height: 40),
                            const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text("Update Username"),
                              onTap: _updateUsername,
                            ),
                            ListTile(
                              leading: const Icon(Icons.lock),
                              title: const Text("Change Password"),
                              onTap: _changePassword,
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
                              onTap: _deleteAccount,
                            ),
                            ListTile(
                              leading: const Icon(Icons.logout, color: Colors.red),
                              title: const Text("Logout"),
                              onTap: () async {
                                await _userService.signOut();
                                if (mounted) {
                                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[100],
            child: Text(
              _user!.firstName.isNotEmpty ? _user!.firstName[0].toUpperCase() : "?",
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 16),
          Text("${_user!.firstName} ${_user!.lastName}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_user!.type.toUpperCase(), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            _loginType == LoginType.firebase ? "Firebase Auth" : 
            _loginType == LoginType.backend ? "MongoDB Auth" : "Unknown",
            style: const TextStyle(color: Colors.blue, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, {bool isStatus = false}) {
    return ListTile(
      leading: Icon(icon, color: isStatus ? (value == "Active" ? Colors.green : Colors.red) : Colors.grey[700]),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value.isNotEmpty ? value : "-", style: TextStyle(color: Colors.grey[600])),
    );
  }
}
