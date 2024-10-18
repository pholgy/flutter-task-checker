import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'task_dashboard.dart';
import 'admin.dart';
import 'register.dart';  // Import the Register page

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String errorMessage = '';  // To show error messages
  final pb = PocketBase('http://127.0.0.1:8090');  // Initialize PocketBase

  // Function to log in the user using PocketBase SDK
  Future<void> login(String email, String password) async {
    setState(() {
      errorMessage = '';
    });

    try {
      // Authenticate the user with email and password using PocketBase SDK
      final authData = await pb.collection('users').authWithPassword(email, password);

      // If authentication is successful, check the user's role
      if (pb.authStore.isValid) {
        final userId = pb.authStore.model.id;
        final userEmail = pb.authStore.model.data['email'];  // Access email from data map
        checkUserRole(userId, userEmail);
      } else {
        setState(() {
          errorMessage = 'Authentication failed.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Login failed: $e';
      });
    }
  }

  // Function to check if the logged-in user is an admin or a normal user
  Future<void> checkUserRole(String userId, String userEmail) async {
    try {
      // Fetch the user's details from PocketBase
      final userRecord = await pb.collection('users').getOne(userId);

      bool isAdmin = userRecord.data['isAdmin'] ?? false;  // Default to false if not present

      // Redirect to the appropriate page based on the role
      if (isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminPage(userEmail: userEmail)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TaskDashboard(userEmail: userEmail)),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error checking user role: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    login(emailController.text, passwordController.text);
                  }
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
              
              // Register button to navigate to the Register page
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),  // Navigate to the RegisterPage
                    ),
                  );
                },
                child: const Text("Don't have an account? Register here"),
              ),
              
              const SizedBox(height: 16),
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
