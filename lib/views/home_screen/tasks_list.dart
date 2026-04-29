import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  Timer? _timer;
  bool _isLoading = true;
  List<Map<String, dynamic>> tasks = [];
  bool _isFirstLoad = true;

  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isFirstLoad) {
      _fetchTasks();
    }
    _isFirstLoad = false;
  }

  Future<void> _fetchTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cid = prefs.getString('cid') ?? prefs.getString('cid_str') ?? "21472147";
      final String uid =
          prefs.getString('login_cus_id') ??
          prefs.getString('employee_table_id') ??
          prefs.getString('uid') ??
          "54";
      
      final body = {
        "type": "2075",
        "cid": cid,
        "uid": uid,
        "cus_id": uid,
        "id": uid,
      };

      debugPrint("Fetching tasks (Type 2075) body: $body");

      final response = await ApiClient().post(body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["error"] == false) {
          final summaryData = data["summary"];
          final tasksMap = data["data"] ?? {};
          
          List<dynamic> allTasks = [];
          if (tasksMap is Map) {
            allTasks.addAll(tasksMap["pending"] ?? []);
            allTasks.addAll(tasksMap["partial"] ?? []);
            allTasks.addAll(tasksMap["completed"] ?? []);
          }

          setState(() {
            _summary = summaryData;
            tasks = allTasks.map((t) {
              final String taskId = t["task_id"].toString();

              final String? localStatus = prefs.getString("task_status_$taskId");
              final int? localSeconds = prefs.getInt("task_seconds_$taskId");

              final String apiStatus = (t["status"] ?? "pending").toString().toLowerCase();
              final String currentStatus = (localStatus ?? apiStatus).toLowerCase();

              bool isDoneStatus = currentStatus == "done" || currentStatus == "completed" || currentStatus == "1";
              bool isPartial = currentStatus == "partial" || currentStatus == "2";
              bool isPendingStatus = !isDoneStatus;

              int apiSeconds = _parseTimeStringToSeconds(t["spending_time"] ?? "00:00:00");
              int finalSeconds = (localSeconds != null && localSeconds > apiSeconds) ? localSeconds : apiSeconds;

              return {
                "id": taskId,
                "title": t["task_name"] ?? "Untitled Task",
                "deadline": t["due_date"] ?? "N/A",
                "task_timing": t["task_timing"] ?? "00:00:00",
                "priority": t["priority"] ?? "N/A",
                "isPending": isPendingStatus,
                "elapsedSeconds": finalSeconds,
                "isRunning": false,
                "timeLimitSeconds": _parseTimeStringToSeconds(t["task_timing"] ?? "00:00:00"),
                "isPartiallyCompleted": isPartial,
                "partialReason": t["reason"] ?? t["remarks"] ?? "",
                "isPartialSubmitted": isPartial,
                "approvalStatus": t["approval_status"]?.toString(),
                "assignedBy": t["assigned_by"] ?? "N/A",
              };
            }).toList();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("API Error: $e");
      setState(() => _isLoading = false);
    }
  }

  int _parseTimeStringToSeconds(String timeString) {
    if (timeString.isEmpty || timeString == "null") return 0;
    try {
      List<String> parts = timeString.split(':');
      if (parts.length == 3) {
        int h = int.parse(parts[0]);
        int m = int.parse(parts[1]);
        int s = int.parse(parts[2]);
        return (h * 3600) + (m * 60) + s;
      }
    } catch (_) {}
    return 0;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        bool shouldSave = false;
        setState(() {
          for (var task in tasks) {
            if (task["isRunning"] == true) {
              task["elapsedSeconds"] = (task["elapsedSeconds"] ?? 0) + 1;
              if (task["elapsedSeconds"] % 5 == 0) shouldSave = true;
            }
          }
        });

        if (shouldSave) {
          final prefs = await SharedPreferences.getInstance();
          for (var task in tasks) {
            if (task["isRunning"] == true) {
              await prefs.setInt(
                "task_seconds_${task["id"]}",
                task["elapsedSeconds"],
              );
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Widget _buildSummaryRow() {
    if (_summary == null) return const SizedBox.shrink();
    
    return Container(
      height: 85.h,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Row(
          children: [
            _buildSummaryCard("Pending", _summary!["pending"]?.toString() ?? "0", Colors.red),
            SizedBox(width: 4.w),
            _buildSummaryCard("Partial", _summary!["partial"]?.toString() ?? "0", Colors.orange),
            SizedBox(width: 4.w),
            _buildSummaryCard("Done", _summary!["completed"]?.toString() ?? "0", Colors.green),
            SizedBox(width: 4.w),
            _buildSummaryCard("Total", _summary!["total"]?.toString() ?? "0", Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      width: 75.w,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Assigned Tasks",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF26A69A)),
            )
          : Column(
              children: [
                _buildSummaryRow(),
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Text(
                            "No tasks found",
                            style: GoogleFonts.poppins(fontSize: 16.sp),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(20.w),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            if (task["approvalStatus"] == 'approved') {
                              return const SizedBox.shrink();
                            }
                            return _buildTaskItem(
                              task,
                              onPartialToggle: () {
                                if (!task["isPending"]) return;
                                setState(() {
                                  task["isPartiallyCompleted"] = true;
                                  task["isPending"] = true;
                                  task["isRunning"] = false;
                                  task["isPartialSubmitted"] = false;
                                });
                              },
                              onPartialSubmit: () async {
                                await _updateTaskOnBackend(
                                  task,
                                  status: "partial",
                                  remarks: task["partialReason"] ?? "",
                                );
                                setState(() {
                                  task["isPartialSubmitted"] = true;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Partial reason submitted to backend!"),
                                    ),
                                  );
                                }
                              },
                              onToggle: (bool val) async {
                                if (!val) {
                                  await _updateTaskOnBackend(
                                    task,
                                    status: "done",
                                    remarks: "Task completed",
                                  );
                                  setState(() {
                                    task["isPending"] = false;
                                    task["isRunning"] = false;
                                    task["isPartiallyCompleted"] = false;
                                    task["approvalStatus"] = 'pending';
                                  });
                                } else {
                                  setState(() {
                                    task["isPending"] = true;
                                    task["isPartiallyCompleted"] = false;
                                    task["approvalStatus"] = null;
                                  });
                                }
                              },
                              onTimerToggle: () async {
                                setState(() {
                                  // Stop other timers
                                  for (var t in tasks) t["isRunning"] = false;
                                  task["isRunning"] = true;
                                });
                                // Sync start with backend as requested "once started can't stop"
                                await _updateTaskOnBackend(task, status: "started");
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _updateTaskOnBackend(
    Map<String, dynamic> task, {
    required String status,
    String remarks = "",
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cid = prefs.getString('cid') ?? prefs.getString('cid_str') ?? "21472147";
      final String uid =
          prefs.getString('employee_table_id') ??
          prefs.getString('login_cus_id') ??
          prefs.getString('server_uid') ??
          prefs.getString('uid') ??
          prefs.getInt('uid')?.toString() ??
          "";
      final String deviceId = prefs.getString('device_id') ?? "123456";
      final String lat = prefs.getDouble('lat')?.toString() ?? "0.0";
      final String lng = prefs.getDouble('lng')?.toString() ?? "0.0";
      final String? token = prefs.getString('token');

      // Map status strings to numeric values as required by backend example
      String finalStatus = status;
      if (status == "done" || status == "completed") {
        finalStatus = "1";
      } else if (status == "partial") {
        finalStatus = "2";
      }

      final body = {
        "type": "2074",
        "cid": cid,
        "uid": uid,
        "task_id": task["id"].toString(),
        "status": finalStatus,
        "token": token ?? "",
        "device_id": deviceId,
        "ln": lng,
        "lt": lat,
        "spending_time": _formatDuration(task["elapsedSeconds"] ?? 0),
        "reason": remarks,
        "completion_date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };

      await prefs.setString("task_status_${task["id"]}", status);
      if (status == "partial") {
        await prefs.setString("task_remarks_${task["id"]}", remarks);
      }

      debugPrint("Updating Task (Type 2074) Request Body: $body");

      final response = await ApiClient().post(body);

      debugPrint("Updating Task (Type 2074) Response Body: ${response.body}");
    } catch (e) {
      debugPrint("Error updating task on backend: $e");
    }
  }

  Widget _buildTaskItem(
    Map<String, dynamic> task, {
    required VoidCallback onTimerToggle,
    required VoidCallback onPartialToggle,
    required VoidCallback onPartialSubmit,
    required Function(bool) onToggle,
  }) {
    final String title = task["title"] ?? "Task";
    final String deadline = task["deadline"] ?? "";
    final String taskTiming = task["task_timing"] ?? "";
    final bool isPending = task["isPending"] ?? true;
    final int elapsedSeconds = task["elapsedSeconds"] ?? 0;
    final bool isRunning = task["isRunning"] ?? false;
    final int timeLimitSeconds = task["timeLimitSeconds"] ?? 0;
    final bool isPartiallyCompleted = task["isPartiallyCompleted"] ?? false;
    final String partialReason = task["partialReason"] ?? "";
    final String? approvalStatus = task["approvalStatus"];
    final bool isPartialSubmitted = task["isPartialSubmitted"] ?? false;

    bool isOvertime = timeLimitSeconds > 0 && elapsedSeconds > timeLimitSeconds;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200, width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOvertime)
            Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: Colors.red.shade200, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14.sp,
                    color: Colors.red,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    "OVERTIME",
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B2C61),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            "Finish Within: $taskTiming",
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.person_pin,
                          size: 14.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            "Assigned By: ${task['assignedBy']}",
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            "Due Date: ${task['deadline']}",
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Spend Time: ${_formatDuration(elapsedSeconds)}",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isOvertime
                              ? Colors.red
                              : (isRunning ? Colors.green : Colors.grey),
                        ),
                      ),
                    ),
                    if (isPartialSubmitted)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            "Saved: ${_formatDuration(elapsedSeconds)}",
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: const Divider(height: 1),
          ),
          Row(
            children: [
              if (isPending)
                GestureDetector(
                  onTap: isRunning ? null : onTimerToggle,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: isRunning
                          ? Colors.blue.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRunning ? Icons.timer : Icons.play_arrow,
                          size: 18.sp,
                          color: isRunning ? Colors.blue : Colors.green,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          isRunning ? "Running..." : "Start",
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isRunning ? Colors.blue : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 15.h),
            child: const Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isPending) ...[
                Expanded(
                  child: _statusActionButton(
                    "Partially",
                    isPartiallyCompleted,
                    Colors.orange,
                    isPartiallyCompleted
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    isPending ? onPartialToggle : null,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _statusActionButton(
                    "Pending",
                    isPending && !isPartiallyCompleted,
                    Colors.red,
                    isPending && !isPartiallyCompleted
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    null,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: _statusActionButton(
                  "Completed",
                  !isPending,
                  const Color(0xff05D817),
                  !isPending ? Icons.check_circle : Icons.radio_button_off,
                  isPending ? () => onToggle(false) : null,
                ),
              ),
            ],
          ),
          if (isPartiallyCompleted && !isPartialSubmitted) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: const Divider(height: 1),
            ),
            Text(
              "Reason & Pending Info",
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B2C61),
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              onChanged: (val) => setState(() => task["partialReason"] = val),
              controller: TextEditingController(text: partialReason)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: partialReason.length),
                ),
              maxLines: 2,
              style: GoogleFonts.poppins(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: "Enter why it's pending...",
                contentPadding: EdgeInsets.all(12.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPartialSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26A69A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  "Submit Partial Info",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          if (isPartialSubmitted && isPartiallyCompleted)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_done,
                      color: Colors.orange.shade800,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        "Partial Info Submitted to Backend",
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (approvalStatus != null) ...[
            Padding(
              padding: EdgeInsets.only(top: 15.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: approvalStatus == 'pending'
                      ? Colors.blue.shade50
                      : (approvalStatus == 'approved'
                            ? Colors.green.shade50
                            : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      approvalStatus == 'pending'
                          ? Icons.hourglass_empty
                          : (approvalStatus == 'approved'
                                ? Icons.verified
                                : Icons.cancel),
                      color: approvalStatus == 'pending'
                          ? Colors.blue
                          : (approvalStatus == 'approved'
                                ? Colors.green
                                : Colors.red),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        approvalStatus == 'pending'
                            ? "Waiting for TL Approval"
                            : (approvalStatus == 'approved'
                                  ? "Task Approved"
                                  : "Task Rejected"),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusActionButton(
    String label,
    bool isActive,
    Color color,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: (isActive && label == "Completed")
              ? color
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: 2.w,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22.sp,
              color: (isActive && label == "Completed")
                  ? Colors.white
                  : (isActive ? color : Colors.grey.shade600),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: (isActive && label == "Completed")
                    ? Colors.white
                    : (isActive ? color : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
