// ignore_for_file: camel_case_types

/// Represents the result of an error response.
class NwcResponse {
  /// The error code.
  String? errorCode;

  /// The error message.
  String? errorMessage;

  /// The type of the result.
  final String resultType;

  NwcResponse({
    required this.resultType,
  });

  void deserializeError(Map<String, dynamic> input) {
    if (input.containsKey('error') && input['error'] != null) {
      Map<String, dynamic> error = input['error'] as Map<String, dynamic>;
      errorCode = error["code"];
      errorMessage = error["message"];
    }
  }
}
