// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'Strona główna';

  @override
  String get playersListTitle => 'Lista graczy';

  @override
  String get gameTypesTitle => 'Rodzaje gier';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get aboutTitle => 'O aplikacji';

  @override
  String get newGame => 'Nowa gra';

  @override
  String get noGames => 'Brak gier';

  @override
  String get noGamesOfThisType => 'Brak gier tego typu';

  @override
  String get createFirstGame => 'Utwórz swoją pierwszą grę';

  @override
  String get newWithSamePlayers => 'Nowa z tymi samymi graczami';

  @override
  String get playAgain => 'Graj jeszcze raz';

  @override
  String get rename => 'Zmień nazwę';

  @override
  String get delete => 'Usuń';

  @override
  String get confirmDeletion => 'Potwierdź usunięcie';

  @override
  String confirmDeleteGame(String name) {
    return 'Czy naprawdę chcesz usunąć grę \"$name\"?';
  }

  @override
  String get cancel => 'Anuluj';

  @override
  String get renameGame => 'Zmień nazwę gry';

  @override
  String get gameName => 'Nazwa gry';

  @override
  String get save => 'Zapisz';

  @override
  String get allGames => 'Wszystkie gry';

  @override
  String get filterGames => 'Filtruj gry';

  @override
  String get applyFilter => 'Zastosuj';

  @override
  String get resetFilter => 'Resetuj';

  @override
  String get selectGameType => 'Wybierz rodzaj gry';

  @override
  String get gameType => 'Rodzaj gry';

  @override
  String get loadingGameTypes => 'Ładowanie rodzajów gier...';

  @override
  String get lowestScoreWins => 'Najniższy wynik wygrywa';

  @override
  String get highestScoreWins => 'Najwyższy wynik wygrywa';

  @override
  String get players => 'Gracze';

  @override
  String get add => 'Dodaj';

  @override
  String get pleaseEnterName => 'Proszę wpisz nazwę';

  @override
  String get clear => 'Wyczyść';

  @override
  String get remove => 'Usuń';

  @override
  String get game => 'Gra';

  @override
  String get editGame => 'Edytuj grę';

  @override
  String get editGameDialogTitle => 'Edytuj grę';

  @override
  String get removePlayer => 'Usuń gracza';

  @override
  String get addPlayerToGame => 'Dodaj gracza';

  @override
  String get warningRemovePlayer =>
      'Ostrzeżenie! Usunięcie tego gracza spowoduje skasowanie wszystkich jego wyników z tej gry. Ta czynność jest nieodwracalna.';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'Czy naprawdę chcesz usunąć $playerName z tej gry?';
  }

  @override
  String get playerRemoved => 'Gracz usunięty z gry';

  @override
  String get deleteLastRound => 'Usuń ostatnią rundę';

  @override
  String get confirm => 'Potwierdź';

  @override
  String get confirmDeleteLastRound => 'Usunąć ostatnią rundę?';

  @override
  String get noPlayersInGame => 'Brak graczy w tej grze';

  @override
  String get round => 'Runda';

  @override
  String boardRoundButton(int round) {
    return 'Runda $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · runda $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · runda $round · $position/$count';
  }

  @override
  String keypadTotalAfter(int total) {
    return 'razem po: $total';
  }

  @override
  String keypadNext(String player) {
    return 'Następny\n$player';
  }

  @override
  String get keypadValidateRound => 'Zatwierdź rundę';

  @override
  String get keypadToggleSign => 'Zmień znak';

  @override
  String get keypadBackspace => 'Usuń cyfrę';

  @override
  String get keypadShortcutTitle => 'Skrót klawiatury';

  @override
  String get keypadShortcutKind => 'Typ klawisza';

  @override
  String get keypadShortcutKindValue => 'Wpisz wartość';

  @override
  String get keypadShortcutKindMultiply => 'Pomnóż wynik (tylko dodatni)';

  @override
  String get keypadShortcutKindAdd => 'Dodaj do wyniku';

  @override
  String get keypadShortcutAmount => 'Liczba';

  @override
  String get keypadShortcutLabel => 'Etykieta klawisza (opcjonalnie)';

  @override
  String keypadShortcutAddRange(int min, int max) {
    return 'Liczba całkowita między $min a $max, inna niż 0';
  }

  @override
  String keypadShortcutAmountRange(int min, int max) {
    return 'Liczba całkowita między $min a $max';
  }

  @override
  String get appearance => 'Wygląd';

  @override
  String get light => 'Jasny';

  @override
  String get dark => 'Ciemny';

  @override
  String get system => 'System';

  @override
  String get screen => 'Ekran';

  @override
  String get keepScreenAwake => 'Utrzymaj ekran aktywny';

  @override
  String get keepScreenAwakeDescription =>
      'Zapobiega usypianiu ekranu podczas gry';

  @override
  String get backup => 'Kopia zapasowa';

  @override
  String get exportDatabase => 'Eksportuj bazę danych';

  @override
  String get exportDatabaseDescription => 'Zapisz wszystkie swoje gry do pliku';

  @override
  String get databaseExportedTo => 'Baza danych wyeksportowana do:';

  @override
  String get errorDuringExport => 'Błąd podczas eksportu:';

  @override
  String get importDatabase => 'Importuj bazę danych';

  @override
  String get importDatabaseDescription =>
      'Przywróć swoje gry z pliku kopii zapasowej';

  @override
  String get confirmation => 'Potwierdzenie';

  @override
  String get importWarning =>
      'Importowanie zastąpi wszystkie bieżące dane. Automatyczna kopia zapasowa zostanie utworzona przed importem.\n\nCzy chcesz kontynuować?';

  @override
  String get import => 'Importuj';

  @override
  String get databaseImportedSuccessfully =>
      'Baza danych zaimportowana pomyślnie';

  @override
  String get importSuccessful => 'Import pomyślny';

  @override
  String get importSuccessMessage =>
      'Baza danych została zaimportowana pomyślnie.\n\nAplikacja zostanie teraz zamknięta. Proszę otwórz ją ponownie, aby zobaczyć nowe dane.';

  @override
  String get ok => 'OK';

  @override
  String get errorDuringImport => 'Błąd podczas importu:';

  @override
  String get noPlayers => 'Brak graczy';

  @override
  String get playersAppearMessage =>
      'Gracze pojawią się tutaj, gdy\nutworzyłeś gry';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gier',
      many: '$count gier',
      few: '$count gry',
      one: '$count gra',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zwycięstw',
      many: '$count zwycięstw',
      few: '$count zwycięstwa',
      one: '$count zwycięstwo',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'Zmień kolor';

  @override
  String get renamePlayer => 'Zmień nazwę gracza';

  @override
  String get newName => 'Nowa nazwa';

  @override
  String playerRenamedTo(String name) {
    return 'Gracz zmienił nazwę na \"$name\"';
  }

  @override
  String get deletePlayer => 'Usuń gracza';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'Czy naprawdę chcesz usunąć \"$name\"?\n\nTen gracz będzie usunięty ze wszystkich $count gry(gier).';
  }

  @override
  String playerDeleted(String name) {
    return 'Gracz \"$name\" usunięty';
  }

  @override
  String get chooseColor => 'Wybierz kolor';

  @override
  String get noGameTypes => 'Brak rodzajów gier';

  @override
  String get edit => 'Edytuj';

  @override
  String get newType => 'Nowy typ';

  @override
  String get editType => 'Edytuj typ';

  @override
  String get newGameType => 'Nowy rodzaj gry';

  @override
  String get gameTypeName => 'Nazwa rodzaju gry';

  @override
  String get icon => 'Ikona:';

  @override
  String get color => 'Kolor:';

  @override
  String get chooseIcon => 'Wybierz ikonę';

  @override
  String get nameIsRequired => 'Nazwa jest wymagana';

  @override
  String get create => 'Utwórz';

  @override
  String get ranking => 'Ranking';

  @override
  String get noCurrentGame => 'Brak bieżącej gry';

  @override
  String get noScoresRecorded => 'Brak zarejestrowanych wyników';

  @override
  String get playerStatistics => 'Statystyki graczy';

  @override
  String get noStatisticsAvailable => 'Brak dostępnych statystyk';

  @override
  String get gamesPlayed => 'Rozegrane gry';

  @override
  String get wins => 'Zwycięstwa';

  @override
  String get winRate => 'Procent zwycięstw';

  @override
  String get byGameType => 'Wg rodzaju gry';

  @override
  String get rate => 'Wskaźnik';

  @override
  String version(String version) {
    return 'Wersja $version';
  }

  @override
  String get appDescription =>
      'Aplikacja do zarządzania wynikami dla sesji gier autorstwa Vincenta Moreaua';

  @override
  String get features => 'Funkcje';

  @override
  String get featureDifferentGameTypes => 'Różne rodzaje gier';

  @override
  String get featurePlayerManagement => 'Zarządzanie graczami';

  @override
  String get featureDetailedStatistics => 'Szczegółowe statystyki';

  @override
  String get featureCustomization => 'Dostosowanie';

  @override
  String get featureDarkLightTheme => 'Motyw ciemny/jasny';

  @override
  String get featureGroupSharing => 'Udostępnianie grupowe';

  @override
  String get featureGameAnalysis => 'Analiza gry AI';

  @override
  String get rateApp => 'Oceń CountScore';

  @override
  String get search => 'Szukaj';

  @override
  String get newPlayerName => 'Nazwa nowego gracza';

  @override
  String get noPlayersFound => 'Nie znaleziono graczy';

  @override
  String get close => 'Zamknij';

  @override
  String get playerEliminationCondition => 'Warunek eliminacji gracza';

  @override
  String get gameOverCondition => 'Warunek końca gry';

  @override
  String get none => 'Brak';

  @override
  String get overThreshold => 'Ponad próg';

  @override
  String get underThreshold => 'Poniżej progu';

  @override
  String get firstPlayerOver => 'Pierwszy gracz, który osiągnie';

  @override
  String get firstPlayerUnder => 'Pierwszy gracz poniżej';

  @override
  String get lastPlayerOver => 'Ostatni gracz w grze (inni ponad)';

  @override
  String get lastPlayerUnder => 'Ostatni gracz w grze (inni poniżej)';

  @override
  String get threshold => 'Próg';

  @override
  String get conditionType => 'Typ warunku';

  @override
  String get continuePlay => 'Kontynuuj grę';

  @override
  String gameEndWinner(String name) {
    return '$name wygrywa';
  }

  @override
  String gameEndTie(String names) {
    return 'Remis: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rund',
      many: '$count rund',
      few: '$count rundy',
      one: '$count runda',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'najniższy wynik wygrywa';

  @override
  String get gameEndHighestWins => 'najwyższy wynik wygrywa';

  @override
  String get gameEndAnalysis => 'Analiza';

  @override
  String get gameEndResults => 'Wyniki';

  @override
  String get rankingEliminationNote =>
      'Ranking wg kolejności eliminacji: kto wychodzi później, jest wyżej, niezależnie od sum.';

  @override
  String get endGame => 'Zakończ grę';

  @override
  String get reopenGame => 'Wznów grę';

  @override
  String get gameFinished => 'Zakończona';

  @override
  String get undo => 'Cofnij';

  @override
  String get gameReopened => 'Gra wznowiona';

  @override
  String get comment => 'Komentarz';

  @override
  String get enterComment => 'Wpisz komentarz';

  @override
  String get analyzeGame => 'Analizuj grę';

  @override
  String get analysisTitle => 'Analiza gry';

  @override
  String get analysisStyle => 'Styl analizy';

  @override
  String get analysisStyleProfessor => 'Profesor';

  @override
  String get analysisStyleCommentator => 'Komentator sportowy';

  @override
  String get analysisStyleDocumentary => 'Dokument przyrodniczy';

  @override
  String get analysisStyleNoir => 'Detektyw';

  @override
  String get analysisStyleBard => 'Bard';

  @override
  String get analysisStyleCoach => 'Trener';

  @override
  String get analysisStyleConsultant => 'Konsultant';

  @override
  String get analysisStyleAstrologer => 'Astrolog';

  @override
  String get analysisStyleRealityTv => 'Reality show';

  @override
  String get generatingAnalysis => 'Generowanie analizy…';

  @override
  String get generateAnalysis => 'Generuj analizę';

  @override
  String get regenerateAnalysis => 'Wygeneruj ponownie analizę';

  @override
  String get deleteAnalysis => 'Usuń analizę';

  @override
  String get confirmRegenerateAnalysis =>
      'Wygenerować ponownie? Bieżąca analiza zostanie zastąpiona.';

  @override
  String get confirmDeleteAnalysis => 'Usunąć analizę dla tej gry?';

  @override
  String get analysisError => 'Nie udało się wygenerować analizy';

  @override
  String get analysisErrorUnavailable =>
      'Serwer analizy jest tymczasowo niedostępny. Spróbuj ponownie później.';

  @override
  String get analysisErrorGroupBudget =>
      'Twoja grupa zużyła budżet analiz na ten miesiąc. Odnawia się na początku następnego miesiąca.';

  @override
  String get analysisStyleGroupDefault =>
      'Nie wybrano stylu: ta udostępniana gra jest analizowana w stylu i języku grupy.';

  @override
  String analysisErrorStatus(int status) {
    return 'Nie udało się wygenerować analizy (HTTP $status)';
  }

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String analysisGeneratedAt(String date) {
    return 'Wygenerowano $date';
  }

  @override
  String get serverSection => 'Serwer';

  @override
  String get backendUrlLabel => 'Adres URL serwera';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'Funkcje połączone wymagają serwera CountScore. Zainstaluj jeden z folderu backend/ i wpisz jego adres tutaj. Bez serwera żadne dane nie opuszczają tego urządzenia.';

  @override
  String get backendNotConfigured => 'Serwer nie skonfigurowany';

  @override
  String get backendUrlInvalid =>
      'Nieprawidłowy adres. Wpisz pełny adres URL, na przykład https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// jest akceptowany tylko w sieci lokalnej. Używaj https:// dla serwera publicznego.';

  @override
  String get testConnection => 'Testuj połączenie';

  @override
  String get connectionOk => 'Serwer odpowiada';

  @override
  String get connectionFailed => 'Serwer nie odpowiada';

  @override
  String get serverUrlSaved => 'Serwer zapisany';

  @override
  String get analysisRequiresBackend =>
      'Ta analiza wymaga serwera. Skonfiguruj jeden w ustawieniach.';

  @override
  String get openSettings => 'Otwórz ustawienia';

  @override
  String get serverUrlCleared => 'Serwer wyczyszczony';

  @override
  String get groupSection => 'Grupa';

  @override
  String get groupDescription =>
      'Udostępniaj gry innym urządzeniom w grupie. Udostępniane gry, ich gracze, wyniki, komentarze i analizy są wysyłane na twój serwer; inne gry pozostają na tym urządzeniu.';

  @override
  String get groupNeedsServer => 'Najpierw skonfiguruj serwer powyżej.';

  @override
  String get groupCreate => 'Utwórz grupę';

  @override
  String get groupJoin => 'Dołącz do grupy';

  @override
  String get groupNameLabel => 'Nazwa grupy';

  @override
  String get groupNicknameLabel => 'Twój pseudonim';

  @override
  String get groupNicknameHint => 'Inni członkowie grupy będą to widzieć';

  @override
  String groupNicknameCurrent(String nickname) {
    return 'Twój pseudonim: $nickname';
  }

  @override
  String get groupNicknameEdit => 'Zmień swój pseudonim';

  @override
  String get shareTokenLabel => 'Kod zaproszenia';

  @override
  String get shareTokenHint => 'Wklej kod przesłany przez członka grupy';

  @override
  String groupCurrent(String name) {
    return 'Grupa: $name';
  }

  @override
  String get shareTokenExplain =>
      'Wyślij ten kod do urządzeń, które mają dołączyć do grupy. Każdy, kto go ma, może dołączyć.';

  @override
  String get shareTokenCopy => 'Skopiuj kod';

  @override
  String get shareTokenCopied => 'Kod skopiowany';

  @override
  String get shareTokenRotate => 'Nowy kod';

  @override
  String get shareTokenRotateConfirm =>
      'Stary kod nie pozwoli już nikomu dołączyć. Urządzenia już w grupie nie są dotknięte.';

  @override
  String get groupLeave => 'Opuść grupę';

  @override
  String get groupLeaveConfirm =>
      'To urządzenie opuszcza grupę. Udostępniane gry pozostają na tym urządzeniu, ale nie będą już synchronizowane.';

  @override
  String get groupLeft => 'Grupa opuszczona';

  @override
  String get groupJoined => 'Grupa dołączona';

  @override
  String get clearServerLeavesGroup =>
      'Wyczyszczenie serwera powoduje opuszczenie grupy. Udostępniane gry pozostają na tym urządzeniu.';

  @override
  String get syncNow => 'Synchronizuj teraz';

  @override
  String syncStatusIdle(String time) {
    return 'Zsynchronizowano o $time';
  }

  @override
  String get syncStatusSyncing => 'Synchronizowanie…';

  @override
  String get syncStatusOffline =>
      'Serwer niedostępny — zmiany będą wysłane później';

  @override
  String get syncStatusUnauthorized =>
      'Serwer nie akceptuje już tego urządzenia. Opuść grupę, a następnie dołącz ją ponownie.';

  @override
  String get syncStatusError => 'Błąd serwera podczas synchronizacji';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zmian oczekujących',
      many: '$count zmian oczekujących',
      few: '$count zmiany oczekujące',
      one: '$count zmiana oczekująca',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zmian odrzuconych przez serwer',
      many: '$count zmian odrzuconych przez serwer',
      few: '$count zmiany odrzucone przez serwer',
      one: '$count zmiana odrzucona przez serwer',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken =>
      'Kod zaproszenia nieznany lub zastąpiony';

  @override
  String get groupErrorRateLimited =>
      'Zbyt wiele prób. Spróbuj ponownie za minutę.';

  @override
  String get groupErrorUnreachable => 'Serwer niedostępny';

  @override
  String get groupErrorServer => 'Błąd serwera';

  @override
  String get shareWithGroup => 'Udostępnij grupie';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'Urządzenia w grupie $name będą widać i edytować tę grę';
  }

  @override
  String shareGameConfirm(String name) {
    return 'Gra, jej gracze, wyniki i komentarze będą wysłane do $name. Udostępniania nie można cofnąć.';
  }

  @override
  String get gameSharedDone => 'Gra udostępniona grupie';

  @override
  String get gameSharedBadge => 'Udostępniana gra';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'Te nazwy nie mogą być udostępniane: $names. Używaj liter, cyfr, spacji, łączników, apostrofów lub kropek (maksymalnie 32 znaki).';
  }

  @override
  String roundRenumbered(int number) {
    return 'Ta runda została już wpisana na innym urządzeniu, więc stała się rundą $number.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return 'Gra \"$name\" została usunięta na innym urządzeniu';
  }

  @override
  String get groupDevices => 'Urządzenia';

  @override
  String get groupDevicesExplain =>
      'Zagubiony lub sprzedany telefon można usunąć z grupy tutaj.';

  @override
  String get groupDeviceThisOne => 'To urządzenie';

  @override
  String groupDeviceLastSeen(String date) {
    return 'Ostatnio widziane $date';
  }

  @override
  String get groupDeviceRevoke => 'Usuń';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'Usunąć \"$label\" z grupy? Nie będzie już synchronizować. Kod zaproszenia również się zmieni: członkowie zachowają dostęp, ale będziesz musiał udostępnić nowy kod, aby zaprosić kogokolwiek.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return 'Urządzenie \"$label\" zostało usunięte. Kod zaproszenia się zmienił.';
  }

  @override
  String get reportCommentary => 'Zgłoś ten komentarz';

  @override
  String get reportCommentarySubject => 'CountScore — zgłoszenie komentarza AI';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'Co jest nie tak z tym komentarzem wygenerowanym przez AI?\n\n\n---\nOdniesienie: $reference\nKomentarz:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'Nie znaleziono aplikacji poczty e-mail. Napisz do $email, aby zgłosić ten komentarz.';
  }

  @override
  String get gameRulesTitle => 'Zasady gry';

  @override
  String get gameRulesInApp => 'W CountScore';

  @override
  String get gameRulesSection => 'Zasady';

  @override
  String get gameRulesNoElimination => 'Brak eliminacji podczas gry';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'Gracz jest eliminowany powyżej $threshold punktów';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'Gracz jest eliminowany poniżej $threshold punktów';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'Gra kończy się, gdy gracz osiągnie $threshold punktów';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'Gra kończy się, gdy gracz spadnie poniżej $threshold punktów';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'Gra kończy się, gdy wszyscy oprócz jednego gracza przekroczą $threshold punktów';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'Gra kończy się, gdy wszyscy oprócz jednego gracza spadną poniżej $threshold punktów';
  }

  @override
  String get gameRulesNoEnd =>
      'Brak automatycznego końca: decydujesz, kiedy gra się skończy';

  @override
  String get gameRulesEmptyTitle => 'Brak jeszcze zasad';

  @override
  String get gameRulesEmptyHint =>
      'Zapisz, jak twój stół liczy punkty — wszyscy będą mieć tę samą wersję.';

  @override
  String get gameRulesWrite => 'Napisz zasady';

  @override
  String get gameRulesEditTitle => 'Edytuj zasady';

  @override
  String get gameRulesEditorHint =>
      'Zasady twojego stołu. Obsługiwany jest Markdown.';

  @override
  String get gameRulesFromGroup => 'Zasady twojej grupy';

  @override
  String get gameRulesRestoreDefault => 'Przywróć oryginalne zasady';

  @override
  String get gameRulesSaved => 'Zasady zapisane';

  @override
  String get gameRulesRestored => 'Oryginalne zasady przywrócone';

  @override
  String get gameRulesDisclaimer =>
      'Streszczenie napisane dla CountScore na podstawie zasad powszechnie granych. Nazwy gier należą do ich właścicieli i są używane wyłącznie w celach opisowych.';

  @override
  String get gameTypeNameZapzap => 'ZapZap';

  @override
  String get gameTypeNameZapzapSortKey => 'ZapZap';

  @override
  String get gameTypeNameUno => 'Uno';

  @override
  String get gameTypeNameUnoSortKey => 'Uno';

  @override
  String get gameTypeNameScrabble => 'Scrabble';

  @override
  String get gameTypeNameScrabbleSortKey => 'Scrabble';

  @override
  String get gameTypeNameOther => 'Inne';

  @override
  String get gameTypeNameOtherSortKey => 'Inne';

  @override
  String get gameTypeNameSkyjo => 'Skyjo';

  @override
  String get gameTypeNameSkyjoSortKey => 'Skyjo';

  @override
  String get gameTypeNamePresident => 'President';

  @override
  String get gameTypeNamePresidentSortKey => 'President';

  @override
  String get gameTypeNameBelote => 'Belote';

  @override
  String get gameTypeNameBeloteSortKey => 'Belote';

  @override
  String get gameTypeNameTarot => 'Tarot';

  @override
  String get gameTypeNameTarotSortKey => 'Tarot';

  @override
  String get gameTypeNameBridge => 'Bridge';

  @override
  String get gameTypeNameBridgeSortKey => 'Bridge';

  @override
  String get gameTypeNameRami => 'Rummy';

  @override
  String get gameTypeNameRamiSortKey => 'Rummy';

  @override
  String get gameTypeNameCoinche => 'Coinche';

  @override
  String get gameTypeNameCoincheSortKey => 'Coinche';

  @override
  String get gameTypeNameYahtzee => 'Yahtzee';

  @override
  String get gameTypeNameYahtzeeSortKey => 'Yahtzee';

  @override
  String get gameTypeNamePhase10 => 'Phase 10';

  @override
  String get gameTypeNamePhase10SortKey => 'Phase 10';

  @override
  String get gameTypeNameFlip7 => 'Flip 7';

  @override
  String get gameTypeNameFlip7SortKey => 'Flip 7';

  @override
  String get gameTypeNameMilleBornes => 'Mille Bornes';

  @override
  String get gameTypeNameMilleBornesSortKey => 'Mille Bornes';

  @override
  String get gameTypeNameRummikub => 'Rummikub';

  @override
  String get gameTypeNameRummikubSortKey => 'Rummikub';

  @override
  String get gameTypeNameSixNimmt => 'Take 6';

  @override
  String get gameTypeNameSixNimmtSortKey => 'Take 6';

  @override
  String get gameTypeNameQwirkle => 'Qwirkle';

  @override
  String get gameTypeNameQwirkleSortKey => 'Qwirkle';

  @override
  String get gameTypeNameFarkle => 'Farkle';

  @override
  String get gameTypeNameFarkleSortKey => 'Farkle';

  @override
  String get gameTypeNameCanasta => 'Canasta';

  @override
  String get gameTypeNameCanastaSortKey => 'Canasta';

  @override
  String get gameTypeNameWizard => 'Wizard';

  @override
  String get gameTypeNameWizardSortKey => 'Wizard';

  @override
  String get gameTypeNameTriomino => 'Triomino';

  @override
  String get gameTypeNameTriominoSortKey => 'Triomino';

  @override
  String get groupDeviceOwner => 'Właściciel';

  @override
  String get groupDeviceMakeOwner => 'Ustaw jako właściciela';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return 'Oddać grupę \"$label\"? To urządzenie nie będzie już mogło usuwać urządzenia ani zmieniać kodu zaproszenia.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return 'Urządzenie \"$label\" teraz jest właścicielem grupy.';
  }

  @override
  String get groupDevicesExplainMember =>
      'Tylko właściciel grupy może usunąć urządzenie lub zmienić kod zaproszenia.';

  @override
  String get groupErrorNotOwner => 'Tylko właściciel grupy może to zrobić';

  @override
  String get whoStarts => 'Kto zaczyna?';

  @override
  String get whoStartsAgain => 'Losuj ponownie';

  @override
  String get diceRoller => 'Rzuć kostką';

  @override
  String get diceCount => 'Liczba kostek';

  @override
  String get diceRollAgain => 'Rzuć ponownie';

  @override
  String diceTotal(int total) {
    return 'Razem: $total';
  }

  @override
  String get resumeGame => 'Wznów';

  @override
  String get recentGames => 'Ostatnie';

  @override
  String get gameInProgress => 'W trakcie';

  @override
  String roundNumber(int number) {
    return 'runda $number';
  }

  @override
  String gameLeader(String name, int score) {
    return '$name prowadzi · $score';
  }

  @override
  String gameWonBy(String name) {
    return 'Wygrał $name';
  }

  @override
  String boardRank(int rank) {
    String _temp0 = intl.Intl.pluralLogic(
      rank,
      locale: localeName,
      other: '#$rank',
      one: '#$rank',
    );
    return '$_temp0';
  }

  @override
  String get boardViewRows => 'Jeden wiersz na gracza';

  @override
  String get boardViewLanes => 'Jedna kolumna na gracza';

  @override
  String get boardSeatOrder => 'Kolejność miejsc';

  @override
  String boardRoundShort(int number) {
    return 'R$number';
  }

  @override
  String get boardPlayer => 'Gracz';

  @override
  String get boardTotal => 'Razem';

  @override
  String get boardLeader => 'Prowadzący';

  @override
  String get groupSettingsTitle => 'Komentarze i użycie';

  @override
  String get groupSettingsDescription =>
      'Styl i język komentarzy, które serwer pisze dla gier grupy. Każdy członek może je zmienić.';

  @override
  String get groupCommentStyle => 'Styl komentarza';

  @override
  String get groupCommentStyleNarrative => 'Narracyjny';

  @override
  String get groupCommentStyleHumorous => 'Humorystyczny';

  @override
  String get groupCommentStyleAnalytical => 'Analityczny';

  @override
  String get groupCommentLanguage => 'Język komentarza';

  @override
  String get groupSettingsSaved => 'Ustawienia grupy zapisane';

  @override
  String get groupUsageTitle => 'Użycie LLM w tym miesiącu';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$used wydane z $budget';
  }

  @override
  String groupUsageResets(String date) {
    return 'Odnawia się $date';
  }

  @override
  String get statsBestWinRate => 'Najlepszy procent zwycięstw';

  @override
  String statsWinsOutOfGames(int wins, int games) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins zwycięstw z $games',
      one: '$wins zwycięstwo z $games',
      zero: 'Brak zwycięstw z $games',
    );
    return '$_temp0';
  }

  @override
  String get statsColumnPlayer => 'Gracz';

  @override
  String get statsColumnGames => 'Gry';

  @override
  String statsUnranked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gry · jeszcze nie ranking',
      one: '$count gra · jeszcze nie ranking',
    );
    return '$_temp0';
  }

  @override
  String statsLeaderboardFooter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Uszeregowany z $count ukończonych gier. Dotknij gracza, aby zobaczyć jego kartę.',
      one:
          'Uszeregowany z $count ukończonej gry. Dotknij gracza, aby zobaczyć jego kartę.',
    );
    return '$_temp0';
  }

  @override
  String statsGamesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'gry',
      one: 'gra',
    );
    return '$_temp0';
  }

  @override
  String statsWinsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'zwycięstwa',
      one: 'zwycięstwo',
    );
    return '$_temp0';
  }

  @override
  String get statsAverageRank => 'średnie miejsce';

  @override
  String statsRankChartTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Miejsce, ostatnie $count gier',
      one: 'Miejsce, ostatnia gra',
    );
    return '$_temp0';
  }

  @override
  String get statsTrendImproving => 'poprawa';

  @override
  String get statsTrendDeclining => 'spadek';

  @override
  String get statsTrendSteady => 'stabilny';

  @override
  String statsRankOrdinal(String rank) {
    String _temp0 = intl.Intl.selectLogic(rank, {
      '1': '1.',
      '2': '2.',
      '3': '3.',
      'other': '$rank.',
    });
    return '$_temp0';
  }

  @override
  String statsWinStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seria: $count zwycięstw',
      one: 'Seria: $count zwycięstwo',
      zero: 'Brak zwycięskiej serii',
    );
    return '$_temp0';
  }

  @override
  String statsRecord(int total) {
    return 'Najlepiej: $total';
  }

  @override
  String statsOnGameType(String gameType) {
    return 'Na $gameType';
  }

  @override
  String get statsAverageTotal => 'Średni wynik końcowy';

  @override
  String get statsBestTotal => 'Najlepszy wynik końcowy';

  @override
  String get statsMostBeaten => 'Najczęściej pokonywany przeciwnik';

  @override
  String get statsOpenPlayerCard => 'otwórz kartę gracza';

  @override
  String get shareResult => 'Udostępnij wynik';

  @override
  String get shareAnalysis => 'Udostępnij analizę';

  @override
  String shareResultSubject(String gameName) {
    return 'Wynik: $gameName';
  }

  @override
  String shareResultTitle(String date) {
    return 'Gra z $date';
  }

  @override
  String shareResultStanding(int rank, String name, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points punktów',
      one: '$points punkt',
    );
    return '$rank. $name — $_temp0';
  }

  @override
  String shareResultFooter(String appName, String url) {
    return 'Wyniki śledzone za pomocą $appName: $url';
  }

  @override
  String get shareFailed => 'Udostępnianie nie mogło być otwarte';

  @override
  String get newGameNameLabel => 'Nazwa';

  @override
  String get newGameGameLabel => 'Gra';

  @override
  String newGameAllGames(int count) {
    return 'Wszystkie gry ($count)';
  }

  @override
  String get newGamePlayersLabel => 'Gracze · kolejność miejsc';

  @override
  String get newGameDragToReorder => 'przeciągnij, aby zmienić kolejność';

  @override
  String get newGameDealer => 'rozdaje';

  @override
  String get newGameAddPlayer => 'Dodaj gracza';

  @override
  String newGameStart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rozpocznij · $count graczy',
      one: 'Rozpocznij · 1 gracz',
      zero: 'Rozpocznij',
    );
    return '$_temp0';
  }

  @override
  String get whoIsPlayingTitle => 'Kto gra?';

  @override
  String get whoIsPlayingSearchHint => 'Nazwa lub nowy gracz';

  @override
  String get whoIsPlayingFrequent => 'Często gra z tobą';

  @override
  String whoIsPlayingSameAs(String gameName) {
    return 'Ci sami gracze co \"$gameName\"';
  }

  @override
  String whoIsPlayingCreate(String name) {
    return 'Utwórz \"$name\"';
  }

  @override
  String whoIsPlayingConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dodaj $count graczy',
      one: 'Dodaj 1 gracza',
      zero: 'Gotowe',
    );
    return '$_temp0';
  }

  @override
  String defaultGameName(int number) {
    return 'Gra $number';
  }

  @override
  String get pwaUpdateReady => 'Nowa wersja CountScore jest gotowa';

  @override
  String get pwaUpdateReload => 'Załaduj ponownie';

  @override
  String get thresholdIsRequired => 'Próg jest wymagany dla tego warunku';

  @override
  String thresholdTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Próg nie może być większy niż $maxString';
  }

  @override
  String get deletionImpossible => 'Usunięcie niemożliwe';

  @override
  String gameTypeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gier używa tego typu: nie można go usunąć.',
      one: '1 gra używa tego typu: nie można go usunąć.',
    );
    return '$_temp0';
  }

  @override
  String confirmDeleteGameType(String name) {
    return 'Czy naprawdę chcesz usunąć rodzaj gry \"$name\"?';
  }

  @override
  String get winDirectionChangeTitle => 'Odwrócić, kto wygrywa?';

  @override
  String winDirectionChangeWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ukończone gry tego typu będą miały odwróconą kolejność: ich zwycięzcy stają się ostatni.',
      one: '1 ukończona gra tego typu będzie miała odwróconą kolejność: jej zwycięzca staje się ostatni.',
    );
    return '$_temp0';
  }

  @override
  String get winDirectionContradiction =>
      'Warunek końca gry nagradza przeciwieństwo wybranego zwycięzcy. Domowa reguła może chcieć dokładnie tego.';

  @override
  String get rulesOutOfDateTitle => 'Zaktualizować zasady?';

  @override
  String get rulesOutOfDateMessage =>
      'Zasady tego typu nadal opisują stary warunek.';

  @override
  String get later => 'Później';

  @override
  String get currentIcon => 'Bieżąca ikona';

  @override
  String get currentColor => 'Bieżący kolor';

  @override
  String get groupDeviceClaimOwner => 'Przejmij własność';

  @override
  String groupDeviceClaimOwnerConfirm(String label) {
    return 'Urządzenie \"$label\" jest właścicielem grupy, ale nie było widać od długiego czasu. Przejąć własność na tym urządzeniu?';
  }

  @override
  String get groupDeviceOwnerClaimed =>
      'To urządzenie jest teraz właścicielem grupy.';

  @override
  String get groupErrorOwnerActive =>
      'Właściciel grupy był niedawno widzany: nie można przejąć własności.';

  @override
  String get groupCreatedOwnerExplain =>
      'Grupa utworzona. To urządzenie jest jej właścicielem; rola może być przekazana innej w Urządzenia.';

  @override
  String get boardEliminated => 'Wyeliminowany';

  @override
  String get soundsSection => 'Dźwięki';

  @override
  String get gameSounds => 'Dźwięki gry';

  @override
  String get gameSoundsDescription =>
      'Dźwięk, gdy gracz jest wyeliminowany, gdy gra jest wygrywana i gdy czasomierz się kończy';

  @override
  String get turnTimer => 'Czasomierz rundy';

  @override
  String get turnTimerLess => 'Mniej czasu';

  @override
  String get turnTimerMore => 'Więcej czasu';

  @override
  String get turnTimerStart => 'Rozpocznij';

  @override
  String get turnTimerPause => 'Pauza';

  @override
  String get turnTimerReset => 'Reset';

  @override
  String get turnTimerTimeUp => 'Koniec czasu!';

  @override
  String get configShareOpen => 'Udostępnij kod QR';

  @override
  String get configShareTitle => 'Udostępnij tę konfigurację';

  @override
  String get configShareExplainServer =>
      'Zeskanuj ten kod innym telefonem, aby skonfigurować go z tym samym serwerem.';

  @override
  String configShareExplainGroup(String name) {
    return 'Zeskanuj ten kod innym telefonem, aby skonfigurować go z tym samym serwerem i dołączyć do grupy $name. Zawiera kod zaproszenia grupy: pokaż go tylko osobom, które chcesz w grupie.';
  }

  @override
  String get configShareWebAppLabel => 'Adres aplikacji internetowej';

  @override
  String get configShareWebAppHelper =>
      'Gdzie twój serwer obsługuje aplikację internetową CountScore, na przykład https://countscore.example.com/countscore. Kod otwiera tę stronę.';

  @override
  String get configShareWebAppNeeded =>
      'Wpisz adres aplikacji internetowej, aby pokazać kod.';

  @override
  String get configShareQrLabel => 'Kod QR konfiguracji linku';

  @override
  String get configShareCopyLink => 'Skopiuj link';

  @override
  String get configShareLinkCopied => 'Link skopiowany';

  @override
  String get configShareTooLong =>
      'Ten link jest za długi, aby zmieścić się w kodzie QR. Zamiast tego użyj \"Skopiuj link\".';

  @override
  String get replaceConfigTitle => 'Zastąpić konfigurację?';

  @override
  String replaceConfigCurrent(String value) {
    return 'Teraz: $value';
  }

  @override
  String replaceConfigNew(String value) {
    return 'Nowe: $value';
  }

  @override
  String replaceConfigInvite(String code) {
    return 'kod zaproszenia $code';
  }

  @override
  String replaceConfigLeavesGroup(String name) {
    return 'To urządzenie opuści grupę $name. Jego gry pozostają na tym urządzeniu.';
  }

  @override
  String get replaceConfigConfirm => 'Zastąp';

  @override
  String replaceConfigUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count zmian na tym urządzeniu nie dotarły jeszcze do grupy. Jeśli teraz opuścisz, grupa nigdy ich nie otrzyma.',
      one: '1 zmiana na tym urządzeniu nie dotarła jeszcze do grupy. Jeśli teraz opuścisz, grupa nigdy jej nie otrzyma.',
    );
    return '$_temp0';
  }

  @override
  String get replaceConfigLeaveAnyway => 'Opuść mimo to';

  @override
  String get replaceConfigDone => 'Konfiguracja zastąpiona';

  @override
  String get replaceConfigUnchanged =>
      'To urządzenie już używa tej konfiguracji';

  @override
  String get joinLinkHandOverMessage =>
      'Ten link może się otworzyć w aplikacji CountScore Android. Jeśli aplikacja nie jest zainstalowana, zamiast tego otworzy się Play Store.';

  @override
  String get joinLinkOpenInApp => 'Otwórz w aplikacji';

  @override
  String get joinLinkContinueHere => 'Kontynuuj w przeglądarce';
}
