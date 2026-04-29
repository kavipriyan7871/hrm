import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/models/expense_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

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
  Map<String, dynamic> _apiSummary = {};

  // Wallet State
  List<Map<String, dynamic>> _walletExpenses = [];
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? walletData = prefs.getString('personal_wallet_expenses');
    if (walletData != null) {
      setState(() {
        _walletExpenses = List<Map<String, dynamic>>.from(jsonDecode(walletData));
        _calculateWalletBalance();
      });
    }
  }

  void _calculateWalletBalance() {
    double total = 0;
    for (var item in _walletExpenses) {
      total += double.tryParse(item['amount'].toString()) ?? 0.0;
    }
    _walletBalance = total;
  }

  Future<void> _addWalletEntry(String title, double amount, String category) async {
    final entry = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "title": title,
      "amount": amount,
      "category": category,
      "date": DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    };

    setState(() {
      _walletExpenses.insert(0, entry);
      _calculateWalletBalance();
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('personal_wallet_expenses', jsonEncode(_walletExpenses));
  }

  Future<void> _deleteWalletEntry(String id) async {
    setState(() {
      _walletExpenses.removeWhere((item) => item['id'] == id);
      _calculateWalletBalance();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('personal_wallet_expenses', jsonEncode(_walletExpenses));
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
              primary: Color(0xFF26A69A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF26A69A),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      bool needsFetch =
          picked.month != _selectedDate.month ||
          picked.year != _selectedDate.year;

      setState(() {
        _selectedDate = picked;
        _isDateFilterActive = true;
      });

      if (needsFetch) {
        _fetchExpenses();
      }
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    DateTime tempDate = _selectedDate;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    onPressed: () => setStateDialog(
                      () => tempDate = DateTime(
                        tempDate.year - 1,
                        tempDate.month,
                      ),
                    ),
                  ),
                  Text(
                    "${tempDate.year}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    onPressed: () => setStateDialog(
                      () => tempDate = DateTime(
                        tempDate.year + 1,
                        tempDate.month,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                height: 250,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthIndex = index + 1;
                    final isSelected =
                        tempDate.year == _selectedDate.year &&
                        monthIndex == _selectedDate.month;
                    return InkWell(
                      onTap: () => Navigator.pop(
                        context,
                        DateTime(tempDate.year, monthIndex),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF26A69A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF26A69A)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          [
                            "Jan",
                            "Feb",
                            "Mar",
                            "Apr",
                            "May",
                            "Jun",
                            "Jul",
                            "Aug",
                            "Sep",
                            "Oct",
                            "Nov",
                            "Dec",
                          ][index],
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    ).then((picked) {
      if (picked != null && picked is DateTime) {
        if (picked.month != _selectedDate.month ||
            picked.year != _selectedDate.year) {
          setState(() {
            _selectedDate = picked;
            _expenses = []; // Clear current list
            _isLoading = true;
            _isDateFilterActive = false; // Reset to Month View
          });
          _fetchExpenses();
        }
      }
    });
  }

  Future<Position?> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      // Try last known first (instant)
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;

      // Fast current position (low accuracy, short timeout)
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 3),
      );
    } catch (e) {
      print("Location Fetch Error: $e");
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
      final String uid =
          prefs.getString('uid') ??
          prefs.getString('login_cus_id') ??
          prefs.getString('employee_table_id') ??
          "";
      final cid = (prefs.get('cid') ?? prefs.get('cid_str') ?? "").toString();

      final deviceId = prefs.getString('device_id') ?? "";

      final position = await _determinePosition();
      final lat = position?.latitude.toString() ?? "0.0";
      final lng = position?.longitude.toString() ?? "0.0";

      final response = await ExpenseRepo.getExpenses(
        cid: cid,
        uid: uid,
        month: _selectedDate.month.toString().padLeft(2, '0'),
        year: _selectedDate.year.toString(),
        deviceId: deviceId,
        lat: lat,
        lng: lng,
        token: prefs.getString('token'),
      );

      if (!mounted) return;

      if (response["success"] == true ||
          response["error"] == false ||
          response["error"] == "false") {
        final data = response["data"];

        List<dynamic> expenseList = [];

        if (data is Map) {
          expenseList = data["expenses"] ?? 
                        data["expense_list"] ?? 
                        data["list"] ?? 
                        data["data"] ?? 
                        [];
        } else if (data is List) {
          expenseList = data;
        } else {
          // Fallback to top-level keys
          expenseList = response["expenses"] ?? 
                        response["expense_list"] ?? 
                        response["list"] ?? 
                        response["data"] ?? 
                        [];
        }

        setState(() {
          _expenses = expenseList.where((item) {
            final String delFlag = item['del']?.toString() ?? "";
            final String isDFlag = item['is_d']?.toString() ?? "";
            return delFlag != "1" && isDFlag != "1";
          }).toList();
          
          _apiSummary = {};
          if (data is Map && data["summary"] != null) {
            _apiSummary = Map<String, dynamic>.from(data["summary"]);
          } else if (response["summary"] != null) {
            _apiSummary = Map<String, dynamic>.from(response["summary"]);
          }
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

    List<dynamic> dateFilteredList = _expenses;
    if (_isDateFilterActive) {
      String targetDate =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      dateFilteredList = _expenses.where((item) {
        String itemDate = item["expense_date"] ?? "";
        return itemDate == targetDate;
      }).toList();
    }

    double total = 0, approved = 0, pending = 0;
    for (var item in dateFilteredList) {
      double claimAmt = double.tryParse(item["amount"]?.toString().replaceAll(",", "") ?? "0") ?? 0;
      total += claimAmt;
      String status = item["status"]?.toString().toLowerCase() ?? "0";
      double apprAmt = double.tryParse((item['approved_amt'] ?? item['approved_amount'])?.toString().replaceAll(",", "") ?? "0") ?? 0;
      if ((status == "1" || status.contains("approv")) && apprAmt == 0) apprAmt = claimAmt;
      approved += apprAmt;
      if (status != "2" && !status.contains("reject")) pending += (claimAmt - apprAmt);
    }

    List<dynamic> finalDisplayList = dateFilteredList.where((item) {
      if (_selectedFilter == 'Total') return true;
      String statusRaw = item["status"]?.toString().toLowerCase() ?? "0";
      double claim = double.tryParse(item['amount']?.toString().replaceAll(",", "") ?? "0") ?? 0;
      double appr = double.tryParse((item['approved_amt'] ?? item['approved_amount'])?.toString().replaceAll(",", "") ?? "0") ?? 0;
      if ((statusRaw == "1" || statusRaw.contains("approv")) && appr == 0) appr = claim;
      if (_selectedFilter == 'Approved') return appr > 0;
      if (_selectedFilter == 'Pending') return statusRaw != "2" && !statusRaw.contains("reject") && appr < claim;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Expense Management",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchExpenses,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF26A69A)))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // Wallet Section pinned to top
                        InkWell(
                          onTap: _showAddWalletBottomSheet,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF26A69A), Color(0xFF00796B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF26A69A).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Personal Wallet (Click to Add)", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                                    const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 24),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "\u20B9 ${_walletBalance.toStringAsFixed(2)}",
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Company Summary Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Expense Summary", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                  InkWell(
                                    onTap: () => _selectMonth(context),
                                    child: Row(
                                      children: [
                                        Text(
                                          "${["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][_selectedDate.month - 1]} ${_selectedDate.year}",
                                          style: GoogleFonts.poppins(color: const Color(0xFF26A69A), fontWeight: FontWeight.bold),
                                        ),
                                        const Icon(Icons.arrow_drop_down, color: Color(0xFF26A69A)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: InkWell(onTap: () => setState(() => _selectedFilter = 'Total'), child: _buildSummaryCard("Total", "\u20B9 $total", const Color(0xFF3F51B5), _selectedFilter == 'Total'))),
                                  const SizedBox(width: 8),
                                  Expanded(child: InkWell(onTap: () => setState(() => _selectedFilter = 'Approved'), child: _buildSummaryCard("Approved", "\u20B9 $approved", const Color(0xFF4CAF50), _selectedFilter == 'Approved'))),
                                  const SizedBox(width: 8),
                                  Expanded(child: InkWell(onTap: () => setState(() => _selectedFilter = 'Pending'), child: _buildSummaryCard("Pending", "\u20B9 $pending", const Color(0xFFFF9800), _selectedFilter == 'Pending'))),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              // Recent Activities (Optional horizontal row or integrated)
                              if (_walletExpenses.isNotEmpty) ...[
                                Text("Recent Wallet Activity", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _walletExpenses.length > 5 ? 5 : _walletExpenses.length,
                                    itemBuilder: (context, index) {
                                      final item = _walletExpenses[index];
                                      return Container(
                                        width: 140,
                                        margin: const EdgeInsets.only(right: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(item['title'], style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                            Text("\u20B9 ${item['amount']}", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade400)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              Text("Company Expenses", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              finalDisplayList.isEmpty
                                  ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Text("No company expenses found", style: GoogleFonts.poppins(color: Colors.grey))))
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: finalDisplayList.length,
                                      itemBuilder: (context, index) {
                                        final item = finalDisplayList[index];
                                        String cat = (item["expense_category"] ?? item["purpose"] ?? "").toString().toLowerCase();
                                        IconData icon = Icons.receipt_long;
                                        if (cat.contains("food")) icon = Icons.restaurant;
                                        else if (cat.contains("travel")) icon = Icons.directions_car;
                                        else if (cat.contains("stationary")) icon = Icons.edit_note;

                                        String statusRaw = item["status"]?.toString().toLowerCase() ?? "pending";
                                        Color sColor = Colors.orange;
                                        if (statusRaw.contains("approv") || statusRaw == "1") sColor = Colors.green;
                                        else if (statusRaw.contains("reject") || statusRaw == "2") sColor = Colors.red;

                                        List<dynamic>? att;
                                        if (item["attachments"] is List) att = item["attachments"];
                                        else if (item["attachements"] is List) att = item["attachements"];

                                        return _buildExpenseItem(
                                          context: context,
                                          icon: icon,
                                          iconColor: sColor,
                                          title: item["expense_category"] ?? item["purpose"] ?? "Miscellaneous",
                                          date: item["expense_date"] ?? "No Date",
                                          claimAmount: "\u20B9 ${item['amount']}",
                                          approvedAmount: "\u20B9 ${item['approved_amt'] ?? item['approved_amount'] ?? '0'}",
                                          status: statusRaw.contains("approv") || statusRaw == "1" ? "Approved" : (statusRaw.contains("reject") || statusRaw == "2" ? "Rejected" : "Pending"),
                                          statusColor: sColor,
                                          statusBgColor: sColor.withOpacity(0.1),
                                          attachments: att,
                                        );
                                      },
                                    ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExpense()));
                if (result == true) _fetchExpenses();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Expense", style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF26A69A),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF26A69A), Color(0xFF00796B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF26A69A).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Personal Wallet", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                        const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 24),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "\u20B9 ${_walletBalance.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.white54, size: 16),
                        const SizedBox(width: 4),
                        Text("Current Balance Total", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent Activity", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text("See All")),
                ],
              ),
              const SizedBox(height: 10),
              if (_walletExpenses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("No wallet entries yet", style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _walletExpenses.length,
                  itemBuilder: (context, index) {
                    final item = _walletExpenses[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF26A69A).withOpacity(0.1),
                          child: const Icon(Icons.wallet, color: Color(0xFF26A69A)),
                        ),
                        title: Text(item['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Text(item['date'] ?? "", style: GoogleFonts.poppins(fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "\u20B9 ${item['amount']}",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red.shade400),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                              onPressed: () => _deleteWalletEntry(item['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddWalletBottomSheet(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add to Wallet", style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF26A69A),
            elevation: 4,
          ),
        ),
      ],
    );
  }

  void _showAddWalletBottomSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add Wallet Expense", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Title / Description",
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount (\u20B9)",
                labelStyle: GoogleFonts.poppins(),
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    _addWalletEntry(titleController.text, double.tryParse(amountController.text) ?? 0, "Personal");
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26A69A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Save to Wallet", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color activeColor, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
        boxShadow: isSelected ? [BoxShadow(color: activeColor.withOpacity(0.1), blurRadius: 10)] : [],
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: isSelected ? activeColor : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(height: 4),
          FittedBox(child: Text(amount, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? activeColor : Colors.black))),
        ],
      ),
    );
  }

  Widget _buildExpenseItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String date,
    required String claimAmount,
    required String approvedAmount,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    List<dynamic>? attachments,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1B2C61))),
                    Text(date, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(claimAmount, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1B2C61))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(status, style: GoogleFonts.poppins(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
          if (status == "Approved" && approvedAmount != claimAmount) ...[
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Approved Amount:", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                Text(approvedAmount, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
          if (attachments != null && attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: InteractiveViewer(child: Image.network(attachments!.first.toString(), errorBuilder: (_, __, ___) => Container(color: Colors.white, padding: const EdgeInsets.all(20), child: const Text("Image not available")))),
                  ),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.attachment, size: 14, color: Color(0xFF26A69A)),
                  const SizedBox(width: 4),
                  Text("View Receipt", style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF26A69A), decoration: TextDecoration.underline)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
