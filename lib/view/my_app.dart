// lib/view/my_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quitsmoking/core/router/router.dart';

import 'package:quitsmoking/data/services/firebase_auth_service.dart';
import 'package:quitsmoking/data/repositories/auth_repository.dart';
import 'package:quitsmoking/data/repositories/smoke_log_repository.dart';

import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/viewmodel/auth/auth_event.dart';

import 'package:quitsmoking/viewmodel/home/home_bloc.dart';
import 'package:quitsmoking/viewmodel/history/history_bloc.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final HomeBloc _homeBloc;
  late final HistoryBloc _historyBloc;

  bool _initialized = false;
  bool _started = false; // ensures AppStarted only runs once

  @override
  void initState() {
    super.initState();
    _initDependencies();
  }

  Future<void> _initDependencies() async {
    // ----------------------------
    // AUTHENTICATION SYSTEM
    // ----------------------------
    final authRepo = FirebaseAuthRepository(
      googleSignIn: GoogleSignIn.standard(),
      firebaseAuth: fb.FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );

    _authBloc = AuthBloc(authRepository: authRepo);

    // ----------------------------
    // SMOKE LOG SYSTEM (Shared repo)
    // ----------------------------
    final smokeRepo = SmokeLogRepository(firestore: FirebaseFirestore.instance);

    // HomeBloc — dynamic expectedCostPerCig & expectedDailyIntake
    _homeBloc = HomeBloc(
      repo: smokeRepo,
      expectedCostPerCig: 0,
      expectedDailyIntake: 0,
    );

    // HistoryBloc — listens to same smoke logs repo
    _historyBloc = HistoryBloc(repo: smokeRepo);

    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _authBloc.close();
    _homeBloc.close();
    _historyBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0B0B0C),
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF3BF37C)),
            ),
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _homeBloc),
        BlocProvider.value(
          value: _historyBloc,
        ), // <-- Required for History Screen
      ],
      child: Builder(
        builder: (context) {
          // Dispatch AppStarted ONCE after UI loads
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_started) {
              _started = true;
              context.read<AuthBloc>().add(AppStarted());
            }
          });

          final router = createAppRouter(_authBloc);

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'logmysmoke',
            routerConfig: router,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF0B0B0C),
            ),
          );
        },
      ),
    );
  }
}
