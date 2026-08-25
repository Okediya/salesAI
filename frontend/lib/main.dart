import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sales_ai_provider.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SalesAiApp());
}

class SalesAiApp extends StatelessWidget {
  const SalesAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SalesAiProvider()),
      ],
      child: MaterialApp(
        title: 'SalesAI - 24/7 Autonomous Sales & Marketing Agent',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainShell(),
      ),
    );
  }
}
