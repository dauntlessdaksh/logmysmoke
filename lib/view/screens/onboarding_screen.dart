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

  final motivations = const [
    "You will breathe freely and feel lighter every day.",
    "Your body starts healing within hours of quitting.",
    "Food tastes richer, and your sense of smell returns.",
    "Your skin becomes clearer and more radiant.",
    "You will always smell clean and fresh.",
    "You will save a large amount of money every month and year.",
    "Your confidence grows because you beat addiction.",
    "Your sleep improves, and you wake up energized.",
    "Your mind becomes sharper and more focused.",
    "Your stamina and energy increase for daily activities.",
    "You become a healthy role model for others.",
    "No more hiding or rushing for smoke breaks.",
    "You regain full control over your mind and body.",
    "You protect your loved ones from secondhand smoke.",
    "Every smoke-free day becomes a personal victory.",
  ];

  final Set<String> selectedMotivations = {};
  int dailyIntake = 5;
  int cigarettesPerPack = 10;
  double packCost = 100;
  bool notificationsEnabled = true;

  late final TextEditingController _packCostController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
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
        motivations: selectedMotivations.toList(),
        dailyIntake: dailyIntake,
        cigarettesPerPack: cigarettesPerPack,
        packCost: parsed,
        notificationsEnabled: notificationsEnabled,
      ),
    );
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
        // close any dialog from loading
        if (Navigator.of(c, rootNavigator: true).canPop())
          Navigator.of(c, rootNavigator: true).pop();
        if (s is AuthAuthenticated) {
          // router redirect will handle navigation
        }
        if (s is AuthError) {
          ScaffoldMessenger.of(
            c,
          ).showSnackBar(SnackBar(content: Text(s.message)));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
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
        Text(
          'logmysmoke',
          style: TextStyle(
            color: AppColors.logoPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '.',
          style: TextStyle(
            color: AppColors.logoDot,
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
      progressColor: AppColors.progressFill,
    ),
  );

  Widget _stepMotivations() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 6),
          const Text(
            "What motivates you to quit smoking?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "Tap to select one or more motivations",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: motivations.map((m) {
                  final selected = selectedMotivations.contains(m);
                  return NeonPill(
                    label: m,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        if (selected)
                          selectedMotivations.remove(m);
                        else
                          selectedMotivations.add(m);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDaily() => Padding(
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
              background: AppColors.neonGreen,
              iconColor: Colors.black,
              onTap: () => setState(() => dailyIntake++),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _stepPerPack() => Padding(
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
              background: AppColors.neonGreen,
              iconColor: Colors.black,
              onTap: () => setState(() => cigarettesPerPack++),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _stepPackCost() => Padding(
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceDarker,
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  '₹',
                  style: TextStyle(
                    color: AppColors.neonGreen,
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
      ],
    ),
  );

  Widget _stepNotifications() => Padding(
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
        Icon(Icons.notifications_active, size: 72, color: AppColors.neonBlue),
        const SizedBox(height: 16),
        SwitchListTile(
          value: notificationsEnabled,
          onChanged: (v) => setState(() => notificationsEnabled = v),
          title: const Text(
            'Enable daily notifications',
            style: TextStyle(color: Colors.white),
          ),
          activeColor: AppColors.neonGreen,
        ),
        const SizedBox(height: 8),
        const Text(
          'We will send one daily motivation and a gentle reminder to log your cigarettes.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
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
                          color: AppColors.neonGreen.withOpacity(glow),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [AppColors.neonGreen, AppColors.neonBlue],
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
                              color: Colors.black,
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

/// Small neon helper widgets:
class NeonPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const NeonPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.chipSelected : AppColors.chipBackground;
    final glow = selected ? AppColors.chipSelectedGlow : AppColors.chipGlow;
    final fg = selected ? Colors.white : AppColors.softWhite;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        width: MediaQuery.of(context).size.width - 64,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: glow,
              blurRadius: selected ? 18 : 6,
              spreadRadius: selected ? 1.0 : 0.2,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
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
