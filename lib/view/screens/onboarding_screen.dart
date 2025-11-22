import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_stepper/progress_stepper.dart';

import 'package:quitsmoking/core/theme/app_colors.dart';
import 'package:quitsmoking/core/widgets/neon_loader.dart';
import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_event.dart';
import 'package:quitsmoking/viewmodel/auth/auth_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  int currentStep = 0;

  // User Input Motivations
  final List<String> userMotivations = [];
  late final TextEditingController _motivationInputController;

  int dailyIntake = 5;
  int cigarettesPerPack = 10;
  double packCost = 100;
  bool notificationsEnabled = true;

  late final TextEditingController _packCostController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _motivationInputController = TextEditingController();
    _packCostController = TextEditingController(
      text: packCost.toStringAsFixed(0),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _packCostController.dispose();
    _motivationInputController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _go(int index) {
    setState(() {
      currentStep = index;
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    });
  }

  void _next() {
    if (currentStep == 0) {
      if (userMotivations.length < 3) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.red,
            content: Text(
              "Please add at least ${3 - userMotivations.length} more motivation(s).",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        return;
      }
    }

    if (currentStep == 4) return _finish();
    _go(currentStep + 1);
  }

  void _back() {
    if (currentStep > 0) _go(currentStep - 1);
  }

  void _finish() {
    final parsed =
        double.tryParse(_packCostController.text.replaceAll(',', '').trim()) ??
            packCost;

    context.read<AuthBloc>().add(
          OnboardingCompleted(
            motivations: userMotivations,
            dailyIntake: dailyIntake,
            cigarettesPerPack: cigarettesPerPack,
            packCost: parsed,
            notificationsEnabled: notificationsEnabled,
          ),
        );
  }

  void _addMotivation() {
    final text = _motivationInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        userMotivations.add(text);
        _motivationInputController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (c, s) {
        if (s is AuthLoading) {
          showDialog(
            context: c,
            barrierDismissible: false,
            builder: (_) => const Center(child: NeonLoader()),
          );
          return;
        }
        if (Navigator.of(c, rootNavigator: true).canPop()) {
          Navigator.of(c, rootNavigator: true).pop();
        }
        if (s is AuthAuthenticated) {
          // Handled by Router
        }
        if (s is AuthError) {
          ScaffoldMessenger.of(c)
              .showSnackBar(SnackBar(content: Text(s.message)));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        // CHANGED: Resize to avoid bottom overflow when keyboard is up
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _top(),
              _progress(),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _stepMotivations(),
                    _stepDaily(),
                    _stepPerPack(),
                    _stepPackCost(),
                    _stepNotifications(),
                  ],
                ),
              ),
              _bottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _top() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
        child: Row(
          children: [
            const Text(
              'logmysmoke',
              style: TextStyle(
                color: Colors.red,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              '.',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.close, color: Colors.white70),
            ),
          ],
        ),
      );

  Widget _progress() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: ProgressStepper(
          width: MediaQuery.of(context).size.width - 40,
          height: 14,
          stepCount: 5,
          currentStep: currentStep,
          color: AppColors.progressTrack,
          progressColor: Colors.red,
        ),
      );

  // CHANGED: Ensure scrolling for every step
  Widget _stepMotivations() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          const Text(
            "YOUR 'WHY'",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.red,
              letterSpacing: 1.5,
              shadows: [
                Shadow(color: Colors.redAccent, blurRadius: 10),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Add at least 3 powerful reasons",
            style: TextStyle(
                color: userMotivations.length >= 3
                    ? Colors.redAccent
                    : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2)
              ],
            ),
            child: TextField(
              controller: _motivationInputController,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              onSubmitted: (_) => _addMotivation(),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2A0000),
                hintText: "I am quitting because...",
                hintStyle: TextStyle(color: Colors.red.withOpacity(0.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: Colors.red.withOpacity(0.5), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Colors.redAccent, width: 2),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.add_circle, size: 32),
                    color: Colors.redAccent,
                    onPressed: _addMotivation,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          if (userMotivations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.format_quote_rounded,
                        size: 60, color: Colors.red.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text(
                      "Your personal motivations\nwill appear here as powerful reminders.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: userMotivations.map((m) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.9),
                        const Color(0xFF4A0000),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 6)
                            ]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          m,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            userMotivations.remove(m);
                          });
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white70),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // CHANGED: Wrapped in SingleChildScrollView
  Widget _stepDaily() => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                "How many cigarettes do you smoke daily?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: 160,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    '$dailyIntake',
                    style: const TextStyle(
                      fontSize: 44,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RoundCircle(
                    icon: Icons.remove,
                    onTap: () => setState(() {
                      if (dailyIntake > 0) dailyIntake--;
                    }),
                  ),
                  const SizedBox(width: 28),
                  RoundCircle(
                    icon: Icons.add,
                    background: Colors.red,
                    iconColor: Colors.white,
                    onTap: () => setState(() => dailyIntake++),
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      );

  // CHANGED: Wrapped in SingleChildScrollView
  Widget _stepPerPack() => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                "How many cigarettes are in a pack?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: 160,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    '$cigarettesPerPack',
                    style: const TextStyle(
                      fontSize: 44,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RoundCircle(
                    icon: Icons.remove,
                    onTap: () => setState(() {
                      if (cigarettesPerPack > 1) cigarettesPerPack--;
                    }),
                  ),
                  const SizedBox(width: 28),
                  RoundCircle(
                    icon: Icons.add,
                    background: Colors.red,
                    iconColor: Colors.white,
                    onTap: () => setState(() => cigarettesPerPack++),
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      );

  // CHANGED: Wrapped in SingleChildScrollView
  Widget _stepPackCost() => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                "What is the cost of a pack?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _packCostController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceDarker,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        '₹',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => packCost = double.tryParse(v) ?? packCost),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      'Average cost of a cigarette: ${cigarettesPerPack > 0 ? (packCost / cigarettesPerPack).toStringAsFixed(2) : 'N/A'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estimated daily spending: ${(packCost / (cigarettesPerPack > 0 ? cigarettesPerPack : 1) * dailyIntake).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      );

  // CHANGED: Wrapped in SingleChildScrollView
  Widget _stepNotifications() => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'Enable daily motivational notifications?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              const Icon(Icons.notifications_active,
                  size: 72, color: Colors.red),
              const SizedBox(height: 16),
              SwitchListTile(
                value: notificationsEnabled,
                onChanged: (v) => setState(() => notificationsEnabled = v),
                title: const Text(
                  'Enable daily notifications',
                  style: TextStyle(color: Colors.white),
                ),
                activeColor: Colors.red,
              ),
              const SizedBox(height: 8),
              const Text(
                'We will send one daily motivation and a gentle reminder to log your cigarettes.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      );

  Widget _bottomControls() {
    final isLast = currentStep == 4;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14),
        child: Row(
          children: [
            if (currentStep > 0)
              TextButton(
                onPressed: _back,
                child: const Text(
                  'Back',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            const Spacer(),
            SizedBox(
              height: 52,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) {
                  final glow = 0.12 + 0.06 * _glowController.value;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(glow),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.redAccent],
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: _next,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26.0),
                          child: Text(
                            isLast ? "Finish" : "Next",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoundCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color iconColor;
  const RoundCircle({
    required this.icon,
    required this.onTap,
    this.background = AppColors.buttonDark,
    this.iconColor = AppColors.softWhite,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background,
          boxShadow: [
            BoxShadow(
              color: background.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(child: Icon(icon, color: iconColor)),
      ),
    );
  }
}
