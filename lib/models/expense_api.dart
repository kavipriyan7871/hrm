import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ExpenseRepo {
  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  // Add Expense API
  static Future<Map<String, dynamic>> addExpense({
    required String cid,
    required String uid,
    required String amount,
    required String description,
    required String expenseDate,
    required String deviceId,
    required String lat,
    required String lng,
    required String purpose,
    File? receiptImage,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));

      request.fields.addAll({
        "cid": cid,
        "uid": uid,
        "amount": amount,
        "description":
            description, // Note: purpose is usually mapped to description or separate field. User said description. I'll append purpose? Or just description.
        // Screen has "Category" (Purpose) and "Description".
        // API param list has "description".
        // I will adhere to the user provided params: "amount:1500, description:Client meeting..., expense_date:..., type:2059..."
        // I'll assume purpose goes into description or is ignored? The UI has both.
        // I'll concatenate: "$purpose - $description" into description field for now to be safe, or just send description.
        // Let's send description as is.
        "type": "2059",
        "expense_date": expenseDate,
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
        "purpose":
            purpose, // Adding strictly in case backend accepts it, otherwise rely on description.
      });

      if (receiptImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('receipt', receiptImage.path),
        );
      }

      print("Add Expense Request Fields: ${request.fields}");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Add Expense Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": true,
          "error_msg": "Server returned status code ${response.statusCode}",
        };
      }
    } catch (e) {
      print("Add Expense API Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }

  // View Expense API
  static Future<Map<String, dynamic>> getExpenses({
    required String cid,
    required String uid,
    required String month,
    required String year,
    required String deviceId,
    required String lat,
    required String lng,
  }) async {
    try {
      final body = {
        "cid": cid,
        "uid": uid,
        "month": month,
        "year": year,
        "type": "2060", // Assumed View Expense Type
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
      };

      print("Get Expenses Request Body: $body");

      final response = await http.post(Uri.parse(baseUrl), body: body);

      print("Get Expenses Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": true,
          "error_msg": "Server returned status code ${response.statusCode}",
        };
      }
    } catch (e) {
      print("Get Expenses API Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }
}
