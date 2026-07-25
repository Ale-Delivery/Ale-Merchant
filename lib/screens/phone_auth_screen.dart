import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../navigation/seller_navigator.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    String phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty || phoneNumber.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid phone number'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+94$phoneNumber';
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final otp = await authService.sendDummyOTP(phoneNumber);

      if (mounted) {
        SellerNavigator.verification(context, phone: phoneNumber, otp: otp);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.store_rounded,
                    color: AppColors.orange, size: 28),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome Seller!',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: context.textPrimary,
                    letterSpacing: -0.8),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your restaurant and orders.',
                style: TextStyle(
                    fontSize: 15, color: context.textMuted, height: 1.5),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: '07X XXX XXXX',
                  hintStyle: TextStyle(color: context.textHint, fontSize: 15),
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    child: Text('+94',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 56),
                  filled: true,
                  fillColor: context.inputBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide(color: AppColors.orange, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor:
                        AppColors.orange.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: AppColors.white, strokeWidth: 2),
                        )
                      : const Text('Send OTP',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
