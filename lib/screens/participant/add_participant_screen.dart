import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/participant.dart';
import '../../providers/participant_provider.dart';
import 'widgets/participant_form_fields.dart';
import 'widgets/action_button.dart';

class AddParticipantScreen extends StatefulWidget {
  final String? raceId;

  const AddParticipantScreen({
    super.key,
    this.raceId, 
  });

  @override
  _AddParticipantScreenState createState() => _AddParticipantScreenState();
}

class _AddParticipantScreenState extends State<AddParticipantScreen> {
  final _bibNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAddingParticipant = false;

  @override
  void initState() {
    super.initState();
    print("📱 AddParticipantScreen initialized with raceId: ${widget.raceId}");

    if (widget.raceId == null) {
      print("Error : AddParticipantScreen initialized without raceId");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final participantProvider = Provider.of<ParticipantProvider>(
          context,
          listen: false,
        );
        final currentRaceId = participantProvider.currentRaceId;

        if (currentRaceId == null) {
          print("Error !!!  No race ID available in provider either");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No active race found. Please return and try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          print("✅ Using raceId from provider: $currentRaceId");
        }
      });
    }
  }

  @override
  void dispose() {
    _bibNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _addParticipant() async {
    print("🔄 Add participant button pressed");

    int filledFields = 0;
    if (_bibNumberController.text.isNotEmpty) filledFields++;
    if (_firstNameController.text.isNotEmpty) filledFields++;
    if (_lastNameController.text.isNotEmpty) filledFields++;

    if (filledFields < 2) {
      print("⚠️ Not enough fields filled");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least two fields must be filled'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final participantProvider = Provider.of<ParticipantProvider>(
        context,
        listen: false,
      );
      final existingParticipant = participantProvider.participants.any(
        (p) => p.bibNumber == _bibNumberController.text,
      );

      if (existingParticipant) {
        print("⚠️ Duplicate BIB number detected");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A participant with this BIB number already exists'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final String? raceId = widget.raceId ?? participantProvider.currentRaceId;

      if (raceId == null || raceId.isEmpty) {
        print("❌ No race ID available");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active race found. Please return and try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final participant = Participant(
        bibNumber: _bibNumberController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        raceId: raceId,
      );

      try {
     
        setState(() {
          _isAddingParticipant = true;
        });

        print(
          "📝 Adding participant: ${participant.bibNumber} to race: ${participant.raceId}",
        );

        await participantProvider.addParticipant(participant);

        if (participantProvider.error != null) {
          print("❌ Error from provider: ${participantProvider.error}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error adding participant: ${participantProvider.error}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          print("✅ Participant added successfully");
          _bibNumberController.clear();
          _firstNameController.clear();
          _lastNameController.clear();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Participant added successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true); 
          }
        }
      } catch (e) {
        print("❌ Error in _addParticipant: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding participant: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isAddingParticipant = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final participantProvider = Provider.of<ParticipantProvider>(
      context,
      listen: false,
    );
    final currentRaceId = widget.raceId ?? participantProvider.currentRaceId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Participant'),

        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adding to Race ID: ${currentRaceId ?? "Unknown"}',
                style: TextStyle(
                  color: currentRaceId != null ? Colors.blue[800] : Colors.red,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),              Form(
                key: _formKey,
                child: Column(
                  children: [
                    ParticipantFormFields(
                      bibNumberController: _bibNumberController,
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                    ),
                    const SizedBox(height: 24),
                    ActionButton(
                      isLoading: _isAddingParticipant,
                      onPressed: currentRaceId != null && !_isAddingParticipant
                          ? _addParticipant
                          : null,
                      label: 'Add Participant',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
