import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/models/expense_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';

import 'add_expense.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _expenses = [];
  String _error = "";

  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'Total';

  bool _isDateFilterActive = false;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF26A69A), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF26A69A), // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Check if the month/year changed to decide if we need to refetch
      bool needsFetch =
          picked.month != _selectedDate.month ||
          picked.year != _selectedDate.year;

      setState(() {
        _selectedDate = picked;
        _isDateFilterActive = true; // Activate date filter strictly
      });

      if (needsFetch) {
        _fetchExpenses();
      }
    }
  }

  Future<Position?> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Future<void> _fetchExpenses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = "";
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid =
          prefs.getString('employee_table_id') ??
          prefs.getInt('uid')?.toString() ??
          "";
      final cid = prefs.getString('cid') ?? "21472147";

      String? deviceId = prefs.getString('device_id');
      if (deviceId == null) {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor;
        } else {
          deviceId = "unknown_device";
        }
      }

      final position = await _determinePosition();
      final lat = position?.latitude.toString() ?? "0.0";
      final lng = position?.longitude.toString() ?? "0.0";

      final response = await ExpenseRepo.getExpenses(
        cid: cid,
        uid: uid,
        month: _selectedDate.month.toString().padLeft(2, '0'),
        year: _selectedDate.year.toString(),
        deviceId: deviceId!,
        lat: lat,
        lng: lng,
      );

      print("Get Expenses UI Response: $response");

      if (!mounted) return;

      if (response["success"] == true || response["error"] == false) {
        final data = response["data"];

        List<dynamic> expenseList = [];

        if (data is Map) {
          if (data["expenses"] is List) {
            expenseList = data["expenses"];
          } else if (data["expense_list"] is List) {
            expenseList = data["expense_list"];
          }
        } else if (data is List) {
          expenseList = data;
        }

        setState(() {
          _expenses = expenseList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              response["message"] ??
              response["error_msg"] ??
              "Failed to fetch expenses";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    // 1. Filter by Date if Active
    List<dynamic> dateFilteredList = _expenses;
    if (_isDateFilterActive) {
      String targetDate =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      dateFilteredList = _expenses.where((item) {
        String itemDate = item["expense_date"] ?? "";
        return itemDate == targetDate;
      }).toList();
    }

    // 2. Calculate Summary based on Date Filtered List
    double total = 0;
    double approved = 0;
    double pending = 0;

    for (var item in dateFilteredList) {
      String amountStr = item["amount"]?.toString() ?? "0";
      double amt = double.tryParse(amountStr.replaceAll(",", "")) ?? 0;
      total += amt;

      String status = item["status"]?.toString().toLowerCase() ?? "0";
      if (status == "1" || status.contains("approv")) {
        approved += amt;
      } else if (status == "0" || status.contains("pend")) {
        pending += amt;
      }
    }

    final currentSummary = {
      "total": total,
      "approved": approved,
      "pending": pending,
    };

    // 3. Filter by Status Tab
    List<dynamic> finalDisplayList = dateFilteredList.where((item) {
      if (_selectedFilter == 'Total') return true;
      String statusRaw = item["status"]?.toString().toLowerCase() ?? "0";
      if (_selectedFilter == 'Approved') {
        return statusRaw == "1" || statusRaw.contains("approv");
      }
      if (_selectedFilter == 'Pending') {
        return statusRaw == "0" || statusRaw.contains("pend");
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => _selectDate(context),
            icon: const Icon(Icons.calendar_month),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Center(
                  child: Text(
                    _isDateFilterActive
                        ? "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}"
                        : "${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_isDateFilterActive)
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isDateFilterActive = false;
                      });
                    },
                    tooltip: "Clear Date Filter",
                  ),
              ],
            ),
          ),
        ],
        title: Text(
          "Expense Management",
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 22 : 19,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 50,
        width: 160,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddExpense()),
            );
            if (result == true) {
              _fetchExpenses();
            }
          },
          label: Text(
            "Add Expense",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          icon: const Icon(Icons.add, color: Colors.white, size: 22),
          backgroundColor: const Color(0xFF26A69A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchExpenses,
        color: const Color(0xFF26A69A),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF26A69A)),
              )
            : _error.isNotEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 100,
                  child: Center(child: Text(_error)),
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    if (_isDateFilterActive)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Showing results for: ${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),

                    // ==================== SUMMARY CARDS ====================
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setState(() => _selectedFilter = 'Total'),
                            child: _buildSummaryCard(
                              "Total",
                              "₹ ${currentSummary['total']}",
                              const Color(0xFF3F51B5), // Blue
                              _selectedFilter == 'Total',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setState(() => _selectedFilter = 'Approved'),
                            child: _buildSummaryCard(
                              "Approved",
                              "₹ ${currentSummary['approved']}",
                              const Color(0xFF4CAF50), // Green
                              _selectedFilter == 'Approved',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setState(() => _selectedFilter = 'Pending'),
                            child: _buildSummaryCard(
                              "Pending",
                              "₹ ${currentSummary['pending']}",
                              const Color(0xFFFF9800), // Orange
                              _selectedFilter == 'Pending',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    if (finalDisplayList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Text(
                          "No expenses found for this category",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: finalDisplayList.length,
                        itemBuilder: (context, index) {
                          final item = finalDisplayList[index];
                          // Map properties
                          // Prioritize showing the specific purpose/category selected by user
                          String title =
                              item["expense_category"] ??
                              item["purpose"] ??
                              item["expense_type"] ??
                              item["description"] ??
                              "Miscellaneous";

                          if (title.trim().isEmpty ||
                              title.toLowerCase() == "expense") {
                            title = "Miscellaneous";
                          }

                          String amountStr = item['amount']?.toString() ?? "0";
                          // Remove commas if present
                          String val = amountStr.replaceAll(",", "");
                          String amount = "₹ $val";

                          String dateStr =
                              item["expense_date"]?.toString() ?? "";
                          String date = dateStr;
                          try {
                            if (dateStr.contains("-")) {
                              List<String> parts = dateStr.split("-");
                              if (parts.length == 3) {
                                // Check if YYYY-MM-DD
                                if (parts[0].length == 4) {
                                  date = "${parts[2]}-${parts[1]}-${parts[0]}";
                                }
                              }
                            }
                          } catch (_) {}
                          // Normalize status to lowercase
                          String statusRaw =
                              item["status"]?.toString().toLowerCase() ?? "0";

                          String statusText = "Pending";
                          Color statusColor = const Color(0xffF87000); // Orange
                          Color statusBgColor = const Color(
                            0xffFFE0B2,
                          ); // Light Orange

                          if (statusRaw == "1" ||
                              statusRaw.contains("approv")) {
                            statusText = "Approved";
                            statusColor = const Color(0xff05D817); // Green
                            statusBgColor = const Color(
                              0xffE8F5E9,
                            ); // Light Green
                          } else if (statusRaw == "2" ||
                              statusRaw.contains("reject")) {
                            statusText = "Rejected";
                            statusColor = Colors.red;
                            statusBgColor = const Color(
                              0xffFFEBEE,
                            ); // Light Red
                          }

                          IconData icon = Icons.receipt_long;
                          Color iconColor =
                              Colors.red; // Default to Red for Pending/Others

                          // Simple icon logic based on title (keep icon, change color based on status)
                          final lowerTitle = title.toLowerCase();
                          if (lowerTitle.contains("food") ||
                              lowerTitle.contains("lunch") ||
                              lowerTitle.contains("dinner")) {
                            icon = Icons.restaurant;
                          } else if (lowerTitle.contains("travel") ||
                              lowerTitle.contains("flight") ||
                              lowerTitle.contains("taxi")) {
                            icon = Icons.directions_car;
                          } else if (lowerTitle.contains("stationary") ||
                              lowerTitle.contains("office")) {
                            icon = Icons.work;
                          } else {
                            icon = Icons.currency_rupee;
                          }

                          // Override color based on status as per user request
                          // "rupees symbol background color aprovel la muttum light green la kami pending ellamea red color la kami"
                          if (statusText == "Approved") {
                            iconColor = const Color(0xFF4CAF50); // Green
                          } else {
                            iconColor = const Color(0xFFD32F2F); // Red
                          }

                          return Column(
                            children: [
                              _buildExpenseItem(
                                context: context,
                                icon: icon,
                                iconColor: iconColor,
                                title: title,
                                date: date,
                                amount: amount,
                                status: statusText,
                                statusColor: statusColor,
                                statusBgColor: statusBgColor,
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),

                    const SizedBox(height: 100),

                    const SizedBox(height: 80), // Space for FAB

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  // Summary Card
  Widget _buildSummaryCard(
    String title,
    String amount,
    Color activeColor,
    bool isSelected,
  ) {
    // If selected, use activeColor for border and text.
    // If not selected, use standard Dark Blue (0xFF1A237E) or Grey.

    final color = isSelected ? activeColor : const Color(0xFF1A237E);
    final bgColor = isSelected ? activeColor.withOpacity(0.05) : Colors.white;

    return Container(
      height: 100, // Fixed height for uniformity
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: isSelected ? 2 : 1),
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Individual Expense Item
  Widget _buildExpenseItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String date,
    required String amount,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: iconColor, // Solid color based on type
            child: Icon(icon, color: Colors.white, size: 30), // White icon
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                amount,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF283593), // Dark Blue amount color
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor, // Light background
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor, // Text color
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
