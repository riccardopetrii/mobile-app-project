import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/diary_repository.dart';
import '../data/repositories/help_request_repository.dart';
import '../data/repositories/mood_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/avatar_service.dart';
import '../data/services/database_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/preferences_service.dart';
import '../domain/use_cases/delete_account_use_case.dart';
import '../domain/use_cases/sos_session_use_case.dart';
import '../domain/use_cases/weekly_progress_use_case.dart';

/// I servizi, i repository e i casi d'uso condivisi da tutta l'applicazione.
///
/// Sono creati una sola volta e messi a disposizione con `provider`; i
/// ViewModel li ricevono nel costruttore, così nei test possono essere
/// sostituiti da implementazioni finte.
List<SingleChildWidget> providers({
  DatabaseService? database,
  PreferencesService? preferences,
  NotificationService? notifications,
  AvatarService? avatar,
}) {
  final databaseService = database ?? DatabaseService();
  final preferencesService = preferences ?? PreferencesService();
  final notificationService = notifications ?? NotificationService();
  final avatarService = avatar ?? LocalAvatarService();

  return <SingleChildWidget>[
    Provider<DatabaseService>.value(value: databaseService),
    Provider<PreferencesService>.value(value: preferencesService),
    Provider<NotificationService>.value(value: notificationService),
    Provider<AvatarService>.value(value: avatarService),

    Provider<UserRepository>(
      create: (_) => LocalUserRepository(databaseService),
    ),
    Provider<MoodRepository>(
      create: (_) => LocalMoodRepository(databaseService),
    ),
    Provider<DiaryRepository>(
      create: (_) => LocalDiaryRepository(databaseService),
    ),
    Provider<HelpRequestRepository>(
      create: (_) => LocalHelpRequestRepository(databaseService),
    ),
    Provider<SettingsRepository>(
      create: (_) => LocalSettingsRepository(preferencesService),
    ),

    Provider<WeeklyProgressUseCase>(
      create: (context) => WeeklyProgressUseCase(context.read()),
    ),
    Provider<SosSessionUseCase>(
      create: (context) => SosSessionUseCase(context.read()),
    ),
    Provider<DeleteAccountUseCase>(
      create: (context) => DeleteAccountUseCase(
        users: context.read(),
        moods: context.read(),
        diary: context.read(),
        requests: context.read(),
        settings: context.read(),
      ),
    ),
  ];
}
