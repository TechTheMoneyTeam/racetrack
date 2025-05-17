import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'repositories/firebase/firebase_participant_repository.dart';
import 'repositories/firebase/firebase_race_repository.dart';
import 'repositories/firebase/firebase_segment_time_repository.dart';
import 'providers/race_provider.dart';
import 'providers/participant_provider.dart';
import 'providers/time_tracking_provider.dart';
import 'screens/race_manager/race_setup_screen.dart';
import 'screens/race_manager/race_control_screen.dart';
import 'screens/time_tracker/segment_selection_screen.dart';
import 'screens/race_manager/results_board_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    runApp(ErrorApp(error: e.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Race Tracking App',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Race Tracking App')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize Firebase',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error details: $error',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Try the following:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Check your internet connection'),
                const Text('• Verify Firebase configuration'),
                const Text(
                  '• Restart the app completely (not just hot reload)',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final raceRepository = FirebaseRaceRepository();
    final participantRepository = FirebaseParticipantRepository();
    final segmentTimeRepository = FirebaseSegmentTimeRepository();

    return MultiProvider(
      providers: [
        Provider<FirebaseRaceRepository>.value(value: raceRepository),
        Provider<FirebaseParticipantRepository>.value(
          value: participantRepository,
        ),
        Provider<FirebaseSegmentTimeRepository>.value(
          value: segmentTimeRepository,
        ),

        ChangeNotifierProvider<RaceProvider>(
          create: (_) => RaceProvider(raceRepository),
        ),
        ChangeNotifierProvider<ParticipantProvider>(
          create: (_) => ParticipantProvider(participantRepository),
        ),
        ChangeNotifierProvider<TimeTrackingProvider>(
          create: (_) => TimeTrackingProvider(segmentTimeRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Race Tracking App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final raceProvider = Provider.of<RaceProvider>(context);
    final String? currentRaceId = raceProvider.currentRaceId;

    Widget currentScreen;
    switch (_selectedIndex) {
      case 0:
        currentScreen = RaceSetupScreen(
          onRaceCreated: (raceId) {
            raceProvider.setCurrentRaceId(raceId);
          },
        );
        break;
      case 1:
        currentScreen =
            currentRaceId == null
                ? const NoRaceScreen(
                  message: 'Please create a race first in the Dashboard tab.',
                )
                : RaceControlScreen(raceId: currentRaceId);
        break;
      case 2:
        currentScreen =
            currentRaceId == null
                ? const NoRaceScreen(
                  message: 'Please create a race first in the Dashboard tab.',
                )
                : SegmentSelectionScreen(raceId: currentRaceId);
        break;
      case 3:
        currentScreen =
            currentRaceId == null
                ? const NoRaceScreen(
                  message: 'Please create a race first in the Dashboard tab.',
                )
                : ResultsBoardScreen(raceId: currentRaceId);
        break;
      default:
        currentScreen = const Center(child: Text('Unknown screen'));
    }

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C3B5B),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => _onItemTapped(0),
              child: _buildNavItem(
                Icons.dashboard,
                'Dashboard',
                _selectedIndex == 0,
              ),
            ),
            GestureDetector(
              onTap: () => _onItemTapped(1),
              child: _buildNavItem(
                Icons.punch_clock,
                'Timer',
                _selectedIndex == 1,
              ),
            ),
            GestureDetector(
              onTap: () => _onItemTapped(2),
              child: _buildNavItem(
                Icons.sports_bar,
                'Segments',
                _selectedIndex == 2,
              ),
            ),
            GestureDetector(
              onTap: () => _onItemTapped(3),
              child: _buildNavItem(
                Icons.leaderboard,
                'Results',
                _selectedIndex == 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoRaceScreen extends StatelessWidget {
  final String message;

  const NoRaceScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                (context.findAncestorStateOfType<_HomeScreenState>())
                    ?._onItemTapped(0);
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
