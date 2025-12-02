import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const WorkoutApp());
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Gym Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF76FF03), // Neon Lime
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF76FF03),
          secondary: Color(0xFF00E5FF), // Neon Blue
          surface: Color(0xFF1E1E1E),
          onPrimary: Colors.black,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFF76FF03), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WorkoutHomePage(),
      },
    );
  }
}

class WorkoutEntry {
  final String id;
  final DateTime date;
  final String exercise;
  final double weight;
  final int sets;
  final int reps;

  WorkoutEntry({
    required this.id,
    required this.date,
    required this.exercise,
    required this.weight,
    required this.sets,
    required this.reps,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'exercise': exercise,
        'weight': weight,
        'sets': sets,
        'reps': reps,
      };

  factory WorkoutEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      exercise: json['exercise'],
      weight: json['weight'].toDouble(),
      sets: json['sets'],
      reps: json['reps'],
    );
  }
}

class WorkoutHomePage extends StatefulWidget {
  const WorkoutHomePage({super.key});

  @override
  State<WorkoutHomePage> createState() => _WorkoutHomePageState();
}

class _WorkoutHomePageState extends State<WorkoutHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _weightController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  List<WorkoutEntry> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _weightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? workoutsJson = prefs.getString('workouts');
    if (workoutsJson != null) {
      final List<dynamic> decoded = jsonDecode(workoutsJson);
      setState(() {
        _workouts = decoded.map((e) => WorkoutEntry.fromJson(e)).toList();
        _sortWorkouts();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_workouts.map((e) => e.toJson()).toList());
    await prefs.setString('workouts', encoded);
  }

  void _sortWorkouts() {
    _workouts.sort((a, b) => b.date.compareTo(a.date));
  }

  void _addWorkout() {
    if (_formKey.currentState!.validate()) {
      final newEntry = WorkoutEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: _selectedDate,
        exercise: _exerciseController.text,
        weight: double.tryParse(_weightController.text) ?? 0,
        sets: int.tryParse(_setsController.text) ?? 0,
        reps: int.tryParse(_repsController.text) ?? 0,
      );

      setState(() {
        _workouts.add(newEntry);
        _sortWorkouts();
      });
      _saveWorkouts();
      
      // Clear form but keep date
      _exerciseController.clear();
      _weightController.clear();
      _setsController.clear();
      _repsController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout logged!'),
          backgroundColor: Color(0xFF76FF03),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteWorkout(String id) {
    setState(() {
      _workouts.removeWhere((entry) => entry.id == id);
    });
    _saveWorkouts();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF76FF03),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NEON GYM LOG',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Color(0xFF76FF03),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildInputForm(),
                const Divider(height: 1, color: Colors.white24),
                Expanded(child: _buildWorkoutList()),
              ],
            ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Picker Row
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const Icon(Icons.calendar_today, color: Color(0xFF76FF03)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Exercise Name
            TextFormField(
              controller: _exerciseController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                prefixIcon: Icon(Icons.fitness_center, color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (value) => value!.isEmpty ? 'Enter exercise' : null,
            ),
            const SizedBox(height: 12),
            
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      suffixText: 'kg',
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sets'),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Add Button
            ElevatedButton(
              onPressed: _addWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF76FF03),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'LOG WORKOUT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutList() {
    if (_workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[800]),
            const SizedBox(height: 16),
            Text(
              'No workouts logged yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        final workout = _workouts[index];
        return Dismissible(
          key: Key(workout.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.redAccent,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) => _deleteWorkout(workout.id),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d').format(workout.date),
                        style: const TextStyle(
                          color: Color(0xFF76FF03),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                        onPressed: () => _deleteWorkout(workout.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    workout.exercise,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatBadge(Icons.fitness_center, '${workout.weight} kg'),
                      const SizedBox(width: 16),
                      _buildStatBadge(Icons.repeat, '${workout.sets} sets'),
                      const SizedBox(width: 16),
                      _buildStatBadge(Icons.numbers, '${workout.reps} reps'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00E5FF)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
