import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitaptakas/features/admin/view/admin_dashboard.dart';
import 'package:kitaptakas/features/auth/bloc/auth_bloc.dart';
import 'package:kitaptakas/features/auth/bloc/auth_event.dart';
import 'package:kitaptakas/features/auth/bloc/auth_state.dart';
import 'package:kitaptakas/features/auth/view/welcome_view.dart';
import 'package:kitaptakas/features/home/view/home_view.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthCheckRequest());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(body: CircularProgressIndicator());
        }
        if (state is AuthAuthenticated) {
          return const HomePage();
        }
        return const WelcomeView();
      },
    );
  }
}
