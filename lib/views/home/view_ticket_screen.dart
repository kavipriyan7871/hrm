import 'package:flutter/material.dart';
import '../home/ticket_raise.dart';
import 'package:intl/intl.dart';

class ViewTicketRaisingScreen extends StatelessWidget {
  final List<Map<String, dynamic>> tickets;

  // ✅ SAFE CONSTRUCTOR (NO MORE NoSuchMethodError)
  const ViewTicketRaisingScreen({
    super.key,
    this.tickets = const [], // 👈 DEFAULT VALUE
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2AA89A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ticket Raising',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 TICKET LIST
            Expanded(
              child: tickets.isEmpty
                  ? const Center(
                      child: Text(
                        "No tickets found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];

                        // ✅ SAFE DATE HANDLING
                        DateTime dateTime;
                        if (ticket["date"] is DateTime) {
                          dateTime = ticket["date"];
                        } else {
                          dateTime = DateTime.now();
                        }

                        final formattedDate = DateFormat(
                          'MMM d, yyyy  hh:mm a',
                        ).format(dateTime);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ticketCard(
                            title: ticket["title"] ?? "No Title",
                            dept:
                                "Dept: ${ticket["dept"] ?? "-"}",
                            date: formattedDate,
                            priority:
                                "Priority: ${ticket["priority"] ?? "-"}",
                            status: ticket["status"] ?? "Pending",
                            statusColor:
                                (ticket["status"] ?? "Pending") == "Pending"
                                    ? Colors.orange.shade100
                                    : Colors.green.shade100,
                            statusTextColor:
                                (ticket["status"] ?? "Pending") == "Pending"
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        );
                      },
                    ),
            ),

            // 🔹 RAISE TICKET BUTTON
            SizedBox(
              width: 180,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2AA89A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TicketRaise(),
                    ),
                  );
                },
                child: const Text(
                  'Raise Ticket',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ================= TICKET CARD =================
  Widget _ticketCard({
    required String title,
    required String dept,
    required String date,
    required String priority,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dept\n$date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priority,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusTextColor,
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
