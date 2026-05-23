import 'dart:convert';
import 'package:http/http.dart' as http;

class ChapaService {
  static const String _baseUrl = 'https://api.chapa.co/v1';

  // ⚠️ Replace with YOUR test secret key
  static const String _secretKey =
      'CHASECK_TEST-Y7f24ClcIacsHi4ac8zUbzvryU0ftxdu';

  /// Initialize a payment transaction
  static Future<ChapaPaymentResponse> initializePayment({
    required String amount,
    required String email,
    required String firstName,
    required String lastName,
    required String txRef,
    required String courseId,
    required String courseTitle,
    String currency = 'ETB',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'tx_ref': txRef,
          'callback_url': 'https://eduvox.com/callback',
          'return_url': 'https://eduvox.com/success',
          'customization': {
            'title': 'EduVox Payment',
            'description': 'Payment for $courseTitle',
          },
          'meta': {'course_id': courseId},
        }),
      );

      // Decode the response
      final data = jsonDecode(response.body);

      // ✅ FIX IS HERE: We check if status exists and equals 'success'
      if (response.statusCode == 200 && data['status'] == 'success') {
        return ChapaPaymentResponse(
          success: true,
          // Safely access nested data
          checkoutUrl: data['data'] != null
              ? data['data']['checkout_url']
              : null,
          txRef: txRef,
          // Safely convert message to string to prevent the "Map is not String" error
          message: data['message']?.toString() ?? 'Success',
        );
      } else {
        // ✅ AND HERE: Safely handle error messages that might be Objects/Maps
        String errorMsg = 'Payment initialization failed';

        if (data['message'] != null) {
          errorMsg = data['message'].toString();
        }
        // Sometimes Chapa puts errors in 'data' instead of 'message'
        else if (data['data'] != null) {
          errorMsg = data['data'].toString();
        }

        return ChapaPaymentResponse(success: false, message: errorMsg);
      }
    } catch (e) {
      return ChapaPaymentResponse(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Verify a payment transaction
  static Future<ChapaVerificationResponse> verifyPayment(String txRef) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transaction/verify/$txRef'),
        headers: {'Authorization': 'Bearer $_secretKey'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return ChapaVerificationResponse(
          success: true,
          status: data['data'] != null ? data['data']['status'] : 'unknown',
          amount: data['data'] != null
              ? data['data']['amount']?.toString()
              : '0',
          txRef: txRef,
          message: 'Payment verified successfully',
        );
      } else {
        return ChapaVerificationResponse(
          success: false,
          status: 'failed',
          // ✅ FIX: Safely convert message
          message: data['message']?.toString() ?? 'Verification failed',
        );
      }
    } catch (e) {
      return ChapaVerificationResponse(
        success: false,
        status: 'error',
        message: 'Error: ${e.toString()}',
      );
    }
  }
}

class ChapaPaymentResponse {
  final bool success;
  final String? checkoutUrl;
  final String? txRef;
  final String message;

  ChapaPaymentResponse({
    required this.success,
    this.checkoutUrl,
    this.txRef,
    required this.message,
  });
}

class ChapaVerificationResponse {
  final bool success;
  final String status;
  final String? amount;
  final String? txRef;
  final String message;

  ChapaVerificationResponse({
    required this.success,
    required this.status,
    this.amount,
    this.txRef,
    required this.message,
  });

  bool get isSuccessful => status == 'success';
}
