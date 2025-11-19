import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_bites/screens/home_screen.dart';

class LoginPage extends StatefulWidget {const LoginPage({super.key});

@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } on AuthException catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check your email for a confirmation link.')),
          );
        }
      } on AuthException catch (error) {
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('lib/assets/images/fries.png', height: 150),
                const SizedBox(height: 20),
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
                SizedBox(
                  height: 400, // Adjust height as needed
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginTab(),
                      _buildSignUpTab(),
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

  Widget _buildLoginTab() {
    return Column(
      children: [
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
        ElevatedButton(
          onPressed: _signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'HowdyBun'),
          ),
          child: const Text('Login', style: TextStyle(
            color: Colors.white,
            fontFamily: 'HowdyBun',
          )),
        ),
      ],
    );
  }

  Widget _buildSignUpTab() {
    return Column(
      children: [
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
        ElevatedButton(
          onPressed: _signUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'HowdyBun'),
          ),
          child: const Text('Sign Up', style: TextStyle(
            color: Colors.white,
            fontFamily: 'HowdyBun',
          )),
        ),
      ],
    );
  }
}
