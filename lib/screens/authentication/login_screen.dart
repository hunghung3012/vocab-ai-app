import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vocab_ai/main_screen.dart';
import 'package:vocab_ai/screens/authentication/service/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool obscure = true;
  bool remember = false;
  bool isLoading = false;

  void _showSnack(String msg, {Color color = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Center(
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Sign in to continue learning",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    _buildInput(
                      controller: emailCtrl,
                      icon: Icons.email_outlined,
                      hint: "your@email.com",
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email is empty";
                        }

                        final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!regex.hasMatch(value)) {
                          return "Invalid email";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildInput(
                      controller: passwordCtrl,
                      icon: Icons.lock_outline,
                      hint: "Password",
                      obscure: obscure,
                      suffix: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => obscure = !obscure);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Password is empty";
                        }

                        if (value.length < 6) {
                          return "Password must be 6 characters or longer";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Checkbox(
                          value: remember,
                          onChanged: (v) => setState(() => remember = v!),
                        ),
                        const Text("Remember me"),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text("Forgot password?"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _gradientButton(
                      text: isLoading ? "Signing In..." : "Sign In",
                      onTap: isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;

                              setState(() => isLoading = true);

                              _showSnack("Logging in...", color: Colors.blue);

                              try {
                                final isLoginSuccess = await authService.signIn(
                                  emailCtrl.text.trim(),
                                  passwordCtrl.text.trim(),
                                );

                                if (isLoginSuccess) {
                                  _showSnack(
                                    "Login Success",
                                    color: Colors.green,
                                  );

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MainScreen(),
                                    ),
                                  );
                                } else {
                                  _showSnack("Login FAILED", color: Colors.red);
                                }
                              } catch (e) {
                                _showSnack(
                                  "Error: $e",
                                  color: Colors.redAccent,
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => isLoading = false);
                                }
                              }
                            },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don’t have an account? "),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/signup'),
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Text("Or continue with"),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () async {
                        _showSnack(
                          "Signing in with Google...",
                          color: Colors.orange,
                        );

                        try {
                          await authService.signInWithGoogle();

                          final user = FirebaseAuth.instance.currentUser;

                          if (user != null && mounted) {
                            _showSnack(
                              "Google Login Success",
                              color: Colors.green,
                            );

                            await Future.delayed(
                              const Duration(milliseconds: 800),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MainScreen(),
                              ),
                            );
                          }
                        } catch (e) {
                          _showSnack(
                            "Google Login Failed: $e",
                            color: Colors.red,
                          );
                        }
                      },
                      icon: const Icon(Icons.g_mobiledata, size: 32),
                      label: const Text("Google"),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _gradientButton({required String text, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: onTap == null
              ? const LinearGradient(colors: [Colors.grey, Colors.grey])
              : const LinearGradient(colors: [Colors.purple, Colors.blue]),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
