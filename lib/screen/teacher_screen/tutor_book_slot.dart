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
  Map<String, dynamic>? selectedSlotData;
  bool isBooking = false;
  bool isFirstTimeTrial = false;
  bool isLoadingTutorData = true;

  late Future<List<Map<String, dynamic>>> _slotsFuture;

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
  String selectedDuration = "1 Hour";
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

    _slotsFuture = _fetchTutorSlots();
    _fetchTutorDetailsAndTrialStatus();
  }

  // Dynamic End Time Calculator based on selected duration
  String _calculateEndTime(String startTimeStr, String durationStr) {
    try {
      String cleanTime = startTimeStr.trim().toUpperCase();
      DateTime parsedTime;

      if (cleanTime.contains('AM') || cleanTime.contains('PM')) {
        parsedTime = DateFormat("h:mm a").parse(cleanTime);
      } else {
        parsedTime = DateFormat("HH:mm").parse(cleanTime);
      }

      int durationInMinutes = 60; // Default 1 hour
      if (durationStr.contains("30")) {
        durationInMinutes = 30;
      } else if (durationStr.contains("1.5")) {
        durationInMinutes = 90;
      } else if (durationStr.contains("2")) {
        durationInMinutes = 120;
      } else if (durationStr.contains("1")) {
        durationInMinutes = 60;
      }

      DateTime endTime = parsedTime.add(Duration(minutes: durationInMinutes));
      return DateFormat("h:mm a").format(endTime);
    } catch (e) {
      return startTimeStr;
    }
  }

  Future<void> _fetchTutorDetailsAndTrialStatus() async {
    try {
      final user = supabase.auth.currentUser;

      debugPrint("Fetching details for Tutor ID: ${widget.tutorId}");

      dynamic res;
      try {
        res = await supabase
            .from('tutors')
            .select('*')
            .eq('id', widget.tutorId)
            .maybeSingle();
      } catch (e) {
        res = await supabase
            .from('tutors')
            .select('*')
            .eq('user_id', widget.tutorId)
            .maybeSingle();
      }

      if (res != null && mounted) {
        setState(() {
          _currentTutorName = res['full_name'] ?? res['name'] ?? res['tutor_name'] ?? 'Tutor';

          if (res['skills'] != null) {
            if (res['skills'] is List) {
              _tutorSkills = List<String>.from(res['skills'].map((item) => item.toString()));
            } else if (res['skills'] is String) {
              _tutorSkills = (res['skills'] as String).split(',').map((e) => e.trim()).toList();
            }
          }

          final rawRate = res['hourly_rate'] ?? res['rate'] ?? res['price_per_hour'] ?? 0;
          _hourlyRate = double.tryParse(rawRate.toString()) ?? 0.0;
        });
      }

      if (user != null) {
        final usedTrialBooking = await supabase
            .from('bookings')
            .select('id')
            .eq('student_id', user.id)
            .eq('is_trial', true)
            .neq('status', 'cancelled')
            .neq('status', 'rejected')
            .limit(1);

        final usedTrialInvite = await supabase
            .from('invites')
            .select('id')
            .eq('student_id', user.id)
            .eq('is_trial', true)
            .neq('status', 'cancelled')
            .neq('status', 'rejected')
            .limit(1);

        bool hasUsedTrialAlready = usedTrialBooking.isNotEmpty || usedTrialInvite.isNotEmpty;

        if (mounted) {
          setState(() {
            isFirstTimeTrial = (!hasUsedTrialAlready) && (!widget.isAlreadyHired);

            if (isFirstTimeTrial) {
              selectedDuration = "30 Minutes (Free Trial)";
            } else {
              selectedDuration = "1 Hour";
            }
          });
          debugPrint("🔥 TRIAL ELIGIBLE STATUS: $isFirstTimeTrial");
        }
      }
    } catch (e) {
      debugPrint("❌ Supabase Tutor Fetch Error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoadingTutorData = false);
      }
    }
  }

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
      final bool trialStatusToSave = (isFirstTimeTrial == true);
      final actualRate = trialStatusToSave ? 0.0 : _hourlyRate;
      final finalDuration = trialStatusToSave ? "30 Minutes (Free Trial)" : selectedDuration;

      final String initialStatus = widget.isAlreadyHired ? 'confirmed' : 'pending';
      final String inviteStatus = widget.isAlreadyHired ? 'accepted' : 'pending';

      final bookingRes = await supabase.from('bookings').insert({
        'student_id': currentStudentId,
        'tutor_id': widget.tutorId,
        'slot_id': selectedSlotId,
        'status': initialStatus,
        'is_trial': trialStatusToSave,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      await supabase.from('invites').insert({
        'tutor_id': widget.tutorId,
        'student_id': currentStudentId,
        'duration': finalDuration,
        'selected_skills': chosenSkills,
        'hourly_rate': actualRate,
        'is_trial': trialStatusToSave,
        'status': inviteStatus,
        'booking_id': bookingRes['id'],
      });

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop(); // Close Dialog
      if (mounted) {
        Navigator.of(context).pop(true); // Close Screen
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAlreadyHired
                ? "Additional Slot Booked Successfully!"
                : (trialStatusToSave
                ? "🎁 Free Trial Claimed & Request Sent!"
                : "Slot Booked and Invitation Sent!"),
          ),
          backgroundColor: const Color(0xff0f766e),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isBooking = false);
    }
  }

  void _showInviteDialog() {
    if (selectedSlotId == null || selectedSlotData == null) {
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

    String slotStartTime = selectedSlotData!['start_time'] ?? 'N/A';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String displayEndTime = isFirstTimeTrial
                ? _calculateEndTime(slotStartTime, "30 Minutes")
                : _calculateEndTime(slotStartTime, selectedDuration);

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextWidget(
                              text: isFirstTimeTrial
                                  ? "Claim Free Trial Slot"
                                  : "Contract of $_currentTutorName",
                              textSize: 16,
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
                                "🎁 100% FREE",
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
                          const TextWidget(text: "Day: ", textWeight: FontWeight.bold, textColor: Color(0xff0f766e)),
                          const SizedBox(width: 3),
                          TextWidget(text: selectedDay),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const TextWidget(text: "Slot Time: ", textWeight: FontWeight.bold, textColor: Color(0xff0f766e)),
                          const SizedBox(width: 3),
                          TextWidget(text: "$slotStartTime - $displayEndTime"),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const TextWidget(
                        text: "Lesson Duration",
                        textWeight: FontWeight.bold,
                        textColor: Color(0xff0f766e),
                      ),
                      const SizedBox(height: 8),

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
                            Icon(Icons.stars_rounded, color: Color(0xff0f766e), size: 22),
                            SizedBox(width: 8),
                            Text(
                              "30 Minutes (Free Trial Lesson)",
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
                          if (newValue != null) {
                            setDialogState(() {
                              selectedDuration = newValue;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 15),

                      if (_tutorSkills.isNotEmpty) ...[
                        const TextWidget(
                          text: "What would you like to learn?",
                          textWeight: FontWeight.bold,
                          textColor: Color(0xff0f766e),
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
                            const TextWidget(
                              text: "Total Amount: ",
                              textWeight: FontWeight.bold,
                              textColor: Color(0xff0f766e),
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
                            child: TextButtonWidget(
                              buttonText: "Cancel",
                              textColor: const Color(0xff0f766e),
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButtonWidget(
                              buttonText: isFirstTimeTrial
                                  ? "Free Trial"
                                  : (widget.isAlreadyHired ? "Confirm Booking" : "Send Invite"),
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
    try {
      final response = await supabase
          .from('tutor_availability')
          .select()
          .eq('tutor_id', widget.tutorId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

    } catch (e) {
      debugPrint("❌ Error fetching slots: $e");
      return [];
    }
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
          text: widget.isAlreadyHired
              ? "Book Extra Slot"
              : (isFirstTimeTrial ? "Claim Free Trial Slot" : "Book Availability Slot"),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (!isLoadingTutorData && isFirstTimeTrial && !widget.isAlreadyHired)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: const Color(0xff0f766e).withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard_rounded, color: Color(0xff0f766e), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                        children: [
                          const TextSpan(text: "First time with "),
                          TextSpan(
                            text: _currentTutorName.isNotEmpty ? _currentTutorName : "this tutor",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: "? Your first "),
                          const TextSpan(
                            text: "30-minute trial is 100% Free!",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0f766e)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                      checkmarkColor: Colors.white,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            selectedDay = day;
                            selectedSlotId = null;
                            selectedSlotData = null;
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
              future: _slotsFuture,
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
                        onTap: isPassed
                            ? null
                            : () => setState(() {
                          selectedSlotId = slotId;
                          selectedSlotData = item;
                        }),
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
                          onChanged: (value) => setState(() {
                            selectedSlotId = value;
                            selectedSlotData = item;
                          }),
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
                onPressed: isBooking ? null : _showInviteDialog,
                child: isBooking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  widget.isAlreadyHired
                      ? "Confirm Booking"
                      : (isFirstTimeTrial ? "🎁 Claim Free Trial (30 Mins)" : "Proceed to Invite"),
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