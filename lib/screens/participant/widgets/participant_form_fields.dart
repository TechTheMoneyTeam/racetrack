import 'package:flutter/material.dart';

class ParticipantFormFields extends StatelessWidget {
  final TextEditingController bibNumberController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;

  const ParticipantFormFields({
    super.key,
    required this.bibNumberController,
    required this.firstNameController,
    required this.lastNameController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: bibNumberController,
          decoration: const InputDecoration(
            labelText: 'BIB Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.confirmation_number),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a BIB number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: firstNameController,
          decoration: const InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a first name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: lastNameController,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a last name';
            }
            return null;
          },
        ),
      ],
    );
  }
}
