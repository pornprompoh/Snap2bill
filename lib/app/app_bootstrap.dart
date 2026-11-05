import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/offline/offline_service.dart';
import 'app_provider_scope.dart';

Future<void> bootstrapAndRunApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final offlineService = OfflineService();
  unawaited(offlineService.start());

  runApp(AppProviderScope(offlineService: offlineService));
}
