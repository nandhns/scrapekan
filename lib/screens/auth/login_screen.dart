import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../main_screen.dart';
import 'register_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/data_seeder.dart';
import '../../config/app_config.dart';
import '../../scripts/seed_machine_data.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _logoTapCount = 0;
  final int _requiredTapsForDevMode = 7;

  @override
  void initState() {
    super.initState();
  }

  void _handleLogoTap() {
    setState(() {
      _logoTapCount++;
      if (_logoTapCount >= _requiredTapsForDevMode) {
        if (!AppConfig.isDevelopment) {
          AppConfig.enableDevelopmentMode();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Developer mode enabled'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        _logoTapCount = 0; // Reset counter
      }
    });
  }

  Future<void> _seedData() async {
    setState(() => _isLoading = true);
    try {
      final seeder = MachineDataSeeder();
      await seeder.seedMachineData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Machine data seeded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error seeding data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Login',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 32),
                GestureDetector(
                  onTap: _handleLogoTap,
                  child: Text(
                    'Welcome to ScraPekan',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 32),
                if (_errorMessage != null) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[900]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _isLoading
                    ? ElevatedButton(
                        onPressed: null,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _handleLogin,
                        child: Text('Login'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterScreen()),
                        );
                      },
                  child: Text('Don\'t have an account? Register'),
                ),
                if (AppConfig.isDevelopment) ...[
                  Divider(height: 32),
                  Text(
                    'Developer Mode',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : TextButton.icon(
                        onPressed: _seedData,
                        icon: Icon(Icons.data_array),
                        label: Text('Seed Machine Data'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                        ),
                      ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      AppConfig.disableDevelopmentMode();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Developer mode disabled'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    child: Text('Disable Developer Mode'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = await authService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );

        if (!mounted) return;

        if (user != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (!mounted) return;
        
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 