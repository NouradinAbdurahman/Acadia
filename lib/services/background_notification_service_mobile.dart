import 'dart:io';

import 'package:background_fetch/background_fetch.dart' as bf;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart' as wm;

import '../repositories/analytics_repository.dart';
import '../repositories/task_repository.dart';
import '../services/notification_intelligence_service.dart';
import '../services/notification_service.dart';
import '../services/supabase/analytics_service.dart';
import '../services/supabase/task_service.dart';
import '../services/supabase/semester_state_service.dart';

const String _supabaseUrlKey = 'background_supabase_url';
const String _supabaseAnonKeyKey = 'background_supabase_anon_key';
const String _workmanagerTaskName = 'evaluateNotifications';

@pragma('vm:entry-point')
void callbackDispatcher() {
  wm.Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await BackgroundNotificationService.runEvaluation(source: 'workmanager');
    return true;
  });
}

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(bf.HeadlessTask task) async {
  WidgetsFlutterBinding.ensureInitialized();

  final taskId = task.taskId;
  if (task.timeout) {
    bf.BackgroundFetch.finish(taskId);
    return;
  }

  await BackgroundNotificationService.runEvaluation(source: 'background_fetch');
  bf.BackgroundFetch.finish(taskId);
}

class BackgroundNotificationService {
  static bool _initialized = false;

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_supabaseUrlKey, supabaseUrl);
    await prefs.setString(_supabaseAnonKeyKey, supabaseAnonKey);

    if (_initialized) return;
    _initialized = true;

    if (Platform.isAndroid) {
      await wm.Workmanager().initialize(callbackDispatcher);
      await wm.Workmanager().registerPeriodicTask(
        _workmanagerTaskName,
        _workmanagerTaskName,
        frequency: const Duration(minutes: 30),
        existingWorkPolicy: wm.ExistingPeriodicWorkPolicy.keep,
        constraints: wm.Constraints(networkType: wm.NetworkType.connected),
      );
    }

    if (Platform.isIOS) {
      await bf.BackgroundFetch.configure(
        bf.BackgroundFetchConfig(
          minimumFetchInterval: 30,
          stopOnTerminate: false,
          enableHeadless: true,
          startOnBoot: true,
          requiredNetworkType: bf.NetworkType.ANY,
        ),
        (String taskId) async {
          await runEvaluation(source: 'background_fetch');
          bf.BackgroundFetch.finish(taskId);
        },
        (String taskId) async {
          bf.BackgroundFetch.finish(taskId);
        },
      );
      bf.BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
    }
  }

  static Future<void> runEvaluation({String source = 'manual'}) async {
    print('BACKGROUND JOB STARTED');
    final prefs = await SharedPreferences.getInstance();
    final supabaseUrl = prefs.getString(_supabaseUrlKey);
    final supabaseAnonKey = prefs.getString(_supabaseAnonKeyKey);

    if (supabaseUrl == null || supabaseAnonKey == null) return;

    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    } catch (_) {
      // If the background isolate has already been bootstrapped, continue.
    }

    await NotificationService.init(
      requestPermissions: false,
      attachForegroundListeners: false,
    );

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    print('USER: ${user?.id}');
    if (user == null) return;

    final semesterStateService = SemesterStateService();
    final semesterId = await semesterStateService.getActiveSemesterId();
    if (semesterId == null) return;

    final taskRepository = TaskRepository(TaskService(client));
    final analyticsRepository = AnalyticsRepository(AnalyticsService(client));

    final analytics = await analyticsRepository.getAnalyticsData(
      user.id,
      semesterId: semesterId,
    );

    final tasks = await taskRepository.getTasks(
      userId: user.id,
      semesterId: semesterId,
    );

    print('TASKS COUNT: ${tasks.length}');
    print('ANALYTICS: ${analytics.riskScore}');

    await NotificationIntelligenceService.evaluateBackground(
      analytics: analytics,
      tasks: tasks,
      fetchTasks: () =>
          taskRepository.getTasks(userId: user.id, semesterId: semesterId),
    );

    if (source == 'manual_smoke') {
      await NotificationService.sendSmartNotification(
        title: 'TEST BACKGROUND',
        body: 'Background execution works',
        type: 'test',
      );
    }
  }
}
