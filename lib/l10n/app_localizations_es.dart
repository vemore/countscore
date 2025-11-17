// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'Inicio';

  @override
  String get playersListTitle => 'Lista de Jugadores';

  @override
  String get gameTypesTitle => 'Tipos de Juego';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get newGame => 'Nuevo Juego';

  @override
  String get noGames => 'Sin juegos';

  @override
  String get noGamesOfThisType => 'No hay juegos de este tipo';

  @override
  String get createFirstGame => 'Crea tu primer juego';

  @override
  String get createdOn => 'Creado el';

  @override
  String get newWithSamePlayers => 'Nuevo con los mismos jugadores';

  @override
  String get newGameSuffix => '(nuevo)';

  @override
  String get rename => 'Renombrar';

  @override
  String get delete => 'Eliminar';

  @override
  String get confirmDeletion => 'Confirmar eliminación';

  @override
  String confirmDeleteGame(String name) {
    return '¿Realmente deseas eliminar el juego \"$name\"?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get renameGame => 'Renombrar juego';

  @override
  String get gameName => 'Nombre del juego';

  @override
  String get save => 'Guardar';

  @override
  String get filterByGameType => 'Filtrar por tipo de juego';

  @override
  String get allGames => 'Todos los juegos';

  @override
  String get gameType => 'Tipo de juego';

  @override
  String get loadingGameTypes => 'Cargando tipos de juego...';

  @override
  String get winRule => 'Regla de victoria';

  @override
  String get lowestScoreWins => 'Gana la puntuación más baja';

  @override
  String get highestScoreWins => 'Gana la puntuación más alta';

  @override
  String get lowestScoreExample => 'Ej: Golf, Corazones';

  @override
  String get highestScoreExample => 'Ej: Rummy, Bridge';

  @override
  String get players => 'Jugadores';

  @override
  String get add => 'Agregar';

  @override
  String get pleaseEnterName => 'Por favor ingresa un nombre';

  @override
  String get atLeast2PlayersRequired => 'Se requieren al menos 2 jugadores';

  @override
  String playerNumber(int index) {
    return 'Jugador $index';
  }

  @override
  String get selectPlayer => 'Seleccionar un jugador...';

  @override
  String get clear => 'Limpiar';

  @override
  String get remove => 'Eliminar';

  @override
  String get createGame => 'Crear juego';

  @override
  String get game => 'Juego';

  @override
  String get deleteLastRound => 'Eliminar última ronda';

  @override
  String get confirm => 'Confirmar';

  @override
  String get confirmDeleteLastRound => '¿Eliminar la última ronda?';

  @override
  String get noPlayersInGame => 'No hay jugadores en este juego';

  @override
  String get round => 'Ronda';

  @override
  String get addRound => 'Agregar ronda';

  @override
  String get score => 'Puntuación';

  @override
  String get enterScore => 'Ingresar puntuación';

  @override
  String get appearance => 'Apariencia';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get system => 'Sistema';

  @override
  String get screen => 'Pantalla';

  @override
  String get keepScreenAwake => 'Mantener pantalla activa';

  @override
  String get keepScreenAwakeDescription =>
      'Evita que la pantalla se apague durante un juego';

  @override
  String get backup => 'Respaldo';

  @override
  String get exportDatabase => 'Exportar base de datos';

  @override
  String get exportDatabaseDescription =>
      'Guarda todos tus juegos en un archivo';

  @override
  String get databaseExportedTo => 'Base de datos exportada a:';

  @override
  String get errorDuringExport => 'Error durante la exportación:';

  @override
  String get importDatabase => 'Importar base de datos';

  @override
  String get importDatabaseDescription =>
      'Restaura tus juegos desde un archivo de respaldo';

  @override
  String get confirmation => 'Confirmación';

  @override
  String get importWarning =>
      'La importación reemplazará todos tus datos actuales. Se creará un respaldo automático antes de importar.\n\n¿Deseas continuar?';

  @override
  String get import => 'Importar';

  @override
  String get databaseImportedSuccessfully =>
      'Base de datos importada exitosamente';

  @override
  String get importSuccessful => 'Importación exitosa';

  @override
  String get importSuccessMessage =>
      'La base de datos se ha importado exitosamente.\n\nLa aplicación se cerrará ahora. Por favor ábrela de nuevo para ver los nuevos datos.';

  @override
  String get ok => 'Aceptar';

  @override
  String get errorDuringImport => 'Error durante la importación:';

  @override
  String get noPlayers => 'Sin jugadores';

  @override
  String playersListSummary(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores: $names',
      one: '1 jugador: $names',
      zero: 'Sin jugadores',
    );
    return '$_temp0';
  }

  @override
  String get playersAppearMessage =>
      'Los jugadores aparecerán aquí una vez\nque hayas creado juegos';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count juegos',
      one: '1 juego',
      zero: '0 juegos',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count victorias',
      one: '1 victoria',
      zero: '0 victorias',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'Cambiar color';

  @override
  String get renamePlayer => 'Renombrar jugador';

  @override
  String get newName => 'Nuevo nombre';

  @override
  String playerRenamedTo(String name) {
    return 'Jugador renombrado a \"$name\"';
  }

  @override
  String get deletePlayer => 'Eliminar jugador';

  @override
  String confirmDeletePlayer(String name, int count) {
    return '¿Realmente deseas eliminar a \"$name\"?\n\nEste jugador será eliminado de todos los $count juego(s).';
  }

  @override
  String playerDeleted(String name) {
    return 'Jugador \"$name\" eliminado';
  }

  @override
  String get chooseColor => 'Elegir un color';

  @override
  String get noGameTypes => 'Sin tipos de juego';

  @override
  String get predefined => 'Predeterminado';

  @override
  String get edit => 'Editar';

  @override
  String get newType => 'Nuevo tipo';

  @override
  String get editType => 'Editar tipo';

  @override
  String get newGameType => 'Nuevo tipo de juego';

  @override
  String get gameTypeName => 'Nombre del tipo de juego';

  @override
  String get icon => 'Ícono:';

  @override
  String get color => 'Color:';

  @override
  String get chooseIcon => 'Elegir un ícono';

  @override
  String get nameIsRequired => 'El nombre es obligatorio';

  @override
  String get create => 'Crear';

  @override
  String get ranking => 'Clasificación';

  @override
  String get noCurrentGame => 'No hay juego actual';

  @override
  String get noScoresRecorded => 'No hay puntuaciones registradas';

  @override
  String get playerStatistics => 'Estadísticas del Jugador';

  @override
  String get noStatisticsAvailable => 'No hay estadísticas disponibles';

  @override
  String get gamesPlayed => 'Juegos jugados';

  @override
  String get wins => 'Victorias';

  @override
  String get winRate => 'Tasa de victorias';

  @override
  String get overallStatistics => 'Estadísticas Generales';

  @override
  String get byGameType => 'Por tipo de juego';

  @override
  String get rate => 'Tasa';

  @override
  String get version => 'Versión 1.0.0';

  @override
  String get appDescription =>
      'Aplicación de gestión de puntuaciones para tus sesiones de juego por Vincent Moreau';

  @override
  String get features => 'Características';

  @override
  String get featureDifferentGameTypes => 'Diferentes tipos de juego';

  @override
  String get featurePlayerManagement => 'Gestión de jugadores';

  @override
  String get featureDetailedStatistics => 'Estadísticas detalladas';

  @override
  String get featureCustomization => 'Personalización';

  @override
  String get featureDarkLightTheme => 'Tema oscuro/claro';

  @override
  String get credits => 'Créditos';

  @override
  String get appIconCredit => 'Ícono de la aplicación';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get selectPlayerDialogTitle => 'Seleccionar un jugador';

  @override
  String get search => 'Buscar';

  @override
  String get createNewPlayer => 'Crear nuevo jugador';

  @override
  String get newPlayerName => 'Nombre del nuevo jugador';

  @override
  String get noPlayersFound => 'No se encontraron jugadores';

  @override
  String get allPlayersSelected => 'Todos los jugadores han sido seleccionados';

  @override
  String get close => 'Cerrar';

  @override
  String get playerEliminationCondition =>
      'Condición de eliminación del jugador';

  @override
  String get gameOverCondition => 'Condición de fin del juego';

  @override
  String get none => 'Ninguna';

  @override
  String get overThreshold => 'Por encima del umbral';

  @override
  String get underThreshold => 'Por debajo del umbral';

  @override
  String get firstPlayerOver => 'Primer jugador por encima';

  @override
  String get firstPlayerUnder => 'Primer jugador por debajo';

  @override
  String get lastPlayerOver => 'Último jugador por encima';

  @override
  String get lastPlayerUnder => 'Último jugador por debajo';

  @override
  String get threshold => 'Umbral';

  @override
  String get conditionType => 'Tipo de condición';

  @override
  String get gameOverTitle => '¡Fin del juego!';

  @override
  String get gameOverMessage =>
      'Se alcanzó la condición de fin del juego. ¿Terminar ahora?';

  @override
  String get continuePlay => 'Continuar jugando';

  @override
  String get endGame => 'Terminar juego';
}
