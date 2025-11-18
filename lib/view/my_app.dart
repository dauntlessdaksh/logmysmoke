// Contains app initialization and provides AuthBloc
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quitsmoking/core/router/router.dart';
import 'package:quitsmoking/data/services/firebase_auth_service.dart';

import 'package:quitsmoking/viewmodel/auth/auth_bloc.dart';
import 'package:quitsmoking/data/repositories/auth_repository.dart';

import 'package:quitsmoking/viewmodel/auth/auth_event.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initDependencies();
  }

  Future<void> _initDependencies() async {
    // create the repo with real Firebase instances
    final authRepo = FirebaseAuthRepository(
      googleSignIn: GoogleSignIn.standard(),
      firebaseAuth: fb.FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );

    _authBloc = AuthBloc(authRepository: authRepo);

    setState(() => _initialized = true);

    // dispatch AppStarted after bloc has been provided in tree (done in build)
  }

  @override
  void dispose() {
    _authBloc.close();
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

    return BlocProvider.value(
      value: _authBloc,
      child: Builder(
        builder: (context) {
          // Post frame dispatch so GoRouter can subscribe to bloc stream
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthBloc>().add(AppStarted());
          });

          final router = createAppRouter(context.read<AuthBloc>());

          return MaterialApp.router(
            title: 'logmysmoke',
            debugShowCheckedModeBanner: false,
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
