import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Utils/shared_prefs_util.dart';

class ExpenseApi {
  static const String _baseUrl = "https://erpsmart.in/total/api/m_api/";

  static Future<Map<String, dynamic>> fetchExpenseRequests() async {
    try {
      final String cid = await SharedPrefsUtil.getCid();
      final String lt = await SharedPrefsUtil.getLat();
      final String ln = await SharedPrefsUtil.getLng();
      final String deviceId = await SharedPrefsUtil.getDeviceId();
      final String uid = await SharedPrefsUtil.getUid();

      final Map<String, String> body = {
        'type': '2083',
        'cid': cid,
        'uid': uid,
        'id': uid,
        'lt': lt,
        'ln': ln,
        'device_id': deviceId,
        'form': 'sm_main_form_16521', 
        'select': '*',
      };

      print("Expense Request body: $body");

      final response = await http.post(
        Uri.parse(_baseUrl),
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": true, "message": "Failed to load expenses: ${response.statusCode}"};
      }
    } catch (e) {
      print("Error fetching expense requests: $e");
      return {"error": true, "message": e.toString()};
    }
  }

  // Placeholder for update status API if needed
  static Future<Map<String, dynamic>> updateExpenseStatus({
    required String expenseId,
    required String status,
    String? amount,
    String? reason,
  }) async {
    try {
      final String cid = await SharedPrefsUtil.getCid();
      final String lt = await SharedPrefsUtil.getLat();
      final String ln = await SharedPrefsUtil.getLng();
      final String deviceId = await SharedPrefsUtil.getDeviceId();
      final String adminUid = await SharedPrefsUtil.getUid();

      // Note: type 2084 is a guess based on pattern (2083 is fetch, 2084 might be update)
      // Change to the correct type provided by the backend later if needed
      final Map<String, String> body = {
        'type': '2084',
        'cid': cid,
        'lt': lt,
        'ln': ln,
        'device_id': deviceId,
        'form': 'sm_main_form_16521',
        'id': expenseId,
        'admin_uid': adminUid,
        'status': status,
        if (amount != null) 'approved_amount': amount,
        if (reason != null) 'reject_reason': reason,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        body: body,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": true, "message": e.toString()};
    }
  }
}
