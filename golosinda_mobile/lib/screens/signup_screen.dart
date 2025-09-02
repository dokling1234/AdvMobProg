import 'package:flutter/material.dart';
import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isObscure = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _userService.registerUser({
          "firstName": _firstNameController.text,
          "lastName": _lastNameController.text,
          "age": _ageController.text,
          "gender": _genderController.text,
          "contactNumber": _contactNumberController.text,
          "email": _emailController.text,
          "username": _usernameController.text,
          "address": _addressController.text,
          "password": _passwordController.text,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup successful: ${response['message']}")),
        );

        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup failed: $e")),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscure = false, TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter $label";
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(_firstNameController, "First Name"),
                const SizedBox(height: 12),
                _buildTextField(_lastNameController, "Last Name"),
                const SizedBox(height: 12),
                _buildTextField(_ageController, "Age",
                    inputType: TextInputType.number),
                const SizedBox(height: 12),
                _buildTextField(_genderController, "Gender"),
                const SizedBox(height: 12),
                _buildTextField(_contactNumberController, "Contact Number",
                    inputType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField(_emailController, "Email",
                    inputType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _buildTextField(_usernameController, "Username"),
                const SizedBox(height: 12),
                _buildTextField(_addressController, "Address"),
                const SizedBox(height: 12),

                // Password
                _buildTextField(_passwordController, "Password", obscure: true),
                const SizedBox(height: 12),
                _buildTextField(_confirmPasswordController, "Confirm Password",
                    obscure: true),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign Up", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
