import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;
}

class WelcomeScreen extends StatelessWidget {
  final Widget appLogo;
  final String welcomeText;
  final String startBtnText;
  final VoidCallback onStartPressed;

  const WelcomeScreen({
    Key? key,
    required this.appLogo,
    required this.welcomeText,
    required this.startBtnText,
    required this.onStartPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgStart = isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F8FA);
    final Color bgEnd = isDark ? const Color(0xFF1E293B) : const Color(0xFF53A4DC).withOpacity(0.15);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgStart, bgEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    appLogo,
                    const SizedBox(height: 28),
                    Text(
                      'GlicoCare',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                        fontSize: ResponsiveBreakpoints.isMobile(context) ? 32 : 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      welcomeText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        fontSize: ResponsiveBreakpoints.isMobile(context) ? 15 : 18,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 280),
                      height: 54,
                      child: ElevatedButton(
                        onPressed: onStartPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                          elevation: 3,
                          shadowColor: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80)).withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          startBtnText,
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuizIntroScreen extends StatelessWidget {
  final VoidCallback onStartQuiz;
  final VoidCallback onSkipQuiz;
  final String Function(String key) getText;

  const QuizIntroScreen({
    Key? key,
    required this.onStartQuiz,
    required this.onSkipQuiz,
    required this.getText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF1E5A80),
        elevation: 0,
        title: Text(
          getText('personalizeTitle'),
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: ResponsiveBreakpoints.isMobile(context) ? 64 : 88,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    getText('quizIntroTitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveBreakpoints.isMobile(context) ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    getText('quizIntroBody'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    getText('quizIntroBody2'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onStartQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        getText('startTest'),
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onSkipQuiz,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        getText('skipTest'),
                        style: TextStyle(
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResponsiveAuthScreen extends StatelessWidget {
  final bool isRegister;
  final Widget appLogo;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String currentLanguage;
  final Function(String) onLanguageChanged;
  final VoidCallback onSubmit;
  final VoidCallback onToggleAuthMode;
  final String Function(String key) getText;

  const ResponsiveAuthScreen({
    Key? key,
    required this.isRegister,
    required this.appLogo,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.currentLanguage,
    required this.onLanguageChanged,
    required this.onSubmit,
    required this.onToggleAuthMode,
    required this.getText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDesktop = ResponsiveBreakpoints.isDesktop(context);

    final Map<String, Map<String, String>> langData = {
      'pt': {'label': 'PT', 'flag': '🇧🇷', 'name': 'Português (Brasil)'},
      'en': {'label': 'EN', 'flag': '🇺🇸', 'name': 'English (USA)'},
      'zh': {'label': 'ZH', 'flag': '🇨🇳', 'name': 'Mandarin (中文)'},
      'es': {'label': 'ES', 'flag': '🇪🇸', 'name': 'Español'},
      'it': {'label': 'IT', 'flag': '🇮🇹', 'name': 'Italiano'},
      'fr': {'label': 'FR', 'flag': '🇫🇷', 'name': 'Français'},
      'de': {'label': 'DE', 'flag': '🇩🇪', 'name': 'Deutsch'},
      'ko': {'label': 'KO', 'flag': '🇰🇷', 'name': '한국어 (Coreano)'},
      'ja': {'label': 'JA', 'flag': '🇯🇵', 'name': '日本語 (Japonês)'},
      'hi': {'label': 'HI', 'flag': '🇮🇳', 'name': 'हिन्दी (Hindi)'},
      'ru': {'label': 'RU', 'flag': '🇷🇺', 'name': 'Русский (Russo)'},
    };

    final Widget leftPanel = Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E5A80), const Color(0xFF164360)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: isDesktop
            ? const BorderRadius.only(topLeft: Radius.circular(28), bottomLeft: Radius.circular(28))
            : const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  appLogo,
                  const SizedBox(width: 12),
                  const Text('GlicoCare', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              PopupMenuButton<String>(
                initialValue: currentLanguage,
                onSelected: onLanguageChanged,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Text(langData[currentLanguage]?['flag'] ?? '🇧🇷', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(langData[currentLanguage]?['label'] ?? 'PT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
                itemBuilder: (BuildContext context) {
                  return langData.entries.map((entry) {
                    return PopupMenuItem<String>(
                      value: entry.key,
                      child: Row(
                        children: [
                          Text(entry.value['flag']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(entry.value['name']!, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            getText('welcome'),
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            getText('subtitle'),
            style: const TextStyle(color: Color(0xFFD0E3F0), fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );

    final Widget rightPanel = Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRegister ? getText('signup') : getText('signin'),
            style: TextStyle(
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (isRegister) ...[
            _buildCustomField(
              context,
              controller: nameController,
              hint: getText('namePlaceholder'),
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 14),
          ],
          _buildCustomField(
            context,
            controller: emailController,
            hint: getText('userPlaceholder'),
            icon: Icons.alternate_email,
          ),
          const SizedBox(height: 14),
          _buildCustomField(
            context,
            controller: passwordController,
            hint: getText('passPlaceholder'),
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isRegister ? getText('signup') : getText('signin'),
                style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isRegister ? getText('alreadyHaveAccount') : getText('newHere'),
                style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 13),
              ),
              TextButton(
                onPressed: onToggleAuthMode,
                child: Text(
                  isRegister ? getText('signin') : getText('createAccount'),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 900 : 500),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDesktop) ...[
                    Expanded(child: leftPanel),
                    Expanded(child: rightPanel),
                  ] else ...[
                    leftPanel,
                    rightPanel,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: isDark ? Colors.white38 : const Color(0xFF94A3B8), size: 20),
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E5A80), width: 1.5),
        ),
      ),
    );
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth = 1100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}