import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../navigation/seller_navigator.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP Code!'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF6B35);
    const darkInk = Color(0xFF1E1E2C);
    const lightBg = Color(0xFFF9FAFC);
    const textMuted = Color(0xFF7D8491);

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))]),
                child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkInk, size: 18), onPressed: () => Navigator.pop(context)),
              ),
              const SizedBox(height: 32),
              const Text('Verification', style: TextStyle(color: darkInk, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
              const SizedBox(height: 8),
              Text('Enter OTP sent to ${widget.phoneNumber}', style: const TextStyle(color: textMuted, fontSize: 15)),
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
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: darkInk),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
