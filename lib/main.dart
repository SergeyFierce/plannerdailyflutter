import 'package:flutter/material.dart';
import 'app.dart';
import 'features/planner/data/planner_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация БД
  await PlannerRepository.init();
  
  runApp(const PlannerDailyApp());
}
