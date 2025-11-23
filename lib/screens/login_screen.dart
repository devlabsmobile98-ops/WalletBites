// Import Material for Design and Screens for Navigation
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import for Database
import 'package:wallet_bites/screens/home_screen.dart';

// Login Page Widget Containing Login/Sign-Up Tabs
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  
  // Tab Controller For Switching Between Login And Sign Up Views
  late TabController _tabController;

  // Controllers For Form Inputs
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Global Key For Form Validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initializing Tabs For Login And Sign Up
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    // Disposing Controllers To Prevent Memory Leaks
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // Function Handling User Login With Supabase Authentication
  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Navigates To Home Screen After Successful Login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } on AuthException catch (error) {
        // Displays Authentication Error Messages
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  // Function Handling Account Creation With Extra User Data
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          data: {
            'first_name': _firstNameController.text,
            'last_name': _lastNameController.text,
          },
        );

        // Notifies User To Confirm Account Via Email
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check your email for a confirmation link.')),
          );
        }
      } on AuthException catch (error) {
        // Displays Authentication Error Messages
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[600],

      // Centers Content And Allows Scrolling On Smaller Screens
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),

          // Main Form For Both Login And Sign Up Tabs
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.asset('lib/assets/images/fries.png', height: 150),

                const SizedBox(height: 20),

                // App Title
                const Text(
                  'Wallet Bites',
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontFamily: 'HowdyBun',
                  ),
                ),

                const SizedBox(height: 40),

                // Tab Selector For Login/Sign Up
                TabBar(
                  controller: _tabController,
                  labelStyle: const TextStyle(fontFamily: 'HowdyBun', fontSize: 20),
                  unselectedLabelStyle: const TextStyle(fontFamily: 'HowdyBun', fontSize: 20),
                  tabs: const [
                    Tab(text: 'Login'),
                    Tab(text: 'Sign Up'),
                  ],
                ),

                const SizedBox(height: 20),

                // Switchable Views: Login Tab And Sign-Up Tab
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginTab(),   // Login UI
                      _buildSignUpTab(),  // Sign Up UI
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds Login Tab Inputs And Button
  Widget _buildLoginTab() {
    return Column(
      children: [
        // Email Input Field
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          validator: (value) => value!.isEmpty ? 'Please enter an email' : null,
        ),

        const SizedBox(height: 20),

        // Password Input Field
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          obscureText: true,
          validator: (value) => value!.isEmpty ? 'Please enter a password' : null,
        ),

        const SizedBox(height: 30),

        // Login Button Triggering _signIn()
        ElevatedButton(
          onPressed: _signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'HowdyBun'),
          ),
          child: const Text(
            'Login',
            style: TextStyle(color: Colors.white, fontFamily: 'HowdyBun'),
          ),
        ),
      ],
    );
  }

  // Builds Sign-Up Tab Inputs And Button
  Widget _buildSignUpTab() {
    return Column(
      children: [
        // First Name Input
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'First Name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          validator: (value) => value!.isEmpty ? 'Please enter your first name' : null,
        ),

        const SizedBox(height: 20),

        // Last Name Input
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          validator: (value) => value!.isEmpty ? 'Please enter your last name' : null,
        ),

        const SizedBox(height: 20),

        // Email Input
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          validator: (value) => value!.isEmpty ? 'Please enter an email' : null,
        ),

        const SizedBox(height: 20),

        // Password Input
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          obscureText: true,
          validator: (value) => value!.isEmpty ? 'Please enter a password' : null,
        ),

        const SizedBox(height: 30),

        // Sign-Up Button Triggering _signUp()
        ElevatedButton(
          onPressed: _signUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'HowdyBun'),
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(color: Colors.white, fontFamily: 'HowdyBun'),
          ),
        ),
      ],
    );
  }
}
