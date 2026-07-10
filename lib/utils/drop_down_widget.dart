import 'package:flutter/material.dart';

class DropdownWidget extends StatelessWidget {
  final String? selectedValue;
  final List<String> items;
  final String hintText;
  final ValueChanged<String?> onChanged;
  const DropdownWidget({super.key, required this.selectedValue, required this.items, required this.hintText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: InputDecorator(
            decoration: InputDecoration(
                border: OutlineInputBorder()
            ),
            child: DropdownButton<String>(
                value: selectedValue,
                icon: const Icon(Icons.arrow_drop_down),
                elevation: 16,
                isExpanded: true,
                hint: Text(hintText),
                underline: Container(
                    height: 2,
                    color: const Color(0xff0f766e)
                ),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
            )
        )
    );
  }
}
