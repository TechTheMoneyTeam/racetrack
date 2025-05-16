import 'package:flutter/material.dart';

class BibNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSubmitted;

  const BibNumberInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'BIB Number',
              labelStyle: const TextStyle(color: Color(0xFF0C3B5B)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0C3B5B)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF0C3B5B), width: 2),
              ),
              prefixIcon: const Icon(Icons.numbers, color: Color(0xFF0C3B5B)),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: onSubmitted,
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () => onSubmitted(controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0C3B5B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            elevation: 2,
          ),
          child: const Text('TRACK TIME'),
        ),
      ],
    );
  }
}
