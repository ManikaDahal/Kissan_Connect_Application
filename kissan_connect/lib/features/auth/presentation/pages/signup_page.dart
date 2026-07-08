import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissan_connect/core/utils/color_utils.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';
import 'package:kissan_connect/core/utils/string_utils.dart';
import 'package:kissan_connect/features/auth/data/auth_repository.dart';
import 'package:kissan_connect/widgets/custom_elevetedbutton.dart';
import 'package:kissan_connect/widgets/custom_text.dart';
import 'package:kissan_connect/widgets/custom_textformfield.dart';
import 'package:kissan_connect/core/providers/nav_provider.dart';
import 'package:kissan_connect/core/providers/cart_provider.dart';
import '../widgets/social_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isAgreedToTerms = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: foregroundColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                CustomText(
                  data: createAccountStr,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: foregroundColor,
                ),
                const SizedBox(height: 8),
                CustomText(
                  data: "Join the KissanConnect community today",
                  fontSize: 16,
                  color: greyColor,
                ),
                const SizedBox(height: 40),
                CustomTextformfield(
                  controller: _nameController,
                  hintText: nameStr,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return validateNameStr;
                    if (value.trim().length < 2) return "Name must be at least 2 characters";
                    if (!RegExp(r"^[a-zA-Z\s'\-]+$").hasMatch(value.trim())) {
                      return "Name can only contain letters, spaces, hyphens or apostrophes";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextformfield(
                  controller: _emailController,
                  hintText: emailAddressStr,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return validateEmailAddressStr;
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return "Please enter a valid email (e.g. name@example.com)";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextformfield(
                  controller: _passwordController,
                  hintText: passwordStr,
                  obscureText: !_isPasswordVisible,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: primaryColor,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return validatePasswordStr;
                    if (value.length < 6) return "Password must be at least 6 characters";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _isAgreedToTerms,
                        activeColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (value) => setState(() => _isAgreedToTerms = value ?? false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomText(
                        data: agreeTermsAndConditionStr,
                        fontSize: 14,
                        color: greyColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                CustomElevatedbutton(
                  onPressed: _isLoading ? () {} : () async {
                    // Force keyboard down instantly on submit click
                    FocusManager.instance.primaryFocus?.unfocus();
                    
                    if (_formKey.currentState!.validate() && _isAgreedToTerms) {
                      setState(() => _isLoading = true);
                      try {
                        await ref.read(authRepositoryProvider).signup(
                              _nameController.text.trim(),
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                        // Sync cart in the background; do not block/await navigation
                        ref.read(cartProvider.notifier).syncCartOnLogin();
                        ref.read(navProvider.notifier).state = 0;
                        if (mounted) {
                          RouteGenerator.navigateToPageWithoutStack(
                              context, "/bottomNavbar");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Account created successfully! Welcome to KissanConnect."),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    } else if (!_isAgreedToTerms) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(notagreedToTermsAndConditionStr)),
                      );
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          SignupStr,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: Divider(color: greyColor.withOpacity(0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CustomText(data: "Or", color: greyColor),
                    ),
                    Expanded(child: Divider(color: greyColor.withOpacity(0.3))),
                  ],
                ),
                const SizedBox(height: 30),
                SocialButton(
                  iconPath: "assets/images/google_logo.png",
                  label: "Signup with Google",
                  isLoading: _isGoogleLoading,
                  onPressed: (_isLoading || _isGoogleLoading) ? () {} : () async {
                    setState(() => _isGoogleLoading = true);
                    try {
                      final GoogleSignIn googleSignIn = GoogleSignIn(
                        serverClientId: '788697519956-v4sldco3nb8q4jqcqnl4gdmqu98i6qo7.apps.googleusercontent.com',
                      );
                      await googleSignIn.signOut();
                      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
                      if (googleUser != null) {
                        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                        final String? idToken = googleAuth.idToken;
                        
                        if (idToken != null) {
                          await ref.read(authRepositoryProvider).googleLogin(idToken);
                          await ref.read(cartProvider.notifier).syncCartOnLogin();
                          ref.read(navProvider.notifier).state = 0;
                          if (mounted) {
                            RouteGenerator.navigateToPageWithoutStack(context, "/bottomNavbar");
                          }
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Google Sign-In failed: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isGoogleLoading = false);
                      }
                    }
                  },
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(data: alreadyHaveanAccountStr),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: CustomText(
                        data: loginStr,
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

