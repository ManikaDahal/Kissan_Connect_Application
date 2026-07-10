import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissan_connect/core/utils/color_utils.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';
import 'package:kissan_connect/core/utils/string_utils.dart';
import 'package:kissan_connect/features/auth/data/auth_repository.dart';
import 'package:kissan_connect/widgets/custom_elevetedbutton.dart';
import 'package:kissan_connect/widgets/custom_text.dart';
import 'package:kissan_connect/widgets/custom_textformfield.dart';
import 'package:kissan_connect/core/providers/nav_provider.dart';
import 'package:kissan_connect/core/providers/cart_provider.dart';
import 'package:kissan_connect/core/utils/error_helper.dart';
import '../widgets/social_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedEmail = prefs.getString('remembered_email');
    if (rememberedEmail != null && rememberedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = rememberedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_email', _emailController.text.trim());
    } else {
      await prefs.remove('remembered_email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: backgroundColor,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  "assets/images/splashScreen.png",
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 24),
                              CustomText(
                                data: welcomeBackStr,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: whiteColor,
                              ),
                              const SizedBox(height: 8),
                              CustomText(
                                data: "Sign in to continue your journey",
                                fontSize: 16,
                                color: whiteColor.withOpacity(0.9),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          CustomTextformfield(
                            controller: _emailController,
                            hintText: emailAddressStr,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: (value) {
                              if (value == null || value.isEmpty) return validateEmailAddressStr;
                              if (!value.contains('@')) return "Please enter a valid email";
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
                              return null;
                            },
                          ),
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: primaryColor,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text("Remember Me"),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  RouteGenerator.navigateToPage(context, "/forgotPassword");
                                },
                                child: CustomText(
                                  data: forgotPasswordStr,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          CustomElevatedbutton(
                            onPressed: _isLoading ? () {} : () async {
                              // Force keyboard down instantly on submit click
                              FocusManager.instance.primaryFocus?.unfocus();
                              
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                try {
                                  await ref.read(authRepositoryProvider).login(
                                        _emailController.text.trim(),
                                        _passwordController.text.trim(),
                                      );
                                  await _saveRememberMe();
                                  // Sync local cart to backend in the background; do not block/await navigation
                                  ref.read(cartProvider.notifier).syncCartOnLogin();
                                  ref.read(navProvider.notifier).state = 0;
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Login successfully!"),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    RouteGenerator.navigateToPageWithoutStack(
                                        context, "/bottomNavbar");
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ErrorHelper.showSnackBarError(context, e);
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              }
                            },
                            child: _isLoading 
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    loginStr,
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
                            label: "Sign in with Google",
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
                                  ErrorHelper.showSnackBarError(context, e);
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
                              CustomText(data: dontHAveanAccountStr),
                              TextButton(
                                onPressed: () {
                                  RouteGenerator.navigateToPage(context, "/signup");
                                },
                                child: CustomText(
                                  data: SignupStr,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Blur overlay — shown while any loading is active
          if (_isLoading || _isGoogleLoading)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withOpacity(0.35),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
