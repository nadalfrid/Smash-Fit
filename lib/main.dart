import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'views/login_view.dart';
import 'views/main_layout.dart'; 


import 'services/ai_coaching_service.dart';

// Import your controllers
import 'controllers/workout/workout_controller.dart';
import 'controllers/workout/workout_timer_controller.dart';
import 'controllers/history/workout_history_controller.dart';
import 'controllers/exercise/exercise_search_controller.dart';
import 'controllers/exercise/exercise_detail_controller.dart';
import 'controllers/workout/workout_questionnaire_controller.dart';
import 'controllers/diet_controller.dart';
import 'controllers/analysis/exercise_analysis_controller.dart';
import 'controllers/analysis/diet_analysis_controller.dart';
import 'controllers/analysis/workout_insight_controller.dart';
import 'controllers/analysis/diet_insight_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/report_controller.dart';
import 'controllers/weight_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => WorkoutController()),
        ChangeNotifierProvider(create: (_) => WorkoutTimerController()),
        ChangeNotifierProvider(create: (_) => WorkoutHistoryController()),
        ChangeNotifierProvider(create: (_) => ExerciseSearchController()),
        ChangeNotifierProvider(create: (_) => ExerciseDetailController()),
        ChangeNotifierProvider(create: (_) => WorkoutQuestionnaireController()),
        ChangeNotifierProvider(create: (_) => DietController()),
        ChangeNotifierProvider(create: (_) => ExerciseAnalysisController()),
        ChangeNotifierProvider(create: (_) => DietAnalysisController()),
        ChangeNotifierProvider(create: (_) => WorkoutInsightController()),
        ChangeNotifierProvider(create: (_) => DietInsightController()),
        Provider<AICoachingService>(create: (_) => AICoachingService()),
        ChangeNotifierProvider(create: (_) => ReportController()),
        ChangeNotifierProvider(create: (_) => WeightController()),
      ],
      child: const SmashFitApp(),
    ),
  );
}

class SmashFitApp extends StatelessWidget {
  const SmashFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smash Fit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2A9D8F),
          primary: const Color(0xFF2A9D8F),
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF2A9D8F)),
              ),
            );
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return const MainLayout(); 
          }
          
          return const LoginView(); 
        },
      ),

      supportedLocales: const [
        Locale('en', 'US'), 
        Locale('en', 'MY'), 
        Locale('ms', 'MY'), 
      ],
      
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}