import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissan_connect/core/utils/color_utils.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';
import 'package:kissan_connect/features/auth/data/auth_repository.dart';
import 'package:kissan_connect/widgets/custom_elevetedbutton.dart';
import 'package:kissan_connect/widgets/custom_textformfield.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  int step = 0; // 0: Email, 1: OTP, 2: New Password

  String otp = "";
  bool loader = false;
  bool showPassword = false;

  int _timerSeconds = 60;
  bool _canResend = false;
  Timer? _timer;

  void _startTimer() {
    setState(() {
      _timerSeconds = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
        ),
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: foregroundColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Reset Password",
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Icon(
                          step == 0
                              ? Icons.email_outlined
                              : step == 1
                              ? Icons.lock_clock_outlined
                              : Icons.lock_reset_rounded,
                          size: 80,
                          color: primaryColor,
                        ),
                        const SizedBox(height: 30),
                        Text(
                          step == 0
                              ? "Forgot Password?"
                              : step == 1
                              ? "Enter OTP"
                              : "New Password",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: foregroundColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          step == 0
                              ? "Don't worry! Enter your email below to receive a reset code."
                              : step == 1
                              ? "Enter the 6-digit code sent to ${_emailController.text.trim()}"
                              : "Almost there! Create a strong new password for your account.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: greyColor, fontSize: 15),
                        ),
                        const SizedBox(height: 40),

                        if (step == 0) ...[
                          _buildLabel("EMAIL ADDRESS"),
                          const SizedBox(height: 8),
                          CustomTextformfield(
                            controller: _emailController,
                            hintText: "Enter email",
                            prefixIcon: const Icon(Icons.mail_outline),
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) => val != null && val.contains("@") ? null : "Enter valid email",
                          ),
                        ] else if (step == 1) ...[
                          _buildLabel("VERIFICATION CODE"),
                          const SizedBox(height: 8),
                          TextFormField(
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: foregroundColor,
                            ),
                            decoration: InputDecoration(
                              hintText: "000000",
                              hintStyle: const TextStyle(color: Colors.black26),
                              counterText: "",
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Colors.black12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: primaryColor),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (val) => otp = val.trim(),
                            validator: (val) => val != null && val.length == 6
                                ? null
                                : "Enter 6-digits",
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _canResend ? "Didn't receive code? " : "Resend code in ",
                                style: const TextStyle(color: greyColor),
                              ),
                              if (_canResend)
                                GestureDetector(
                                  onTap: () async {
                                    _startTimer();
                                    try {
                                      await ref.read(authRepositoryProvider).forgotPassword(_emailController.text.trim());
                                    } catch (e) {
                                      if (mounted) _showErrorDialog(context, e.toString());
                                    }
                                  },
                                  child: const Text(
                                    "Resend",
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  "${_timerSeconds}s",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: foregroundColor),
                                ),
                            ],
                          ),
                        ] else if (step == 2) ...[
                          _buildLabel("NEW PASSWORD"),
                          const SizedBox(height: 8),
                          CustomTextformfield(
                            controller: _newPasswordController,
                            obscureText: !showPassword,
                            hintText: "New password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword ? Icons.visibility : Icons.visibility_off,
                                color: greyColor,
                              ),
                              onPressed: () =>
                                  setState(() => showPassword = !showPassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Please enter a new password";
                              if (value.length < 8) return "Password must be at least 8 characters";
                              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                return "Password must contain at least one uppercase letter";
                              }
                              if (!RegExp(r'[a-z]').hasMatch(value)) {
                                return "Password must contain at least one lowercase letter";
                              }
                              if (!RegExp(r'[0-9]').hasMatch(value)) {
                                return "Password must contain at least one digit";
                              }
                              if (!RegExp(r'[!@#$&*~%_+-]').hasMatch(value)) {
                                return "Password must contain at least one special character";
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 40),

                        CustomElevatedbutton(
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            if (_formKey.currentState!.validate()) {
                              setState(() => loader = true);
                              final email = _emailController.text.trim();
                              final newPassword = _newPasswordController.text;
                              try {
                                if (step == 0) {
                                  await ref.read(authRepositoryProvider).forgotPassword(email);
                                  if (mounted) {
                                    setState(() => step = 1);
                                    _startTimer();
                                  }
                                } else if (step == 1) {
                                  await ref.read(authRepositoryProvider).verifyResetOtp(email, otp);
                                  if (mounted) {
                                    setState(() => step = 2);
                                  }
                                } else {
                                  await ref.read(authRepositoryProvider).resetPassword(email, otp, newPassword);
                                  if (mounted) {
                                    _showSuccessDialog(
                                      context,
                                      "Your password has been reset successfully.",
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  _showErrorDialog(context, e.toString());
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => loader = false);
                                }
                              }
                            }
                          },
                          child: loader
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  step == 0
                                      ? "Send Code"
                                      : step == 1
                                      ? "Verify Code"
                                      : "Reset Password",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 30),
                        if (step == 1)
                          TextButton(
                            onPressed: () {
                              setState(() => step = 0);
                              _timer?.cancel();
                            },
                            child: const Text(
                              "Entered wrong email? Change it",
                              style: TextStyle(color: greyColor),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: greyColor,
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Action failed", style: TextStyle(color: foregroundColor, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: greyColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Try Again", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.green.withOpacity(0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 10),
            Text("Success", style: TextStyle(color: foregroundColor, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: greyColor)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: whiteColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context); // pop dialog
              RouteGenerator.navigateToPageWithoutStack(
                context,
                "/login",
              );
            },
            child: const Text(
              "Log In Now",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
