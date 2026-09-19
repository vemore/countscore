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
  String get newWithSamePlayers => 'Nuevo con los mismos jugadores';

  @override
  String get playAgain => 'Volver a jugar';

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
  String get filterGames => 'Filtrar partidas';

  @override
  String get applyFilter => 'Aplicar';

  @override
  String get resetFilter => 'Restablecer';

  @override
  String get selectGameType => 'Seleccione un tipo de juego';

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
  String get editGame => 'Modificar partida';

  @override
  String get editGameDialogTitle => 'Modificar partida';

  @override
  String get gameSettings => 'Configuración de la partida';

  @override
  String get removePlayer => 'Quitar jugador';

  @override
  String get addPlayerToGame => 'Añadir jugador';

  @override
  String get warningRemovePlayer =>
      '¡Atención! Quitar este jugador eliminará todas sus puntuaciones de esta partida. Esta acción es irreversible.';

  @override
  String confirmRemovePlayer(String playerName) {
    return '¿Realmente deseas quitar a $playerName de esta partida?';
  }

  @override
  String get playerRemoved => 'Jugador quitado de la partida';

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
  String boardRoundButton(int round) {
    return 'Ronda $round';
  }

  @override
  String keypadCaption(String player, int round) {
    return '$player · ronda $round';
  }

  @override
  String keypadCaptionWithPosition(
    String player,
    int round,
    int position,
    int count,
  ) {
    return '$player · ronda $round · $position/$count';
  }

  @override
  String keypadTotalAfter(int total) {
    return 'total después: $total';
  }

  @override
  String keypadNext(String player) {
    return 'Siguiente: $player';
  }

  @override
  String get keypadValidateRound => 'Validar ronda';

  @override
  String get keypadZeroZapZap => '0 ZapZap';

  @override
  String get keypadToggleSign => 'Cambiar signo';

  @override
  String get keypadBackspace => 'Borrar un dígito';

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
  String version(String version) {
    return 'Versión $version';
  }

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
  String get featureGroupSharing => 'Compartir en grupo';

  @override
  String get featureGameAnalysis => 'Análisis de partidas con IA';

  @override
  String get rateApp => 'Valorar CountScore';

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
  String get searchOrCreate => 'Buscar / Crear';

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
  String get continuePlay => 'Continuar jugando';

  @override
  String gameEndWinner(String name) {
    return 'Gana $name';
  }

  @override
  String gameEndTie(String names) {
    return 'Empate: $names';
  }

  @override
  String gameEndRounds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rondas',
      one: '$count ronda',
    );
    return '$_temp0';
  }

  @override
  String get gameEndLowestWins => 'gana la puntuación más baja';

  @override
  String get gameEndHighestWins => 'gana la puntuación más alta';

  @override
  String get gameEndAnalysis => 'Análisis';

  @override
  String get gameEndResults => 'Resultados';

  @override
  String get endGame => 'Terminar juego';

  @override
  String get reopenGame => 'Reabrir juego';

  @override
  String get gameFinished => 'Finalizado';

  @override
  String get undo => 'Deshacer';

  @override
  String get gameReopened => 'Partida reabierta';

  @override
  String get comment => 'Comentario';

  @override
  String get enterComment => 'Escribir un comentario';

  @override
  String get analyzeGame => 'Analizar partida';

  @override
  String get analysisTitle => 'Análisis de la partida';

  @override
  String get analysisStyle => 'Estilo de análisis';

  @override
  String get analysisStyleProfessor => 'El profesor';

  @override
  String get analysisStyleCommentator => 'El comentarista deportivo';

  @override
  String get analysisStyleDocumentary => 'El documental de naturaleza';

  @override
  String get analysisStyleNoir => 'El detective';

  @override
  String get analysisStyleBard => 'El bardo';

  @override
  String get analysisStyleCoach => 'El entrenador';

  @override
  String get analysisStyleConsultant => 'El consultor';

  @override
  String get analysisStyleAstrologer => 'El astrólogo';

  @override
  String get analysisStyleRealityTv => 'El reality';

  @override
  String get generatingAnalysis => 'Generando análisis…';

  @override
  String get generateAnalysis => 'Generar análisis';

  @override
  String get regenerateAnalysis => 'Regenerar análisis';

  @override
  String get deleteAnalysis => 'Eliminar análisis';

  @override
  String get confirmRegenerateAnalysis =>
      '¿Regenerar? El análisis actual será reemplazado.';

  @override
  String get confirmDeleteAnalysis => '¿Eliminar el análisis de esta partida?';

  @override
  String get analysisError => 'Error al generar el análisis';

  @override
  String get analysisErrorUnavailable =>
      'El servidor de análisis no está disponible temporalmente. Inténtelo más tarde.';

  @override
  String analysisErrorStatus(int status) {
    return 'Error al generar el análisis (HTTP $status)';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String analysisGeneratedAt(String date) {
    return 'Generado el $date';
  }

  @override
  String get serverSection => 'Servidor';

  @override
  String get backendUrlLabel => 'URL del servidor';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'Las funciones conectadas requieren un servidor CountScore. Instala uno desde la carpeta backend/ e introduce aquí su dirección. Sin servidor, ningún dato sale de este dispositivo.';

  @override
  String get backendNotConfigured => 'Ningún servidor configurado';

  @override
  String get backendUrlInvalid =>
      'Dirección no válida. Introduce una URL completa, por ejemplo https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// solo se acepta en una red local. Usa https:// para un servidor público.';

  @override
  String get testConnection => 'Probar la conexión';

  @override
  String get connectionOk => 'El servidor responde';

  @override
  String get connectionFailed => 'El servidor no responde';

  @override
  String get serverUrlSaved => 'Servidor guardado';

  @override
  String get analysisRequiresBackend =>
      'Este análisis requiere un servidor. Configura uno en los ajustes.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get serverUrlCleared => 'Servidor borrado';

  @override
  String get groupSection => 'Grupo';

  @override
  String get groupDescription =>
      'Comparte partidas con los demás dispositivos del grupo. Las partidas compartidas, sus jugadores, puntuaciones, comentarios y análisis se envían a tu servidor; las demás partidas se quedan en este dispositivo.';

  @override
  String get groupNeedsServer => 'Primero configura un servidor arriba.';

  @override
  String get groupCreate => 'Crear un grupo';

  @override
  String get groupJoin => 'Unirse a un grupo';

  @override
  String get groupNameLabel => 'Nombre del grupo';

  @override
  String get deviceLabelLabel => 'Nombre de este dispositivo';

  @override
  String get deviceLabelDefault => 'Mi dispositivo';

  @override
  String get shareTokenLabel => 'Código de invitación';

  @override
  String get shareTokenHint =>
      'Pega el código que te envió un miembro del grupo';

  @override
  String groupCurrent(String name) {
    return 'Grupo: $name';
  }

  @override
  String get shareTokenExplain =>
      'Envía este código a los dispositivos que deban unirse al grupo. Cualquiera que lo tenga puede unirse.';

  @override
  String get shareTokenCopy => 'Copiar código';

  @override
  String get shareTokenCopied => 'Código copiado';

  @override
  String get shareTokenRotate => 'Nuevo código';

  @override
  String get shareTokenRotateConfirm =>
      'El código anterior dejará de servir para unirse. Los dispositivos que ya están en el grupo no se ven afectados.';

  @override
  String get groupLeave => 'Salir del grupo';

  @override
  String get groupLeaveConfirm =>
      'Este dispositivo sale del grupo. Las partidas compartidas se quedan en este dispositivo, pero dejarán de sincronizarse.';

  @override
  String get groupLeft => 'Has salido del grupo';

  @override
  String get groupJoined => 'Te has unido al grupo';

  @override
  String get clearServerLeavesGroup =>
      'Borrar el servidor hace salir del grupo. Las partidas compartidas se quedan en este dispositivo.';

  @override
  String get syncNow => 'Sincronizar';

  @override
  String syncStatusIdle(String time) {
    return 'Sincronizado a las $time';
  }

  @override
  String get syncStatusSyncing => 'Sincronizando…';

  @override
  String get syncStatusOffline =>
      'Servidor inaccesible: los cambios se enviarán más tarde';

  @override
  String get syncStatusUnauthorized =>
      'El servidor ya no acepta este dispositivo. Sal del grupo y vuelve a unirte.';

  @override
  String get syncStatusError => 'Error del servidor durante la sincronización';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cambios pendientes',
      one: '1 cambio pendiente',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cambios rechazados por el servidor',
      one: '1 cambio rechazado por el servidor',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken =>
      'Código de invitación desconocido o reemplazado';

  @override
  String get groupErrorRateLimited =>
      'Demasiados intentos. Vuelve a intentarlo en un minuto.';

  @override
  String get groupErrorUnreachable => 'Servidor inaccesible';

  @override
  String get groupErrorServer => 'Error del servidor';

  @override
  String get shareWithGroup => 'Compartir con el grupo';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'Los dispositivos de $name verán y editarán esta partida';
  }

  @override
  String shareGameConfirm(String name) {
    return 'La partida, sus jugadores, puntuaciones y comentarios se enviarán a $name. No se puede deshacer.';
  }

  @override
  String get gameSharedDone => 'Partida compartida con el grupo';

  @override
  String get gameSharedBadge => 'Partida compartida';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'Estos nombres no se pueden compartir: $names. Usa letras, dígitos, espacios, guiones, apóstrofos o puntos (32 caracteres como máximo).';
  }

  @override
  String roundRenumbered(int number) {
    return 'Esa ronda ya se había introducido en otro dispositivo, así que pasa a ser la ronda $number.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return 'La partida «$name» se eliminó en otro dispositivo';
  }

  @override
  String get groupDevices => 'Dispositivos';

  @override
  String get groupDevicesExplain =>
      'Aquí puedes quitar del grupo un teléfono perdido o vendido.';

  @override
  String get groupDeviceThisOne => 'Este dispositivo';

  @override
  String groupDeviceLastSeen(String date) {
    return 'Visto por última vez: $date';
  }

  @override
  String get groupDeviceRevoke => 'Quitar';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return '¿Quitar «$label» del grupo? Dejará de sincronizar. El código de invitación también cambia: los miembros conservan el acceso, pero habrá que compartir el nuevo código para invitar a alguien.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '«$label» se ha quitado. El código de invitación ha cambiado.';
  }

  @override
  String get reportCommentary => 'Denunciar este comentario';

  @override
  String get reportCommentarySubject =>
      'CountScore — denuncia de un comentario de IA';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return '¿Qué problema tiene este comentario generado por IA?\n\n\n---\nReferencia: $reference\nComentario:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'No se encontró ninguna aplicación de correo. Escribe a $email para denunciar este comentario.';
  }

  @override
  String get gameRulesTitle => 'Reglas del juego';

  @override
  String get gameRulesInApp => 'En CountScore';

  @override
  String get gameRulesSection => 'Las reglas';

  @override
  String get gameRulesNoElimination => 'Sin eliminación durante la partida';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'Un jugador queda eliminado al superar los $threshold puntos';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'Un jugador queda eliminado por debajo de $threshold puntos';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'La partida termina en cuanto un jugador alcanza los $threshold puntos';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'La partida termina en cuanto un jugador baja de $threshold puntos';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'La partida termina cuando todos los jugadores menos uno superan los $threshold puntos';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'La partida termina cuando todos los jugadores menos uno bajan de $threshold puntos';
  }

  @override
  String get gameRulesNoEnd =>
      'Sin final automático: tú decides cuándo termina la partida';

  @override
  String get gameRulesEmptyTitle => 'Todavía no hay reglas';

  @override
  String get gameRulesEmptyHint =>
      'Anota cómo cuenta los puntos tu mesa: así todos tendréis la misma versión.';

  @override
  String get gameRulesWrite => 'Escribir las reglas';

  @override
  String get gameRulesEditTitle => 'Editar las reglas';

  @override
  String get gameRulesEditorHint =>
      'Las reglas de tu mesa. Se admite Markdown.';

  @override
  String get gameRulesFromGroup => 'Reglas de tu grupo';

  @override
  String get gameRulesRestoreDefault => 'Restaurar las reglas originales';

  @override
  String get gameRulesSaved => 'Reglas guardadas';

  @override
  String get gameRulesRestored => 'Reglas originales restauradas';

  @override
  String get gameRulesDisclaimer =>
      'Resumen redactado para CountScore a partir de las reglas tal como se juegan habitualmente. Los nombres de los juegos pertenecen a sus propietarios y se citan solo de forma descriptiva.';

  @override
  String get gameTypeNameZapzap => 'ZapZap';

  @override
  String get gameTypeNameUno => 'Uno';

  @override
  String get gameTypeNameScrabble => 'Scrabble';

  @override
  String get gameTypeNameOther => 'Otro';

  @override
  String get gameTypeNameSkyjo => 'Skyjo';

  @override
  String get gameTypeNamePresident => 'Presidente';

  @override
  String get gameTypeNameBelote => 'Belote';

  @override
  String get gameTypeNameTarot => 'Tarot';

  @override
  String get gameTypeNameBridge => 'Bridge';

  @override
  String get gameTypeNameRami => 'Rummy';

  @override
  String get gameTypeNameCoinche => 'Coinche';

  @override
  String get gameTypeNameYahtzee => 'Yahtzee';

  @override
  String get gameTypeNamePhase10 => 'Phase 10';

  @override
  String get gameTypeNameFlip7 => 'Flip 7';

  @override
  String get gameTypeNameMilleBornes => 'Mille Bornes';

  @override
  String get gameTypeNameRummikub => 'Rummikub';

  @override
  String get gameTypeNameSixNimmt => '¡Toma 6!';

  @override
  String get gameTypeNameQwirkle => 'Qwirkle';

  @override
  String get gameTypeNameFarkle => 'Farkle';

  @override
  String get gameTypeNameCanasta => 'Canasta';

  @override
  String get gameTypeNameWizard => 'Wizard';

  @override
  String get gameTypeNameTriomino => 'Triomino';

  @override
  String get groupDeviceOwner => 'Propietario';

  @override
  String get groupDeviceMakeOwner => 'Hacer propietario';

  @override
  String groupDeviceMakeOwnerConfirm(String label) {
    return '¿Ceder el grupo a «$label»? Este dispositivo ya no podrá quitar dispositivos ni cambiar el código de invitación.';
  }

  @override
  String groupDeviceOwnerChanged(String label) {
    return '«$label» es ahora el propietario del grupo.';
  }

  @override
  String get groupDevicesExplainMember =>
      'Solo el propietario del grupo puede quitar un dispositivo o cambiar el código de invitación.';

  @override
  String get groupErrorNotOwner =>
      'Solo el propietario del grupo puede hacerlo';

  @override
  String get whoStarts => '¿Quién empieza?';

  @override
  String get whoStartsAgain => 'Sortear de nuevo';

  @override
  String get resumeGame => 'Reanudar';

  @override
  String get recentGames => 'Recientes';

  @override
  String get gameInProgress => 'En curso';

  @override
  String roundNumber(int number) {
    return 'ronda $number';
  }

  @override
  String gameLeader(String name, int score) {
    return '$name va en cabeza · $score';
  }

  @override
  String gameWonBy(String name) {
    return 'Ganada por $name';
  }

  @override
  String boardRank(int rank) {
    String _temp0 = intl.Intl.pluralLogic(
      rank,
      locale: localeName,
      other: '$rank.º',
      one: '$rank.º',
    );
    return '$_temp0';
  }

  @override
  String get boardViewRows => 'Una fila por jugador';

  @override
  String get boardViewLanes => 'Una columna por jugador';

  @override
  String get boardSeatOrder => 'Orden de juego';

  @override
  String boardRoundShort(int number) {
    return 'M$number';
  }

  @override
  String get boardPlayer => 'Jugador';

  @override
  String get boardTotal => 'Puntos';

  @override
  String get boardLeader => 'En cabeza';

  @override
  String get groupSettingsTitle => 'Comentarios y consumo';

  @override
  String get groupSettingsDescription =>
      'El estilo y el idioma de los comentarios que el servidor escribe para las partidas del grupo. Cualquier miembro puede cambiarlos.';

  @override
  String get groupCommentStyle => 'Estilo de los comentarios';

  @override
  String get groupCommentStyleNarrative => 'Narrativo';

  @override
  String get groupCommentStyleHumorous => 'Humorístico';

  @override
  String get groupCommentStyleAnalytical => 'Analítico';

  @override
  String get groupCommentLanguage => 'Idioma de los comentarios';

  @override
  String get groupSettingsSaved => 'Ajustes del grupo guardados';

  @override
  String get groupUsageTitle => 'Consumo del LLM este mes';

  @override
  String groupUsageAmount(String used, String budget) {
    return '$used gastados de $budget';
  }

  @override
  String groupUsageResets(String date) {
    return 'Se reinicia el $date';
  }
}
