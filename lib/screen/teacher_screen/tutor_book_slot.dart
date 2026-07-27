import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/button.dart';
import '../../utils/drop_down_widget.dart';
import '../../utils/text.dart';

class TutorBookSlot extends StatefulWidget {
  final String tutorId;
  final bool isAlreadyHired;

  const TutorBookSlot({
    super.key,
    required this.tutorId,
    this.isAlreadyHired = false,
  });

  @override
  State<TutorBookSlot> createState() => _TutorBookSlotState();
}

class _TutorBookSlotState extends State<TutorBookSlot> {
  final supabase = Supabase.instance.client;

  String? selectedSlotId;
  bool isBooking = false;
  bool isFirstTimeTrial = true; // 🟢 Free Trial status check

  final List<String> _weekDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  late String selectedDay;
  String selectedDuration = "30 Minutes (Free Trial)";
  List<String> _tutorSkills = [];
  Map<String, bool> selectedSkills = {};
  double _hourlyRate = 0.00;
  String _currentTutorName = '';

  @override
  void initState() {
    super.initState();
    selectedDay = DateFormat('EEEE').format(DateTime.now());
    if (!_weekDays.contains(selectedDay)) {
      selectedDay = "Monday";
    }
    _fetchTutorDetailsAndTrialStatus();
  }

  // 🔄 Fetch tutor info + Check if user qualifies for Free Trial
  Future<void> _fetchTutorDetailsAndTrialStatus() async {
    try {
      final user = supabase.auth.currentUser;

      // 1. Fetch tutor details
      final res = await supabase
          .from('tutors')
          .select('full_name, skills, hourly_rate')
          .eq('id', widget.tutorId)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _currentTutorName = res['full_name'] ?? 'Tutor';
          _tutorSkills = List<String>.from(res['skills'] ?? []);
          _hourlyRate = (res['hourly_rate'] ?? 0).toDouble();
        });
      }

      // 2. Check if student has already taken any booking/invite before
      if (user != null) {
        final previousInvites = await supabase
            .from('invites')
            .select('id')
            .eq('student_id', user.id)
            .eq('tutor_id', widget.tutorId)
            .limit(1)
            .maybeSingle();

        if (mounted) {
          setState(() {
            // Agar pehle invite maujood hai toh Free trial nahi hoga
            isFirstTimeTrial = (previousInvites == null) && !widget.isAlreadyHired;

            if (isFirstTimeTrial) {
              selectedDuration = "30 Minutes (Free Trial)";
            } else {
              selectedDuration = "1 Hour"; // Default paid duration
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching trial status: $e");
    }
  }

  // 🟢 DIRECT SLOT BOOKING (When already hired)
  Future<void> _bookDirectSlot() async {
    if (selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an available slot first"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isBooking = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('bookings').insert({
        'student_id': user.id,
        'tutor_id': widget.tutorId,
        'slot_id': selectedSlotId,
        'status': 'confirmed',
        'is_trial': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Additional slot booked successfully!"),
          backgroundColor: Color(0xff0f766e),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Booking Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isBooking = false);
    }
  }

  // 🟢 INVITE SUBMIT WITH FREE TRIAL SUPPORT
  Future<void> _submitBookingAndInvite() async {
    final currentStudentId = supabase.auth.currentUser?.id;
    if (currentStudentId == null) return;

    List<String> chosenSkills = selectedSkills.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    if (chosenSkills.isEmpty && _tutorSkills.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one skill")),
      );
      return;
    }

    setState(() => isBooking = true);

    try {
      // Step A: Booking Table Entry
      final bookingRes = await supabase.from('bookings').insert({
        'student_id': currentStudentId,
        'tutor_id': widget.tutorId,
        'slot_id': selectedSlotId,
        'status': 'pending',
        'is_trial': isFirstTimeTrial, // 🟢 Mark if this is a trial booking
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      // Step B: Invite Table Entry
      final actualRate = isFirstTimeTrial ? 0.0 : _hourlyRate; // $0 for trial

      await supabase.from('invites').insert({
        'tutor_id': widget.tutorId,
        'student_id': currentStudentId,
        'duration': selectedDuration,
        'selected_skills': chosenSkills,
        'hourly_rate': actualRate,
        'is_trial': isFirstTimeTrial,
        'status': 'pending',
        'booking_id': bookingRes['id'],
      });

      if (!mounted) return;

      Navigator.of(context).pop(); // Close Dialog
      Navigator.of(context).pop(true); // Close Page

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFirstTimeTrial
                ? "Free Trial Invite Sent Successfully!"
                : "Slot Booked and Invitation Sent!",
          ),
          backgroundColor: const Color(0xff0f766e),
        ),
      );
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isBooking = false);
    }
  }

  // 🟢 CONTRACT DIALOG WITH FREE TRIAL BADGE
  void _showInviteDialog() {
    if (selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an available slot first!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    for (var skill in _tutorSkills) {
      selectedSkills.putIfAbsent(skill, () => false);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            DateTime now = DateTime.now();
            String formattedDate = DateFormat("EEE, MMM d, yyyy").format(now);
            String formattedTime = DateFormat('hh:mm a').format(now);

            // Free Trial duration is locked to 30 mins
            int minutesToAdd = isFirstTimeTrial ? 30 : 60;
            DateTime endTime = now.add(Duration(minutes: minutesToAdd));
            String formattedEndTime = DateFormat('hh:mm a').format(endTime);

            Widget buildSkillItem(String skillName) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    activeColor: const Color(0xff0f766e),
                    value: selectedSkills[skillName] ?? false,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        selectedSkills[skillName] = value ?? false;
                      });
                    },
                  ),
                  Flexible(child: TextWidget(text: skillName)),
                ],
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 5,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🟢 Header Row with Free Trial Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextWidget(
                              text: "Contract of $_currentTutorName",
                              textSize: 18,
                              textWeight: FontWeight.bold,
                              textColor: const Color(0xff0f766e),
                            ),
                          ),
                          if (isFirstTimeTrial)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xff0f766e).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xff0f766e)),
                              ),
                              child: const Text(
                                "🎁 FREE TRIAL",
                                style: TextStyle(
                                  color: Color(0xff0f766e),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextWidget(text: "Date: ", textWeight: FontWeight.bold, textColor: const Color(0xff0f766e)),
                          const SizedBox(width: 3),
                          TextWidget(text: formattedDate),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextWidget(text: "Time: ", textWeight: FontWeight.bold, textColor: const Color(0xff0f766e)),
                          const SizedBox(width: 3),
                          TextWidget(text: formattedTime),
                          const SizedBox(width: 5),
                          TextWidget(text: "To"),
                          const SizedBox(width: 5),
                          TextWidget(text: formattedEndTime),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextWidget(
                        text: "Lesson Duration",
                        textWeight: FontWeight.bold,
                        textColor: const Color(0xff0f766e),
                      ),
                      const SizedBox(height: 8),

                      // 🟢 Duration Selection (Disabled / Auto-Set for Free Trial)
                      isFirstTimeTrial
                          ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xff0f766e).withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.timer_outlined, color: Color(0xff0f766e), size: 20),
                            SizedBox(width: 8),
                            Text(
                              "30 Minutes (Free Trial)",
                              style: TextStyle(
                                color: Color(0xff0f766e),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                          : DropdownWidget(
                        hintText: "Select Duration",
                        selectedValue: selectedDuration,
                        items: const ["30 Minutes", "1 Hour", "1.5 Hours", "2 Hours"],
                        onChanged: (newValue) {
                          setDialogState(() {
                            selectedDuration = newValue!;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      if (_tutorSkills.isNotEmpty) ...[
                        TextWidget(
                          text: "What would you like to learn?",
                          textWeight: FontWeight.bold,
                          textColor: const Color(0xff0f766e),
                        ),
                        const SizedBox(height: 5),
                        for (int i = 0; i < _tutorSkills.length; i += 2) ...[
                          Row(
                            children: [
                              Expanded(child: buildSkillItem(_tutorSkills[i])),
                              const SizedBox(width: 10),
                              Expanded(
                                child: (i + 1 < _tutorSkills.length)
                                    ? buildSkillItem(_tutorSkills[i + 1])
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            TextWidget(
                              text: "Contract Rate: ",
                              textWeight: FontWeight.bold,
                              textColor: const Color(0xff0f766e),
                            ),
                            const SizedBox(width: 3),
                            TextWidget(
                              text: isFirstTimeTrial ? "FREE (\$0.00)" : "\$${_hourlyRate.toStringAsFixed(2)} / hour",
                              textWeight: FontWeight.bold,
                              textColor: isFirstTimeTrial ? Colors.green.shade700 : Colors.black,
                            ),
                          ],
                        )
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButtonWidget(
                              buttonText: "Cancel",
                              buttonColor: Colors.grey.shade400,
                              textColor: Colors.white,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButtonWidget(
                              buttonText: isFirstTimeTrial ? "Start Free Trial" : "Send Invite",
                              buttonColor: const Color(0xff0f766e),
                              textColor: Colors.white,
                              onTap: _submitBookingAndInvite,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchTutorSlots() async {
    final response = await supabase
        .from('tutor_availability')
        .select()
        .eq('tutor_id', widget.tutorId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  bool _isSlotPassed(String slotDay, String? startTimeStr) {
    if (startTimeStr == null || startTimeStr.isEmpty) return false;

    DateTime now = DateTime.now();
    int currentDayIndex = now.weekday - 1;
    int slotDayIndex = _weekDays.indexOf(slotDay);

    if (slotDayIndex < currentDayIndex) return true;

    if (slotDayIndex == currentDayIndex) {
      try {
        DateTime parsedTime;
        String cleanTime = startTimeStr.trim().toUpperCase();

        if (cleanTime.contains('AM') || cleanTime.contains('PM')) {
          parsedTime = DateFormat("h:mm a").parse(cleanTime);
        } else {
          parsedTime = DateFormat("HH:mm").parse(cleanTime);
        }

        DateTime slotDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          parsedTime.hour,
          parsedTime.minute,
        );

        return now.isAfter(slotDateTime);
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: TextWidget(
          text: widget.isAlreadyHired ? "Book Extra Slot" : "Book Availability Slot",
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Days List
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _weekDays.map((day) {
                  final bool isSelected = day == selectedDay;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(
                        day,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xff0f766e),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xff0f766e),
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            selectedDay = day;
                            selectedSlotId = null;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1),

          // Slots List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTutorSlots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xff0f766e)));
                }

                final allSlots = snapshot.data ?? [];
                final daySlots = allSlots.where((s) {
                  final dayStr = s['day']?.toString().toLowerCase() ?? '';
                  return dayStr == selectedDay.toLowerCase();
                }).toList();

                if (daySlots.isEmpty) {
                  return Center(
                    child: Text("No slots available on $selectedDay.", style: const TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: daySlots.length,
                  itemBuilder: (context, index) {
                    final item = daySlots[index];
                    final String slotId = item['id'].toString();
                    final String startTime = item['start_time'] ?? '';
                    final String endTime = item['end_time'] ?? '';

                    final bool isPassed = _isSlotPassed(selectedDay, startTime);
                    final bool isSelected = selectedSlotId == slotId;

                    return Card(
                      elevation: isPassed ? 0 : (isSelected ? 4 : 1),
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isPassed ? Colors.grey.shade200 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isPassed
                              ? Colors.grey.shade300
                              : (isSelected ? const Color(0xff0f766e) : Colors.transparent),
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        enabled: !isPassed,
                        onTap: isPassed ? null : () => setState(() => selectedSlotId = slotId),
                        leading: CircleAvatar(
                          backgroundColor: isPassed
                              ? Colors.grey.shade400
                              : (isSelected
                              ? const Color(0xff0f766e)
                              : const Color(0xff0f766e).withOpacity(0.1)),
                          child: Icon(
                            Icons.access_time_rounded,
                            color: isPassed ? Colors.white : (isSelected ? Colors.white : const Color(0xff0f766e)),
                            size: 20,
                          ),
                        ),
                        title: Text("$startTime - $endTime", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(selectedDay),
                        trailing: isPassed
                            ? const Text("Unavailable", style: TextStyle(color: Colors.grey))
                            : Radio<String>(
                          value: slotId,
                          groupValue: selectedSlotId,
                          activeColor: const Color(0xff0f766e),
                          onChanged: (value) => setState(() => selectedSlotId = value),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0f766e),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isBooking
                    ? null
                    : () {
                  if (widget.isAlreadyHired) {
                    _bookDirectSlot();
                  } else {
                    _showInviteDialog();
                  }
                },
                child: isBooking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  widget.isAlreadyHired
                      ? "Confirm Booking"
                      : (isFirstTimeTrial ? "Claim Free Trial (30 Mins)" : "Proceed to Invite"),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}