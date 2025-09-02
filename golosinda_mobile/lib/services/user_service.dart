import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class UserService {
  Map<String, dynamic> data = {};

  /// **Login User**
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    Response response = await post(
      Uri.parse('$host/api/users/login'),
      body: {"email": email, "password": password},
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);

      final user = data['user'];
      user['token'] = data['token'];

      await saveUserData(user);

      return user;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  /// **Save User Data to SharedPreferences**
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();


    await prefs.setString('uid', userData['uid'] ?? '');
    await prefs.setString('firstName', userData['firstName'] ?? '');
    await prefs.setString('lastName', userData['lastName'] ?? '');
    await prefs.setString('age', userData['age'] ?? '');
    await prefs.setString('gender', userData['gender'] ?? '');
    await prefs.setString('contactNumber', userData['contactNumber'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setString('username', userData['username'] ?? '');
    await prefs.setString('address', userData['address'] ?? '');
    await prefs.setBool('isActive', userData['isActive'] == true);
    await prefs.setString('type', userData['type'] ?? '');
    await prefs.setString('token', userData['token'] ?? '');
  }

  /// **Retrieve User Data from SharedPreferences**
  Future<Map<String, dynamic>> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userData = {
      'uid': prefs.getString('uid') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'age': prefs.getString('age') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'contactNumber': prefs.getString('contactNumber') ?? '',
      'email': prefs.getString('email') ?? '',
      'username': prefs.getString('username') ?? '',
      'address': prefs.getString('address') ?? '',
      'isActive': prefs.getBool('isActive') ?? false,
      'type': prefs.getString('type') ?? '',
      'token': prefs.getString('token') ?? '',
    };

    // print("Retrieved User Data: $userData"); // DEBUG
    return userData;
  }

  /// **Check if User is Logged In**
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getString('token') != null;
    return isLoggedIn;
  }

  /// **Register User**
  Future<Map<String, dynamic>> registerUser(
    Map<String, dynamic> userData,
  ) async {

    Response response = await post(
      Uri.parse('$host/api/users/register'),
      body: userData,
    );


    if (response.statusCode == 201) {
      final registeredData = jsonDecode(response.body);
      return registeredData;
    } else {

      throw Exception('Failed to register user: ${response.body}');
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
