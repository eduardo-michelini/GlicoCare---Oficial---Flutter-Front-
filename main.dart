import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:fl_chart/fl_chart.dart';
import 'languages.dart';
import 'suporte_telas.dart';

void main() {
  runApp(const GlicoCareApp());
}

class GlicoCareApp extends StatefulWidget {
  const GlicoCareApp({Key? key}) : super(key: key);

  static _GlicoCareAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_GlicoCareAppState>()!;

  @override
  State<GlicoCareApp> createState() => _GlicoCareAppState();
}

class _GlicoCareAppState extends State<GlicoCareApp> {
  ThemeMode _themeMode = ThemeMode.light;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlicoCare',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1E5A80),
        scaffoldBackgroundColor: const Color(0xFFF4F8FA),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF1E5A80),
          primary: const Color(0xFF1E5A80),
          secondary: const Color(0xFF53A4DC),
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E5A80),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF1E5A80).withOpacity(0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF53A4DC),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF1E5A80),
          primary: const Color(0xFF53A4DC),
          secondary: const Color(0xFF38BDF8),
          surface: const Color(0xFF1E293B),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});
}

class UserProfile {
  final String name;
  final String email;

  UserProfile({required this.name, required this.email});
}

class Medication {
  String id;
  String name;
  String schedule;
  int stock;
  int dailyDose;

  Medication({
    required this.id,
    required this.name,
    required this.schedule,
    required this.stock,
    required this.dailyDose,
  });

  int get daysRemaining => dailyDose > 0 ? (stock / dailyDose).floor() : 0;
  bool get isLowStock => daysRemaining <= 5;
}

class GlucoseReading {
  final double value;
  final DateTime time;
  final String period;

  GlucoseReading({required this.value, required this.time, required this.period});
}

class MealEntry {
  final String mealName;
  final int carbsInGrams;
  final DateTime time;

  MealEntry({required this.mealName, required this.carbsInGrams, required this.time});
}

class SymptomCheckIn {
  final String moodEmoji;
  final String fatigueLevel;
  final List<String> symptoms;
  final DateTime time;

  SymptomCheckIn({
    required this.moodEmoji,
    required this.fatigueLevel,
    required this.symptoms,
    required this.time,
  });
}

class Question {
  final String titleKey;
  final List<Option> options;

  Question({required this.titleKey, required this.options});
}

class Option {
  final String textKey;
  final String archetype;

  Option({required this.textKey, required this.archetype});
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  String currentLanguage = 'pt';
  String currentScreen = 'welcome';
  String userArchetype = 'Sem dados';
  int _selectedTab = 0;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  int _currentQuestionIndex = 0;
  final Map<String, int> _archetypeScores = {
    'ansioso': 0,
    'bravo': 0,
    'tranquilo': 0,
    'iniciante': 0,
  };

  final String _backendUrl = "http://localhost:3000/api/chat";

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Medication> _medications = [
    Medication(id: '1', name: 'Metformina 850mg', schedule: '08:00, 20:00', stock: 20, dailyDose: 2),
    Medication(id: '2', name: 'Insulina NPH', schedule: '22:00', stock: 3, dailyDose: 1),
  ];

  final List<GlucoseReading> _glucoseReadings = [
    GlucoseReading(value: 110, time: DateTime.now().subtract(const Duration(hours: 12)), period: 'Jejum'),
    GlucoseReading(value: 145, time: DateTime.now().subtract(const Duration(hours: 8)), period: 'Pós-Almoço'),
    GlucoseReading(value: 95, time: DateTime.now().subtract(const Duration(hours: 4)), period: 'Antes do Jantar'),
    GlucoseReading(value: 130, time: DateTime.now(), period: 'Pós-Jantar'),
  ];

  final List<MealEntry> _meals = [
    MealEntry(mealName: 'Almoço: Arroz integral, Feijão, Frango e Salada', carbsInGrams: 45, time: DateTime.now().subtract(const Duration(hours: 8))),
    MealEntry(mealName: 'Lanche: Maçã com aveia', carbsInGrams: 20, time: DateTime.now().subtract(const Duration(hours: 4))),
  ];

  final List<SymptomCheckIn> _checkIns = [
    SymptomCheckIn(moodEmoji: '😊', fatigueLevel: 'Baixo', symptoms: ['Nenhum'], time: DateTime.now().subtract(const Duration(hours: 10))),
  ];

  String _glucoseFilterPeriod = 'Dia';

  final List<ChatMessage> _messages = [];
  bool _isDianaTyping = false;

  final Map<String, String> _registeredUsers = {
    'admin@eurofarma.com': '12345678',
  };

  final Map<String, String> _userNames = {
    'admin@eurofarma.com': 'Administrador Eurofarma',
  };

  UserProfile? currentUser;

  final List<Question> _questions = [
    Question(
      titleKey: 'q1',
      options: [
        Option(textKey: 'q1_a', archetype: 'ansioso'),
        Option(textKey: 'q1_b', archetype: 'bravo'),
        Option(textKey: 'q1_c', archetype: 'tranquilo'),
        Option(textKey: 'q1_d', archetype: 'iniciante'),
      ],
    ),
    Question(
      titleKey: 'q2',
      options: [
        Option(textKey: 'q2_a', archetype: 'ansioso'),
        Option(textKey: 'q2_b', archetype: 'tranquilo'),
        Option(textKey: 'q2_c', archetype: 'bravo'),
        Option(textKey: 'q2_d', archetype: 'iniciante'),
      ],
    ),
    Question(
      titleKey: 'q3',
      options: [
        Option(textKey: 'q3_a', archetype: 'bravo'),
        Option(textKey: 'q3_b', archetype: 'tranquilo'),
        Option(textKey: 'q3_c', archetype: 'ansioso'),
        Option(textKey: 'q3_d', archetype: 'iniciante'),
      ],
    ),
    Question(
      titleKey: 'q4',
      options: [
        Option(textKey: 'q4_a', archetype: 'ansioso'),
        Option(textKey: 'q4_b', archetype: 'tranquilo'),
        Option(textKey: 'q4_c', archetype: 'bravo'),
        Option(textKey: 'q4_d', archetype: 'iniciante'),
      ],
    ),
    Question(
      titleKey: 'q5',
      options: [
        Option(textKey: 'q5_a', archetype: 'ansioso'),
        Option(textKey: 'q5_b', archetype: 'tranquilo'),
        Option(textKey: 'q5_c', archetype: 'bravo'),
        Option(textKey: 'q5_d', archetype: 'iniciante'),
      ],
    ),
    Question(
      titleKey: 'q6',
      options: [
        Option(textKey: 'q6_a', archetype: 'ansioso'),
        Option(textKey: 'q6_b', archetype: 'tranquilo'),
        Option(textKey: 'q6_c', archetype: 'bravo'),
        Option(textKey: 'q6_d', archetype: 'iniciante'),
      ],
    ),
    Question(
      titleKey: 'q7',
      options: [
        Option(textKey: 'q7_a', archetype: 'tranquilo'),
        Option(textKey: 'q7_b', archetype: 'ansioso'),
        Option(textKey: 'q7_c', archetype: 'bravo'),
        Option(textKey: 'q7_d', archetype: 'iniciante'),
      ],
    ),
    Question(
      titleKey: 'q8',
      options: [
        Option(textKey: 'q8_a', archetype: 'tranquilo'),
        Option(textKey: 'q8_b', archetype: 'ansioso'),
        Option(textKey: 'q8_c', archetype: 'bravo'),
        Option(textKey: 'q8_d', archetype: 'iniciante'),
      ],
    ),
    Question(
      titleKey: 'q9',
      options: [
        Option(textKey: 'q9_a', archetype: 'ansioso'),
        Option(textKey: 'q9_b', archetype: 'bravo'),
        Option(textKey: 'q9_c', archetype: 'tranquilo'),
        Option(textKey: 'q9_d', archetype: 'iniciante'),
      ],
    ),
    Question(
      titleKey: 'q10',
      options: [
        Option(textKey: 'q10_a', archetype: 'iniciante'),
        Option(textKey: 'q10_b', archetype: 'tranquilo'),
        Option(textKey: 'q10_c', archetype: 'ansioso'),
        Option(textKey: 'q10_d', archetype: 'bravo'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _resetChat();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: currentLanguage == 'pt' ? 'pt_BR' : 'en_US',
          onResult: (val) {
            setState(() {
              _chatController.text = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildAppLogo({double height = 80}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Image.asset(
          'assets/glicocare_logo.png',
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Future<void> _launchEurofarmaUrl() async {
    final Uri url = Uri.parse('https://eurofarma.com.br/');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _showSnackBar("Não foi possível abrir o site da Eurofarma.");
      }
    } catch (e) {
      _showSnackBar("Erro ao tentar abrir o link.");
    }
  }

  Future<void> _launchEurocuidaUrl() async {
    final Uri url = Uri.parse('https://eurocuida.com.br/');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _showSnackBar("Não foi possível abrir o site do Eurocuida.");
      }
    } catch (e) {
      _showSnackBar("Erro ao tentar abrir o link.");
    }
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: _getText('dianaGreeting'),
        isUser: false,
      ));
    });
  }

  void _restartOnboarding() {
    setState(() {
      _currentQuestionIndex = 0;
      _archetypeScores.updateAll((key, value) => 0);
      currentScreen = 'quiz_intro';
    });
  }

  void _takeDose(Medication med) {
    if (med.stock <= 0) {
      _showSnackBar(_getText('stockEmpty').replaceAll('{name}', med.name));
      return;
    }

    setState(() {
      med.stock = (med.stock - med.dailyDose).clamp(0, 99999);
    });

    _showSnackBar(_getText('doseRecorded').replaceAll('{stock}', med.stock.toString()));
  }

  void _clearAllMedications() {
    setState(() {
      _medications.clear();
    });
    _showSnackBar(_getText('clearAllMeds'));
  }

  String _getText(String key) {
    return AppTranslations.values[currentLanguage]?[key] ?? 
           AppTranslations.values['pt']?[key] ?? 
           key;
  }

  String _localizedProfile(String profile) {
    final normalized = profile.toLowerCase();
    if (normalized.contains('ansios')) return _getText('profileAnxious');
    if (normalized.contains('irrit') || normalized.contains('brav')) return _getText('profileIrritated');
    if (normalized.contains('tranquil') || normalized.contains('calm')) return _getText('profileCalm');
    if (normalized.contains('iniciante') || normalized.contains('beginner')) return _getText('profileBeginner');
    if (normalized.contains('sem dados') || normalized.contains('no data')) return _getText('profileNoData');
    return profile;
  }

  String _localizedSymptom(String symptom) {
    switch (symptom) {
      case 'Tontura': case 'Dizziness': return _getText('symptomDizziness');
      case 'Suor Frio': case 'Cold Sweat': return _getText('symptomColdSweat');
      case 'Sede Excessiva': case 'Excessive Thirst': return _getText('symptomExcessiveThirst');
      case 'Visão Turva': case 'Blurred Vision': return _getText('symptomBlurredVision');
      case 'Fome Excessiva': case 'Excessive Hunger': return _getText('symptomExcessiveHunger');
      case 'Fadiga': case 'Fatigue': return _getText('symptomFatigue');
      case 'Nenhum': case 'None': return _getText('none');
      default: return symptom;
    }
  }

  String _localizedMealName(String mealName) {
    if (mealName == 'Almoço: Arroz integral, Feijão, Frango e Salada') return _getText('sampleLunch');
    if (mealName == 'Lanche: Maçã com aveia') return _getText('sampleSnack');
    return mealName;
  }

  void _showNotificationPermissionDialog() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(_getText('notifTitle'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80))),
          content: Text(_getText('notifBody'), style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackBar(_getText('notificationsOff'));
              },
              child: Text(_getText('deny'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackBar(_getText('notificationsOn'));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_getText('allow'), style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _handleLogin() {
    final user = _userController.text.trim();
    final password = _passwordController.text;

    if (user.isEmpty || password.isEmpty) {
      _showSnackBar(_getText('errorEmpty'));
      return;
    }

    if (_registeredUsers.containsKey(user) && _registeredUsers[user] == password) {
      setState(() {
        currentUser = UserProfile(
          name: _userNames[user] ?? 'Usuário GlicoCare',
          email: user,
        );
        currentScreen = 'dashboard';
      });
      _userController.clear();
      _passwordController.clear();
    } else {
      _showSnackBar(_getText('errorAuth'));
    }
  }

  void _handleRegister() {
    final name = _nameController.text.trim();
    final email = _userController.text.trim();
    final password = _passwordController.text;

    if (name.length < 3 || name.length > 70) {
      _showSnackBar(_getText('nameLengthError'));
      return;
    }

    if (email.length < 6 || email.length > 254) {
      _showSnackBar(_getText('emailLengthError'));
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar(_getText('emailInvalidError'));
      return;
    }

    if (password.length < 8 || password.length > 128) {
      _showSnackBar(_getText('passwordLengthError'));
      return;
    }

    setState(() {
      _registeredUsers[email] = password;
      _userNames[email] = name;
      _currentQuestionIndex = 0;
      currentUser = UserProfile(name: name, email: email);
      currentScreen = 'quiz_intro';
    });

    _showSnackBar(_getText('successRegister'));
    _passwordController.clear();
    _nameController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNotificationPermissionDialog();
    });
  }

  void _checkGlucoseAlert(double value) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (value < 70) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getText('hypoTitle'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            _getText('hypoBody').replaceAll('{value}', value.toInt().toString()),
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_getText('understood'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (value > 180) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getText('hyperTitle'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            _getText('hyperBody').replaceAll('{value}', value.toInt().toString()),
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_getText('understood'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _showAddGlucoseDialog() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final valueCtrl = TextEditingController();
    String selectedPeriod = _getText('fasting');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text(_getText('glucoseTitle'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: valueCtrl, 
                    keyboardType: TextInputType.number, 
                    decoration: InputDecoration(
                      hintText: _getText('glucoseHint'), 
                      labelText: _getText('glucoseLabel'),
                    )
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPeriod,
                    decoration: InputDecoration(labelText: _getText('periodLabel')),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    items: [_getText('fasting'), _getText('preMeal'), _getText('postLunch'), _getText('postDinner'), _getText('beforeSleep'), _getText('overnight')]
                        .map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedPeriod = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_getText('close'))),
                ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(valueCtrl.text.trim());
                    if (val != null && val >= 0 && val <= 5000) {
                      setState(() {
                        _glucoseReadings.add(GlucoseReading(value: val, time: DateTime.now(), period: selectedPeriod));
                      });
                      Navigator.of(context).pop();
                      _showSnackBar(_getText('glucoseSaved').replaceAll('{value}', val.toInt().toString()));
                      _checkGlucoseAlert(val);
                    } else {
                      _showSnackBar(_getText('glucoseInvalid'));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_getText('save'), style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showAddMealDialog() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final mealCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(_getText('mealTitle'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: mealCtrl, decoration: InputDecoration(hintText: _getText('mealHint'), labelText: _getText('mealQuestion'))),
              const SizedBox(height: 10),
              TextField(controller: carbsCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: _getText('carbsHint'), labelText: _getText('carbsLabel'))),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getText('medicalWarning'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_getText('close'))),
            ElevatedButton(
              onPressed: () {
                final meal = mealCtrl.text.trim();
                final carbs = int.tryParse(carbsCtrl.text.trim()) ?? 0;
                if (meal.isNotEmpty) {
                  setState(() {
                    _meals.add(MealEntry(mealName: meal, carbsInGrams: carbs, time: DateTime.now()));
                  });
                  Navigator.of(context).pop();
                  _showSnackBar(_getText('mealSaved'));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_getText('save'), style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  void _showAddCheckInDialog() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedEmoji = '😊';
    String selectedFatigue = 'low';
    List<String> selectedSymptoms = [];

    final List<String> availableSymptoms = ['symptomDizziness', 'symptomColdSweat', 'symptomExcessiveThirst', 'symptomBlurredVision', 'symptomExcessiveHunger', 'symptomFatigue'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text(_getText('checkinTitle'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getText('feelingQuestion'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['😄', '😊', '😐', '🙁', '😫'].map((emoji) {
                        final isSel = selectedEmoji == emoji;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedEmoji = emoji),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel ? (isDark ? const Color(0xFF38BDF8).withOpacity(0.3) : const Color(0xFF1E5A80).withOpacity(0.2)) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 26)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(_getText('fatigueLevel'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: ['low', 'medium', 'high'].map((level) {
                        final isSel = selectedFatigue == level;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text(_getText(level)),
                              selected: isSel,
                              onSelected: (val) {
                                if (val) setDialogState(() => selectedFatigue = level);
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(_getText('symptomsPresented'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: availableSymptoms.map((symptom) {
                        final isSel = selectedSymptoms.contains(symptom);
                        return FilterChip(
                          label: Text(_getText(symptom), style: const TextStyle(fontSize: 11)),
                          selected: isSel,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                selectedSymptoms.add(symptom);
                              } else {
                                selectedSymptoms.remove(symptom);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_getText('close'))),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _checkIns.add(SymptomCheckIn(
                        moodEmoji: selectedEmoji,
                        fatigueLevel: selectedFatigue,
                        symptoms: selectedSymptoms.isEmpty ? ['none'] : selectedSymptoms,
                        time: DateTime.now(),
                      ));
                    });
                    Navigator.of(context).pop();
                    _showSnackBar(_getText('checkinSaved'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_getText('save'), style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showAddMedicationDialog() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    final schedCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final dailyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(_getText('addMed'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(hintText: _getText('medName'))),
              const SizedBox(height: 10),
              TextField(controller: schedCtrl, decoration: InputDecoration(hintText: _getText('medSchedule'))),
              const SizedBox(height: 10),
              TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: _getText('medStock'))),
              const SizedBox(height: 10),
              TextField(controller: dailyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: _getText('medDaily'))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_getText('close')),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final sched = schedCtrl.text.trim();
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
                final daily = int.tryParse(dailyCtrl.text.trim()) ?? 1;

                if (name.isNotEmpty) {
                  setState(() {
                    _medications.add(Medication(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      schedule: sched.isEmpty ? '12:00' : sched,
                      stock: stock,
                      dailyDose: daily,
                    ));
                  });
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_getText('save'), style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  void _showEditMedicationDialog(Medication med) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: med.name);
    final schedCtrl = TextEditingController(text: med.schedule);
    final stockCtrl = TextEditingController(text: med.stock.toString());
    final dailyCtrl = TextEditingController(text: med.dailyDose.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(_getText('editMedication'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(hintText: _getText('medName'), labelText: _getText('medName'))),
              const SizedBox(height: 10),
              TextField(controller: schedCtrl, decoration: InputDecoration(hintText: _getText('medSchedule'), labelText: _getText('medSchedule'))),
              const SizedBox(height: 10),
              TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: _getText('medStock'), labelText: _getText('medStock'))),
              const SizedBox(height: 10),
              TextField(controller: dailyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: _getText('medDaily'), labelText: _getText('medDaily'))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_getText('close')),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final sched = schedCtrl.text.trim();
                final stock = int.tryParse(stockCtrl.text.trim()) ?? med.stock;
                final daily = int.tryParse(dailyCtrl.text.trim()) ?? med.dailyDose;

                if (name.isNotEmpty) {
                  setState(() {
                    med.name = name;
                    med.schedule = sched;
                    med.stock = stock;
                    med.dailyDose = daily;
                  });
                }
                Navigator.of(context).pop();
                _showSnackBar(_getText('stockUpdated').replaceAll('{name}', med.name));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_getText('save'), style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  void _showUserProfileDialog() {
    final isDark = GlicoCareApp.of(context).isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool currentIsDark = Theme.of(context).brightness == Brightness.dark;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: currentIsDark ? const Color(0xFF1E293B) : Colors.white,
              child: Container(
                padding: const EdgeInsets.all(28),
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: currentIsDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: (currentIsDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80)).withOpacity(0.15),
                        child: Icon(
                          Icons.person,
                          size: 65,
                          color: currentIsDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentUser?.name ?? 'Usuário',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: currentIsDark ? Colors.white : const Color(0xFF1E5A80),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentUser?.email ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: currentIsDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF53A4DC).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getText('profileLabel').replaceAll('{profile}', _localizedProfile(userArchetype)),
                        style: TextStyle(
                          color: currentIsDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80), 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentIsDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: currentIsDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentIsDark ? _getText('modeDarkActive') : _getText('modeLightActive'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: currentIsDark ? Colors.white : const Color(0xFF1E5A80),
                            ),
                          ),
                          Tooltip(
                            message: isDark ? _getText('modeDark') : _getText('modeLight'),
                            child: IconButton(
                              icon: Icon(
                                isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                                color: isDark ? const Color(0xFF38BDF8) : Colors.amber.shade700,
                              ),
                              onPressed: () {
                                GlicoCareApp.of(context).toggleTheme(!isDark);
                                setDialogState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _restartOnboarding();
                      },
                      icon: const Icon(Icons.quiz_outlined, size: 18),
                      label: Text(_getText('profileRetake')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: currentIsDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                        side: BorderSide(color: currentIsDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentIsDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _getText('close'), 
                          style: TextStyle(
                            color: currentIsDark ? Colors.black : Colors.white, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(
              child: Text(
                text, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ],
        ), 
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleSendMessage([String? directText]) async {
    final String userText = (directText ?? _chatController.text).trim();
    if (userText.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true));
      if (directText == null) _chatController.clear();
      _isDianaTyping = true;
    });
    _scrollToBottom();

    Map<String, String> toneGuidance = {
      'ansioso': 'O usuário é bastante ansioso. Responda de forma extremamente acolhedora, calma e tranquilizadora. Evite qualquer tom alarmista.',
      'bravo': 'O usuário se frustra facilmente com a rotina. Responda de forma leve, direta, sem dar broncas e focada em incentivos positivos.',
      'tranquilo': 'O usuário é pragmático e direto. Responda com foco em dados, de forma objetiva e em tópicos claros.',
      'iniciante': 'O usuário está aprendendo agora sobre o diabetes. Explique os conceitos passo a passo com linguagem bem acessível.',
      'Sem dados sobre o tipo de pessoa': 'Responda de forma tradicional, equilibrada, acolhedora, objetiva e clara.',
    };

    final String archetypeKey = toneGuidance.containsKey(userArchetype) ? userArchetype : 'Sem dados sobre o tipo de pessoa';

    final String baseRule = '''
Você é a Diana, assistente virtual de saúde do app GlicoCare da Eurofarma.
Regra de Ouro: NUNCA prescreva medicamentos. Mantenha conduta cautelosa e educativa.
Adaptação de tom: ${toneGuidance[archetypeKey]}

INSTRUÇÃO DE AÇÃO NO APP:
Quando o usuário solicitar o cadastro/adição de um medicamento e fornecer o nome, horário, estoque e dose diária, responda EXCLUSIVAMENTE em formato JSON puro conforme o exemplo:
{
  "action": "add_medication",
  "name": "Nome do Remédio",
  "schedule": "08:00, 20:00",
  "stock": 30,
  "dailyDose": 2,
  "reply": "Cadastrei a Dipirona para você com sucesso!"
}
''';

    try {
      List<Map<String, String>> conversationHistory = [
        {"role": "system", "content": baseRule},
        ..._messages.map((msg) => {
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text,
        }),
      ];

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({"messages": conversationHistory}),
      );

      setState(() {
        _isDianaTyping = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String aiResponse = data['response'] ?? 'Sem resposta do servidor.';
        
        setState(() {
          _messages.add(ChatMessage(text: aiResponse, isUser: false));

          if (data['medication'] != null) {
            final med = data['medication'];
            _medications.add(Medication(
              id: med['id'].toString(),
              name: med['name'],
              schedule: med['schedule'],
              stock: med['stock'],
              dailyDose: med['dailyDose'],
            ));
            _showSnackBar(_getText('newMedicationAdded'));
          }
        });
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String errorMessage = data['error'] ?? "Erro no servidor (Status ${response.statusCode})";
        setState(() {
          _messages.add(ChatMessage(text: errorMessage, isUser: false));
        });
      }
    } catch (e) {
      setState(() {
        _isDianaTyping = false;
        _messages.add(ChatMessage(text: "Erro ao conectar com o servidor local: $e", isUser: false));
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildCurrentScreen() {
    switch (currentScreen) {
      case 'welcome':
        return WelcomeScreen(
          appLogo: _buildAppLogo(height: 120),
          welcomeText: _getText('welcomeMsg'),
          startBtnText: _getText('startBtn'),
          onStartPressed: () => setState(() {
            currentScreen = 'login';
          }),
        );

      case 'quiz_intro':
        return QuizIntroScreen(
          getText: _getText,
          onStartQuiz: () {
            setState(() {
              _currentQuestionIndex = 0;
              currentScreen = 'onboarding';
            });
          },
          onSkipQuiz: () {
            setState(() {
              userArchetype = 'Sem dados sobre o tipo de pessoa';
              currentScreen = 'dashboard';
            });
          },
        );

      case 'onboarding':
        return _buildOnboardingScreen();

      case 'dashboard':
        return _buildDashboard();

      case 'register':
      case 'login':
      default:
        return ResponsiveAuthScreen(
          isRegister: currentScreen == 'register',
          appLogo: _buildAppLogo(height: 44),
          nameController: _nameController,
          emailController: _userController,
          passwordController: _passwordController,
          currentLanguage: currentLanguage,
          onLanguageChanged: (String value) {
            setState(() {
              currentLanguage = value;
              _resetChat();
            });
          },
          onSubmit: currentScreen == 'register' ? _handleRegister : _handleLogin,
          onToggleAuthMode: () {
            setState(() {
              currentScreen = currentScreen == 'register' ? 'login' : 'register';
              _userController.clear();
              _passwordController.clear();
            });
          },
          getText: _getText,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildOnboardingScreen() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF1E5A80),
        elevation: 0,
        title: Text(
          "${_getText('questionTitle')} (${_currentQuestionIndex + 1}/${_questions.length})",
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(isDark ? const Color(0xFF38BDF8) : const Color(0xFF53A4DC)),
            ),
            const SizedBox(height: 30),
            Text(
              _getText(question.titleKey),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, idx) {
                  final opt = question.options[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: isDark ? Colors.white : const Color(0xFF1E5A80),
                        padding: const EdgeInsets.all(18),
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                        elevation: 1,
                      ),
                      onPressed: () {
                        _archetypeScores[opt.archetype] = (_archetypeScores[opt.archetype] ?? 0) + 1;
                        if (_currentQuestionIndex < _questions.length - 1) {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        } else {
                          String topArchetype = 'tranquilo';
                          int highest = -1;
                          _archetypeScores.forEach((key, val) {
                            if (val > highest) {
                              highest = val;
                              topArchetype = key;
                            }
                          });
                          setState(() {
                            userArchetype = topArchetype;
                            currentScreen = currentUser == null ? 'login' : 'dashboard';
                          });
                        }
                      },
                      child: Text(
                        _getText(opt.textKey),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    Widget themeAction() => IconButton(
      tooltip: isDark ? _getText('modeDark') : _getText('modeLight'),
      icon: Icon(isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
        color: isDark ? const Color(0xFF38BDF8) : Colors.amber.shade300),
      onPressed: () => GlicoCareApp.of(context).toggleTheme(!isDark),
    );

    Widget profileAction() => IconButton(
      tooltip: _getText('profileTitle'),
      icon: CircleAvatar(
        radius: 15,
        backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF53A4DC),
        child: Icon(Icons.person, color: isDark ? Colors.black : Colors.white, size: 18),
      ),
      onPressed: _showUserProfileDialog,
    );

    Widget brandAction({required String asset, required String tooltip, required VoidCallback onTap}) => IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: asset == 'assets/eurofarma_logo.png'
            ? ClipOval(
                child: Image.asset(asset, height: 25, width: 25, fit: BoxFit.cover),
              )
            : Image.asset(asset, height: 25, width: 25, fit: BoxFit.contain),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF1E5A80),
        titleSpacing: isMobile ? 12 : 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAppLogo(height: isMobile ? 28 : 32),
            SizedBox(width: isMobile ? 6 : 10),
            Flexible(child: Text('GlicoCare', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: isMobile ? 16 : 18))),
          ],
        ),
        actions: isMobile
          ? [
              themeAction(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'profile') _showUserProfileDialog();
                  if (value == 'eurocuida') _launchEurocuidaUrl();
                  if (value == 'eurofarma') _launchEurofarmaUrl();
                  if (value == 'logout') setState(() { currentScreen = 'welcome'; _resetChat(); });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'profile', child: Text(_getText('profileTitle'))),
                  const PopupMenuItem(value: 'eurocuida', child: Text('Eurocuida')),
                  const PopupMenuItem(value: 'eurofarma', child: Text('Eurofarma')),
                  PopupMenuItem(value: 'logout', child: Text(_getText('logout'))),
                ],
              ),
              const SizedBox(width: 4),
            ]
          : [
              themeAction(),
              profileAction(),
              brandAction(asset: 'assets/eurocuida_logo.png', tooltip: 'Eurocuida', onTap: _launchEurocuidaUrl),
              brandAction(asset: 'assets/eurofarma_logo.png', tooltip: 'Eurofarma', onTap: _launchEurofarmaUrl),
              IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFFD0E3F0)),
                onPressed: () => setState(() { currentScreen = 'welcome'; _resetChat(); })),
              const SizedBox(width: 8),
            ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildMainChatAndMedsTab(),
          _buildGlucoseAndMealsTab(),
          _buildSymptomsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        iconSize: 22,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        currentIndex: _selectedTab,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        selectedItemColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
        unselectedItemColor: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        onTap: (idx) => setState(() => _selectedTab = idx),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline), activeIcon: const Icon(Icons.chat), label: _getText('navAssistant')),
          BottomNavigationBarItem(icon: const Icon(Icons.show_chart_rounded), activeIcon: const Icon(Icons.analytics_rounded), label: _getText('navGlucoseMeals')),
          BottomNavigationBarItem(icon: const Icon(Icons.emoji_emotions_outlined), activeIcon: const Icon(Icons.emoji_emotions), label: _getText('navSymptomsWellbeing')),
        ],
      ),
    );
  }

  Widget _buildMainChatAndMedsTab() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      child: Column(
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: const Color(0xFF53A4DC).withOpacity(0.2), shape: BoxShape.circle),
                      child: Icon(Icons.medication_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80), size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_getText('medReminder'), maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E5A80)))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (_medications.isNotEmpty)
                      Expanded(child: OutlinedButton.icon(
                        onPressed: _clearAllMedications,
                        icon: const Icon(Icons.delete_sweep, size: 16),
                        label: Text(_getText('medicationsClearAll'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626), padding: const EdgeInsets.symmetric(horizontal: 6), visualDensity: VisualDensity.compact),
                      )),
                    if (_medications.isNotEmpty) const SizedBox(width: 8),
                    Expanded(child: ElevatedButton.icon(
                      onPressed: _showAddMedicationDialog,
                      icon: Icon(Icons.add, size: 16, color: isDark ? Colors.black : Colors.white),
                      label: Text(_getText('addMed'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80), padding: const EdgeInsets.symmetric(horizontal: 6), visualDensity: VisualDensity.compact),
                    )),
                  ],
                ),
              ],
            )
          else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF53A4DC).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medication_rounded, 
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80), 
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getText('medReminder'), 
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : const Color(0xFF1E5A80),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (_medications.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearAllMedications,
                      icon: const Icon(Icons.delete_sweep, size: 16, color: Color(0xFFDC2626)),
                      label: Text(
                        _getText('medicationsClearAll'),
                        style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: _showAddMedicationDialog,
                    icon: Icon(Icons.add, size: 16, color: isDark ? Colors.black : Colors.white),
                    label: Text(
                      _getText('addMed'), 
                      style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          SizedBox(
            height: isMobile ? 178 : 185,
            child: _medications.isEmpty
                ? Center(child: Text(_getText('addMed'), style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _medications.length,
                    itemBuilder: (context, index) {
                      final med = _medications[index];
                      return Container(
                        width: isMobile ? (screenWidth - 32).clamp(260.0, 420.0).toDouble() : 270.0,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: med.isLowStock 
                                ? (isDark ? [const Color(0xFF451220), const Color(0xFF1E293B)] : [const Color(0xFFFFF1F2), Colors.white])
                                : (isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFFF8FAFC), Colors.white]),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: med.isLowStock 
                                ? const Color(0xFFE11D48).withOpacity(0.5) 
                                : (isDark ? Colors.white12 : const Color(0xFF53A4DC).withOpacity(0.25)),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    med.name, 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 15, 
                                      color: isDark ? Colors.white : const Color(0xFF1E5A80),
                                    ), 
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.edit_outlined, size: 18, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80)),
                                      onPressed: () => _showEditMedicationDialog(med),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                      onPressed: () {
                                        setState(() {
                                          _medications.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  med.schedule, 
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Text(
                              med.isLowStock
                                  ? "${_getText('stockRemaining').replaceAll('{stock}', med.stock.toString()).replaceAll('{days}', med.daysRemaining.toString())}"
                                  : "${_getText('stockCount').replaceAll('{stock}', med.stock.toString()).replaceAll('{days}', med.daysRemaining.toString())}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: med.isLowStock 
                                    ? const Color(0xFFFB7185) 
                                    : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80)),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton.icon(
                                onPressed: () => _takeDose(med),
                                icon: Icon(Icons.check_circle_outline, size: 16, color: isDark ? Colors.black : Colors.white),
                                label: Text(
                                  _getText('takeDose'),
                                  style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: isMobile ? 8 : 16),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 20, vertical: isMobile ? 10 : 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E5A80),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Color(0xFF53A4DC), shape: BoxShape.circle),
                              child: const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFF164360),
                                child: Icon(Icons.smart_toy_rounded, color: Color(0xFF53A4DC), size: 20),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E5A80), width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_getText('dianaTitle'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              if (!isMobile || screenWidth >= 380)
                                Text(_getText('dianaSub'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFD0E3F0), fontSize: 10)),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 40),
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                          tooltip: _getText('clearChat'),
                          onPressed: _resetChat,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 40),
                          icon: const Icon(Icons.quiz_outlined, color: Colors.white70, size: 20),
                          tooltip: "Refazer questionário de perfil",
                          onPressed: _restartOnboarding,
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(isMobile ? 12 : 20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return Align(
                          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12, left: msg.isUser ? (isMobile ? 24 : 50) : 0, right: msg.isUser ? 0 : (isMobile ? 24 : 50)),
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: msg.isUser 
                                  ? (isDark 
                                      ? const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0369A1)]) 
                                      : const LinearGradient(colors: [Color(0xFF1E5A80), Color(0xFF164360)]))
                                  : null,
                              color: msg.isUser 
                                  ? null 
                                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F8FA)),
                              borderRadius: BorderRadius.circular(18).copyWith(
                                bottomRight: msg.isUser ? Radius.zero : const Radius.circular(18),
                                bottomLeft: msg.isUser ? const Radius.circular(18) : Radius.zero,
                              ),
                            ),
                            child: MarkdownBody(
                              data: msg.text.replaceAll('<br>', '\n'),
                              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                p: TextStyle(
                                  color: msg.isUser 
                                      ? Colors.white 
                                      : (isDark ? Colors.white : const Color(0xFF1E5A80)),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (_isDianaTyping)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _getText('dianaThinking'),
                          style: const TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic, fontSize: 12),
                        ),
                      ),
                    ),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickChip(_getText('chip1')),
                          _buildQuickChip(_getText('chip2')),
                          _buildQuickChip(_getText('chip3')),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(isMobile ? 6 : 14, 4, isMobile ? 6 : 14, isMobile ? 8 : 14),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80)),
                          ),
                          onPressed: _listen,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            onSubmitted: (_) => _handleSendMessage(),
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              hintText: _getText('dianaChatPlaceholder'),
                              hintStyle: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF94A3B8), fontSize: 13),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28), 
                                borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28), 
                                borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.send_rounded, color: isDark ? Colors.black : Colors.white, size: 20),
                            onPressed: () => _handleSendMessage(),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGlucoseColor(double value) {
    if (value < 70) {
      return Colors.green;
    } else if (value > 180) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }

  List<LineChartBarData> _buildGlucoseLineBars() {
    if (_glucoseReadings.length < 2) {
      if (_glucoseReadings.isEmpty) return [];
      final singleVal = _glucoseReadings.first.value;
      final singleColor = _getGlucoseColor(singleVal);
      return [
        LineChartBarData(
          spots: [FlSpot(0, singleVal)],
          color: singleColor,
          barWidth: 3,
          isCurved: false,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 5,
                color: singleColor,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              );
            },
          ),
        )
      ];
    }

    List<LineChartBarData> bars = [];

    for (int i = 0; i < _glucoseReadings.length - 1; i++) {
      final p1 = FlSpot(i.toDouble(), _glucoseReadings[i].value);
      final p2 = FlSpot((i + 1).toDouble(), _glucoseReadings[i + 1].value);

      final avgVal = (_glucoseReadings[i].value + _glucoseReadings[i + 1].value) / 2;
      final segmentColor = _getGlucoseColor(avgVal);

      bars.add(
        LineChartBarData(
          spots: [p1, p2],
          isCurved: true,
          color: segmentColor,
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              Color dotColor = _getGlucoseColor(spot.y);
              return FlDotCirclePainter(
                radius: 4.5,
                color: dotColor,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: segmentColor.withOpacity(0.12),
          ),
        ),
      );
    }

    return bars;
  }

  Widget _buildGlucoseAndMealsTab() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double lastGlucose = _glucoseReadings.isNotEmpty ? _glucoseReadings.last.value : 0;
    String status = _getText('normalRange');
    Color statusColor = Colors.blue;
    if (lastGlucose < 70) {
      status = _getText('hypoglycemia');
      statusColor = Colors.green;
    } else if (lastGlucose > 180) {
      status = _getText('hyperglycemia');
      statusColor = Colors.red;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getText('glucoseHistory'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80))),
                    Row(
                      children: ['Dia', 'Semana', 'Mês'].map((p) {
                        final isSel = _glucoseFilterPeriod == p;
                        return GestureDetector(
                          onTap: () => setState(() => _glucoseFilterPeriod = p),
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80)) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              p, 
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                color: isSel ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white60 : Colors.black54),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getText('lastReading'), style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
                        Row(
                          children: [
                            Text("${lastGlucose.toInt()}", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E5A80))),
                            const SizedBox(width: 4),
                            const Text("mg/dL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 40),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true, 
                            reservedSize: 32,
                            interval: 40,
                            getTitlesWidget: (val, meta) => Text("${val.toInt()}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              int idx = val.toInt();
                              if (idx >= 0 && idx < _glucoseReadings.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text("${_glucoseReadings[idx].time.hour}h", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: _buildGlucoseLineBars(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddGlucoseDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(_getText('newGlucoseRecord')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_getText('mealsCarbs'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80))),
              IconButton(
                icon: Icon(Icons.add_circle, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80)),
                onPressed: _showAddMealDialog,
              )
            ],
          ),
          const SizedBox(height: 8),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _meals.length,
            itemBuilder: (context, idx) {
              final meal = _meals[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF53A4DC).withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(Icons.restaurant, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80), size: 20),
                  ),
                  title: Text(_localizedMealName(meal.mealName), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("${meal.time.hour.toString().padLeft(2, '0')}:${meal.time.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text("${meal.carbsInGrams}g ${_getText('carbsShort')}", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80), fontSize: 12)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsTab() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getText('wellbeingCheckin'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80))),
                          Text(_getText('wellbeingSubtitle'), style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddCheckInDialog,
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: Text(_getText('dailyCheckin')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(_getText('recordHistory'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80))),
          const SizedBox(height: 12),

          Expanded(
            child: _checkIns.isEmpty
                ? Center(child: Text(_getText('noCheckins')))
                : ListView.builder(
                    itemCount: _checkIns.length,
                    itemBuilder: (context, idx) {
                      final item = _checkIns[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(item.moodEmoji, style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${_getText('fatigue')}: ${_getText(item.fatigueLevel == 'Baixo' || item.fatigueLevel == 'low' ? 'low' : item.fatigueLevel == 'Médio' || item.fatigueLevel == 'medium' ? 'medium' : 'high')}",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "${item.time.day}/${item.time.month}${['zh', 'ko', 'ja'].contains(currentLanguage) ? ' ' : ' ${_getText('dateAt')} '}${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: item.symptoms.map((symp) {
                                  return Chip(
                                    label: Text(_localizedSymptom(symp == 'symptomDizziness' ? 'Tontura' : symp == 'symptomColdSweat' ? 'Suor Frio' : symp == 'symptomExcessiveThirst' ? 'Sede Excessiva' : symp == 'symptomBlurredVision' ? 'Visão Turva' : symp == 'symptomExcessiveHunger' ? 'Fome Excessiva' : symp == 'symptomFatigue' ? 'Fadiga' : symp == 'none' ? 'Nenhum' : symp), style: const TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => _handleSendMessage(label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF53A4DC).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF53A4DC).withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}