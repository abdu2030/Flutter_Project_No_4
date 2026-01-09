import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:eduvox/shared/theme/app_theme.dart';
import 'package:eduvox/core/services/chapa_service.dart';

enum PaymentStatus { success, failed, cancelled, pending }

class ChapaPaymentResult {
  final PaymentStatus status;
  final String? txRef;
  final String? message;

  ChapaPaymentResult({required this.status, this.txRef, this.message});
}

class ChapaPaymentScreen extends StatefulWidget {
  final String checkoutUrl;
  final String txRef;
  final String courseTitle;

  const ChapaPaymentScreen({
    super.key,
    required this.checkoutUrl,
    required this.txRef,
    required this.courseTitle,
  });

  @override
  State<ChapaPaymentScreen> createState() => _ChapaPaymentScreenState();
}

class _ChapaPaymentScreenState extends State<ChapaPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _checkPaymentStatus(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            return _handleNavigation(request.url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  NavigationDecision _handleNavigation(String url) {
    // Check for success or callback URLs
    if (url.contains('success') ||
        url.contains('callback') ||
        url.contains('trx_ref=')) {
      _verifyAndComplete();
      return NavigationDecision.prevent;
    }

    // Check for cancel/failure URLs
    if (url.contains('cancel') || url.contains('fail')) {
      _handleCancel();
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  void _checkPaymentStatus(String url) {
    if (url.contains('success') || url.contains('trx_ref=')) {
      _verifyAndComplete();
    }
  }

  Future<void> _verifyAndComplete() async {
    if (_isVerifying) return;

    setState(() => _isVerifying = true);

    try {
      final verification = await ChapaService.verifyPayment(widget.txRef);

      if (mounted) {
        if (verification.isSuccessful) {
          Navigator.pop(
            context,
            ChapaPaymentResult(
              status: PaymentStatus.success,
              txRef: widget.txRef,
              message: 'Payment successful!',
            ),
          );
        } else {
          Navigator.pop(
            context,
            ChapaPaymentResult(
              status: PaymentStatus.failed,
              txRef: widget.txRef,
              message: verification.message,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(
          context,
          ChapaPaymentResult(
            status: PaymentStatus.failed,
            message: 'Verification error: $e',
          ),
        );
      }
    }
  }

  void _handleCancel() {
    Navigator.pop(
      context,
      ChapaPaymentResult(
        status: PaymentStatus.cancelled,
        message: 'Payment was cancelled',
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _handleCancel();
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
            onPressed: () => _onWillPop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Payment',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.courseTitle,
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppTheme.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Secure',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),

            // Loading indicator
            if (_isLoading)
              Container(
                color: isDark
                    ? AppTheme.darkBackground.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.8),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryColor),
                      SizedBox(height: 16),
                      Text('Loading payment page...'),
                    ],
                  ),
                ),
              ),

            // Verifying overlay
            if (_isVerifying)
              Container(
                color: isDark
                    ? AppTheme.darkBackground.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Verifying Payment...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while we confirm your payment',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : AppTheme.textSecondary,
                        ),
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
