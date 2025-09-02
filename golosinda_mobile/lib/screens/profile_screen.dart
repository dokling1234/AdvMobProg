import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_model.dart'; // <-- Your User model

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _userService.getUserData(); // returns Map<String, dynamic>?
    
    if (userData != null) {
      setState(() {
        _user = User.fromJson(userData);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text("No user data found"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        child: Text(
                          _user!.firstName.isNotEmpty
                              ? _user!.firstName[0].toUpperCase()
                              : "?",
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoTile("Name",
                          "${_user!.firstName} ${_user!.lastName}"),
                      _buildInfoTile("Email", _user!.email),
                      _buildInfoTile("Username", _user!.username),
                      _buildInfoTile("Type", _user!.type),
                      _buildInfoTile("Contact Number", _user!.contactNumber),
                      _buildInfoTile("Age", _user!.age),
                      _buildInfoTile("Gender", _user!.gender),
                      _buildInfoTile("Address", _user!.address),
                      _buildInfoTile(
                          "Status", _user!.isActive ? "Active" : "Inactive"),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value.isNotEmpty ? value : "-"),
      ),
    );
  }
}
