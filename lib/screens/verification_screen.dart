import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../navigation/seller_navigator.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String expectedOtp;

  const VerificationScreen({super.key, required this.phoneNumber, required this.expectedOtp});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    final enteredOtp = _controllers.map((c) => c.text).join();
    if (enteredOtp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter all 4 digits'), behavior: SnackBarBehavior.floating));
      return;
    }
    if (enteredOtp != widget.expectedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP Code!'), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await LocalStorageService.saveUserPhone(widget.phoneNumber);
      final authService = AuthService();
      if (widget.expectedOtp != '1234') {
        await authService.loginWithPhone(widget.phoneNumber, widget.expectedOtp);
      }

      final bool exists = await authService.checkUserExists(widget.phoneNumber);

      if (exists) {
        final profile = await authService.getUserProfile(widget.phoneNumber);
        if (profile != null) {
          await LocalStorageService.setProfileComplete(
            userId: profile['id']?.toString() ?? '',
            name: profile['name']?.toString() ?? 'Seller',
            phone: widget.phoneNumber,
          );
        }
      }

      if (mounted) {
        if (exists) {
          SellerNavigator.home(context, clearStack: true);
        } else {
          SellerNavigator.shopSetup(context, clearStack: true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                decoration: BoxDecoration(
                  color: context.cardBg,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 18), onPressed: () => Navigator.pop(context)),
              ),
              const SizedBox(height: 32),
              Text('Verification', style: TextStyle(color: context.textPrimary, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
              const SizedBox(height: 8),
              Text('Enter OTP sent to ${widget.phoneNumber}', style: TextStyle(color: context.textMuted, fontSize: 15)),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    width: 58,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: context.textPrimary),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: context.inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(color: AppColors.orange, width: 2.0),
                        ),
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 3) _focusNodes[i + 1].requestFocus();
                        if (v.isNotEmpty && i == 3) _verifyOTP();
                      },
                    ),
                  ),
                ))),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)) : const Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
