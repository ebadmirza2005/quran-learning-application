import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/drop_down_widget.dart';
import '../../utils/text.dart';
import '../tutor_home_screen.dart';

class TutorAvailability extends StatefulWidget {
  const TutorAvailability({super.key});

  @override
  State<TutorAvailability> createState() => _TutorAvailabilityState();
}

class _TutorAvailabilityState extends State<TutorAvailability> {
  final supabase = Supabase.instance.client;

  // 🔄 Fetch all availability slots for logged-in tutor
  Future<List<Map<String, dynamic>>> _fetchSchedules() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('tutor_availability')
        .select()
        .eq('tutor_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 🗑️ Specific Slot Delete Logic
  Future<void> _deleteSchedule(String slotId) async {
    try {
      await supabase.from('tutor_availability').delete().eq('id', slotId);

      if (!mounted) return;

      // UI refresh karne ke liye
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Schedule slot removed!"),
          backgroundColor: Color(0xff0f766e),
        ),
      );
    } catch (e) {
      debugPrint("Error deleting slot: $e");
    }
  }

  void _showScheduleDialog() {
    String selectedValue = "Select Day";
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String formatTimeOfDay(TimeOfDay? time) {
              if (time == null) return "Select Time";
              final now = DateTime.now();
              final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
              return TimeOfDay.fromDateTime(dt).format(context);
            }

            ThemeData greenPickerTheme = Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xff0f766e),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              timePickerTheme: TimePickerThemeData(
                dialHandColor: const Color(0xff0f766e),
                dialBackgroundColor: const Color(0xff0f766e).withOpacity(0.08),
                entryModeIconColor: const Color(0xff0f766e),
              ),
            );

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Availability Slot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownWidget(
                      selectedValue: selectedValue,
                      items: const [
                        'Select Day',
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday'
                      ],
                      hintText: "Select Day",
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedValue = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Start At", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: startTime ?? TimeOfDay.now(),
                                    builder: (context, child) => Theme(data: greenPickerTheme, child: child!),
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      startTime = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatTimeOfDay(startTime),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: startTime != null ? FontWeight.w600 : FontWeight.normal,
                                          color: startTime != null ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                      const Icon(Icons.access_time, size: 18, color: Color(0xff0f766e)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("End At", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: endTime ?? TimeOfDay.now(),
                                    builder: (context, child) => Theme(data: greenPickerTheme, child: child!),
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      endTime = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatTimeOfDay(endTime),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: endTime != null ? FontWeight.w600 : FontWeight.normal,
                                          color: endTime != null ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                      const Icon(Icons.access_time_filled, size: 18, color: Color(0xff0f766e)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0f766e),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (selectedValue == "Select Day") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a day")),
                      );
                      return;
                    }

                    if (startTime == null || endTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select both Start and End time")),
                      );
                      return;
                    }

                    try {
                      final user = supabase.auth.currentUser;
                      if (user == null) return;

                      final String formattedStart = startTime!.format(context);
                      final String formattedEnd = endTime!.format(context);

                      await supabase.from('tutor_availability').insert({
                        'tutor_id': user.id,
                        'day': selectedValue,
                        'start_time': formattedStart,
                        'end_time': formattedEnd,
                      });

                      if (!context.mounted) return;

                      Navigator.pop(context);

                      // List refresh karne ke liye
                      setState(() {});

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Slot added successfully!"),
                          backgroundColor: Color(0xff0f766e),
                        ),
                      );
                    } catch (e) {
                      debugPrint("Database Error: $e");
                    }
                  },
                  child: const Text("Save Slot", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TutorHomeScreen()),
              );
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const TextWidget(text: "Tutor Availability"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showScheduleDialog,
            icon: const Icon(Icons.add, size: 30),
          )
        ],
      ),
      body: user == null
          ? const Center(child: Text("User not logged in"))
          : FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchSchedules(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff0f766e)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error Loading Data: ${snapshot.error}"),
            );
          }

          final slots = snapshot.data ?? [];

          if (slots.isEmpty) {
            return const Center(
              child: Text(
                "No Schedule Added Yet.\nClick '+' to add your availability slots.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final item = slots[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xff0f766e).withOpacity(0.1),
                    child: const Icon(Icons.calendar_today, color: Color(0xff0f766e), size: 20),
                  ),
                  title: Text(
                    item['day'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    "${item['start_time']} - ${item['end_time']}",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      _deleteSchedule(item['id'].toString());
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}