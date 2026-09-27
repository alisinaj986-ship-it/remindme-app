import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const RemindMeApp());
}

class Reminder {
  String title;
  DateTime date;
  TimeOfDay time;
  String category;
  String priority;
  String repeat;
  bool pinned;

  Reminder({
    required this.title,
    required this.date,
    required this.time,
    required this.category,
    required this.priority,
    required this.repeat,
    this.pinned = false,
  });
}

class Pet {
  String name;
  String emoji;
  int level;
  int xp;
  int happiness;
  int food;

  Pet({
    required this.name,
    required this.emoji,
    this.level = 1,
    this.xp = 0,
    this.happiness = 50,
    this.food = 0,
  });

  int get xpNeeded => level * 20;
}

class RemindMeApp extends StatefulWidget {
  const RemindMeApp({super.key});

  @override
  State<RemindMeApp> createState() => _RemindMeAppState();
}

class _RemindMeAppState extends State<RemindMeApp> {
  int selectedColor = 0;
  bool darkMode = false;

  final List<Color> colors = [
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RemindMe',
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorSchemeSeed: colors[selectedColor],
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: colors[selectedColor],
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: HomePage(
        color: colors[selectedColor],
        darkMode: darkMode,
        onColorChanged: (index) {
          setState(() {
            selectedColor = index;
          });
        },
        onDarkModeChanged: (value) {
          setState(() {
            darkMode = value;
          });
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Color color;
  final bool darkMode;
  final Function(int) onColorChanged;
  final Function(bool) onDarkModeChanged;

  const HomePage({
    super.key,
    required this.color,
    required this.darkMode,
    required this.onColorChanged,
    required this.onDarkModeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPage = 0;

  String userName = '';
  String petName = '';

  final List<Reminder> reminders = [];

  final Pet pet = Pet(
    name: 'Buddy',
    emoji: '🐶',
  );

  @override
  void initState() {
    super.initState();
    loadNames();
  }

  Future<void> loadNames() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUserName = prefs.getString('user_name');
    final savedPetName = prefs.getString('pet_name');

    if (!mounted) return;

    if (savedUserName == null || savedUserName.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showSetupDialog();
        }
      });
    } else {
      setState(() {
        userName = savedUserName;
        petName = savedPetName ?? 'Buddy';
        pet.name = petName;
      });
    }
  }

  Future<void> showSetupDialog() async {
    final userController = TextEditingController();
    final petController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('👋 Welcome to RemindMe!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Let’s set up your profile!',
              ),
              const SizedBox(height: 18),
              TextField(
                controller: userController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  hintText: 'Example: Alex',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: petController,
                decoration: const InputDecoration(
                  labelText: 'Pet name',
                  hintText: 'Example: Buddy',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                final newUserName = userController.text.trim();
                final newPetName = petController.text.trim();

                if (newUserName.isEmpty || newPetName.isEmpty) {
                  return;
                }

                final prefs = await SharedPreferences.getInstance();

                await prefs.setString(
                  'user_name',
                  newUserName,
                );

                await prefs.setString(
                  'pet_name',
                  newPetName,
                );

                if (!mounted) return;

                setState(() {
                  userName = newUserName;
                  petName = newPetName;
                  pet.name = newPetName;
                });

                Navigator.pop(context);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    userController.dispose();
    petController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildHome(),
      CalendarPage(reminders: reminders),
      SettingsPage(
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        onColorChanged: widget.onColorChanged,
        userName: userName,
        petName: petName,
        onNameChanged: changeUserName,
        onPetNameChanged: changePetName,
      ),
    ];

    return Scaffold(
      body: pages[currentPage],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPage,
        onDestinationSelected: (index) {
          setState(() {
            currentPage = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: currentPage == 0
          ? FloatingActionButton.extended(
              onPressed: addReminder,
              icon: const Icon(Icons.add),
              label: const Text('New Reminder'),
            )
          : null,
    );
  }

  Widget buildHome() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text(
              'RemindMe',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                onPressed: showColorPicker,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      userName.isEmpty
                          ? getGreeting()
                          : '${getGreeting()}, $userName 👋',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                widget.color.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.task_alt,
                              color: widget.color,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Reminders',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  reminders.isEmpty
                                      ? 'You are all caught up!'
                                      : '${reminders.length} reminder${reminders.length == 1 ? '' : 's'} left',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  PetCard(
                    pet: pet,
                    onFeed: feedPet,
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your Reminders',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          if (reminders.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 70,
                      color: widget.color,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No reminders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap "New Reminder" to create one.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return reminderCard(
                      reminders[index],
                    );
                  },
                  childCount: reminders.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget reminderCard(Reminder reminder) {
    Color priorityColor;

    switch (reminder.priority) {
      case 'High':
        priorityColor = Colors.red;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: Checkbox(
          value: false,
          onChanged: (_) {
            completeReminder(reminder);
          },
        ),
        title: Text(
          reminder.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${formatDate(reminder.date)} • ${reminder.time.format(context)}',
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        priorityColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    reminder.priority,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(reminder.category),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'pin') {
              setState(() {
                reminder.pinned = !reminder.pinned;
              });
            }

            if (value == 'delete') {
              setState(() {
                reminders.remove(reminder);
              });
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'pin',
              child: Row(
                children: [
                  Icon(
                    reminder.pinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    reminder.pinned
                        ? 'Unpin'
                        : 'Pin',
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void completeReminder(Reminder reminder) {
    setState(() {
      pet.xp += 10;
      pet.food += 1;
      pet.happiness += 5;

      if (pet.happiness > 100) {
        pet.happiness = 100;
      }

      if (pet.xp >= pet.xpNeeded) {
        pet.xp -= pet.xpNeeded;
        pet.level++;
      }

      reminders.remove(reminder);
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '🎉 Task Complete!',
          ),
          content: Text(
            '+10 XP\n'
            '+1 Food\n'
            '+5 Happiness\n\n'
            '$petName is happy! 🐶\n\n'
            'The reminder has been completed!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Awesome'),
            ),
          ],
        );
      },
    );
  }

  void feedPet() {
    if (pet.food <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '🐶 Complete a reminder first to earn food!',
          ),
        ),
      );
      return;
    }

    setState(() {
      pet.food--;
      pet.xp += 5;
      pet.happiness += 10;

      if (pet.happiness > 100) {
        pet.happiness = 100;
      }

      if (pet.xp >= pet.xpNeeded) {
        pet.xp -= pet.xpNeeded;
        pet.level++;
      }
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '🐶 $petName enjoyed the food! +5 XP +10 Happiness',
        ),
      ),
    );
  }

  Future<void> addReminder() async {
    final result = await Navigator.push<Reminder>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const NewReminderPage(),
      ),
    );

    if (result != null) {
      setState(() {
        reminders.add(result);
      });
    }
  }

  Future<void> changeUserName() async {
    final controller = TextEditingController(
      text: userName,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Change your name',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Your name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name =
                    controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(
                    context,
                    name,
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.isEmpty) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'user_name',
      newName,
    );

    if (!mounted) return;

    setState(() {
      userName = newName;
    });
  }

  Future<void> changePetName() async {
    final controller = TextEditingController(
      text: petName,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '🐾 Change pet name',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Pet name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pets),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name =
                    controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(
                    context,
                    name,
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.isEmpty) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'pet_name',
      newName,
    );

    if (!mounted) return;

    setState(() {
      petName = newName;
      pet.name = newName;
    });
  }

  void showColorPicker() {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 15,
            runSpacing: 15,
            children: List.generate(
              colors.length,
              (index) {
                return GestureDetector(
                  onTap: () {
                    widget.onColorChanged(
                      index,
                    );
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        colors[index],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 18) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onFeed;

  const PetCard({
    super.key,
    required this.pet,
    required this.onFeed,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        pet.xp / pet.xpNeeded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              pet.emoji,
              style: const TextStyle(
                fontSize: 50,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Level ${pet.level}',
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: progress.clamp(
                      0.0,
                      1.0,
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${pet.xp} / ${pet.xpNeeded} XP',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 16,
                        color: Colors.pink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pet.happiness}%',
                      ),
                      const SizedBox(width: 14),
                      const Text('🍖'),
                      const SizedBox(width: 4),
                      Text('${pet.food}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onFeed,
              child: const Text('Feed'),
            ),
          ],
        ),
      ),
    );
  }
}

class NewReminderPage extends StatefulWidget {
  const NewReminderPage({
    super.key,
  });

  @override
  State<NewReminderPage> createState() =>
      _NewReminderPageState();
}

class _NewReminderPageState
    extends State<NewReminderPage> {
  final titleController =
      TextEditingController();

  DateTime selectedDate =
      DateTime.now();

  TimeOfDay selectedTime =
      TimeOfDay.now();

  String category = 'Personal';
  String priority = 'Medium';
  String repeat = 'Never';

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Reminder',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: titleController,
            decoration:
                const InputDecoration(
              labelText:
                  'Reminder title',
              hintText:
                  'Example: Do homework',
              border:
                  OutlineInputBorder(),
              prefixIcon:
                  Icon(Icons.edit),
            ),
          ),

          const SizedBox(height: 18),

          ListTile(
            leading: const Icon(
              Icons.calendar_today,
            ),
            title: const Text('Date'),
            subtitle: Text(
              '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: pickDate,
          ),

          ListTile(
            leading: const Icon(
              Icons.access_time,
            ),
            title: const Text('Time'),
            subtitle: Text(
              selectedTime.format(
                context,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: pickTime,
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            initialValue: category,
            decoration:
                const InputDecoration(
              labelText: 'Category',
              border:
                  OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Personal',
                child:
                    Text('Personal'),
              ),
              DropdownMenuItem(
                value: 'School',
                child:
                    Text('School'),
              ),
              DropdownMenuItem(
                value: 'Work',
                child:
                    Text('Work'),
              ),
              DropdownMenuItem(
                value: 'Health',
                child:
                    Text('Health'),
              ),
              DropdownMenuItem(
                value: 'Other',
                child:
                    Text('Other'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  category = value;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: priority,
            decoration:
                const InputDecoration(
              labelText: 'Priority',
              border:
                  OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'High',
                child: Text('High'),
              ),
              DropdownMenuItem(
                value: 'Medium',
                child:
                    Text('Medium'),
              ),
              DropdownMenuItem(
                value: 'Low',
                child: Text('Low'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  priority = value;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: repeat,
            decoration:
                const InputDecoration(
              labelText: 'Repeat',
              border:
                  OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Never',
                child: Text('Never'),
              ),
              DropdownMenuItem(
                value: 'Daily',
                child: Text('Daily'),
              ),
              DropdownMenuItem(
                value: 'Weekly',
                child:
                    Text('Weekly'),
              ),
              DropdownMenuItem(
                value: 'Monthly',
                child:
                    Text('Monthly'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  repeat = value;
                });
              }
            },
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed: saveReminder,
              icon: const Icon(
                Icons.check,
              ),
              label: const Text(
                'Save Reminder',
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickDate() async {
    final picked =
        await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate:
          DateTime.now().add(
        const Duration(
          days: 3650,
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> pickTime() async {
    final picked =
        await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void saveReminder() {
    final title =
        titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a reminder title.',
          ),
        ),
      );
      return;
    }

    final reminder = Reminder(
      title: title,
      date: selectedDate,
      time: selectedTime,
      category: category,
      priority: priority,
      repeat: repeat,
    );

    Navigator.pop(
      context,
      reminder,
    );
  }
}

class CalendarPage extends StatelessWidget {
  final List<Reminder> reminders;

  const CalendarPage({
    super.key,
    required this.reminders,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            title: Text('Calendar'),
          ),
          SliverList(
            delegate:
                SliverChildBuilderDelegate(
              (context, index) {
                final date = DateTime(
                  today.year,
                  today.month,
                  today.day + index,
                );

                final dayReminders =
                    reminders.where((r) {
                  return r.date.year ==
                          date.year &&
                      r.date.month ==
                          date.month &&
                      r.date.day ==
                          date.day;
                }).toList();

                return Card(
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      '${weekdayName(date.weekday)}, '
                      '${date.month}/${date.day}/${date.year}',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${dayReminders.length} reminder'
                      '${dayReminders.length == 1 ? '' : 's'}',
                    ),
                    children:
                        dayReminders.isEmpty
                            ? const [
                                Padding(
                                  padding:
                                      EdgeInsets.all(16),
                                  child: Text(
                                    'No reminders',
                                  ),
                                ),
                              ]
                            : dayReminders
                                .map(
                                (reminder) {
                                  return ListTile(
                                    leading:
                                        const Icon(
                                      Icons
                                          .notifications_none,
                                    ),
                                    title: Text(
                                      reminder
                                          .title,
                                    ),
                                    subtitle:
                                        Text(
                                      reminder
                                          .time
                                          .format(
                                        context,
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                  ),
                );
              },
              childCount: 60,
            ),
          ),
        ],
      ),
    );
  }

  String weekdayName(int day) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return names[day - 1];
  }
}

class SettingsPage extends StatelessWidget {
  final bool darkMode;
  final Function(bool) onDarkModeChanged;
  final Function(int) onColorChanged;

  final String userName;
  final String petName;

  final VoidCallback onNameChanged;
  final VoidCallback onPetNameChanged;

  const SettingsPage({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.onColorChanged,
    required this.userName,
    required this.petName,
    required this.onNameChanged,
    required this.onPetNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),

          Text(
            'Settings',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
          ),

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.person_outline,
              ),
              title:
                  const Text('Your Name'),
              subtitle: Text(
                userName.isEmpty
                    ? 'Not set'
                    : userName,
              ),
              trailing:
                  const Icon(
                Icons.chevron_right,
              ),
              onTap: onNameChanged,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.pets,
              ),
              title:
                  const Text('Pet Name'),
              subtitle: Text(
                petName.isEmpty
                    ? 'Not set'
                    : petName,
              ),
              trailing:
                  const Icon(
                Icons.chevron_right,
              ),
              onTap: onPetNameChanged,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: SwitchListTile(
              secondary:
                  const Icon(
                Icons.dark_mode_outlined,
              ),
              title:
                  const Text('Dark Mode'),
              subtitle:
                  const Text(
                'Use a darker appearance',
              ),
              value: darkMode,
              onChanged:
                  onDarkModeChanged,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.palette_outlined,
              ),
              title:
                  const Text('App Color'),
              subtitle:
                  const Text(
                'Choose your RemindMe color',
              ),
              trailing:
                  const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                showColorPicker(
                  context,
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          const Card(
            child: ListTile(
              leading: Icon(
                Icons.notifications_outlined,
              ),
              title: Text(
                'Notifications',
              ),
              subtitle: Text(
                'Coming soon',
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Card(
            child: ListTile(
              leading: Icon(
                Icons.lock_outline,
              ),
              title: Text(
                'App Lock',
              ),
              subtitle: Text(
                'Coming soon',
              ),
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.info_outline,
              ),
              title: const Text(
                'About RemindMe',
              ),
              trailing:
                  const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName:
                      'RemindMe',
                  applicationVersion:
                      '1.0.2',
                  applicationIcon:
                      const Icon(
                    Icons
                        .notifications_active,
                  ),
                  children: const [
                    Text(
                      'A simple reminder app with a fun pet reward system.',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void showColorPicker(
    BuildContext context,
  ) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding:
              const EdgeInsets.all(20),
          child: Wrap(
            spacing: 15,
            runSpacing: 15,
            children:
                List.generate(
              colors.length,
              (index) {
                return GestureDetector(
                  onTap: () {
                    onColorChanged(
                      index,
                    );
                    Navigator.pop(
                      context,
                    );
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        colors[index],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}