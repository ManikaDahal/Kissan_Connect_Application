import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissan_connect/core/utils/color_utils.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';
import 'package:kissan_connect/core/utils/string_utils.dart';
import 'package:kissan_connect/features/auth/data/auth_repository.dart';
import 'package:kissan_connect/widgets/custom_elevetedbutton.dart';
import 'package:kissan_connect/widgets/custom_text.dart';
import 'package:kissan_connect/widgets/custom_textformfield.dart';
import '../widgets/social_button.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
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
                          color: whiteColor.withOpacity(0.8),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          RouteGenerator.navigateToPage(context, "/forgotPassword");
                        },
                        child: CustomText(
                          data: forgotPasswordStr,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomElevatedbutton(
                      onPressed: _isLoading ? () {} : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          try {
                            await ref.read(authRepositoryProvider).login(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                );
                            if (mounted) {
                              RouteGenerator.navigateToPageWithoutStack(
                                  context, "/bottomNavbar");
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
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      onPressed: () {
                        // TODO: Implement Google Sign-In
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
    );
  }
}
