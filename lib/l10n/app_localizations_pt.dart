// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'CountScore';

  @override
  String get homeTitle => 'Início';

  @override
  String get playersListTitle => 'Lista de Jogadores';

  @override
  String get gameTypesTitle => 'Tipos de Jogo';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get newGame => 'Novo Jogo';

  @override
  String get noGames => 'Sem jogos';

  @override
  String get noGamesOfThisType => 'Sem jogos deste tipo';

  @override
  String get createFirstGame => 'Crie seu primeiro jogo';

  @override
  String get createdOn => 'Criado em';

  @override
  String get newWithSamePlayers => 'Novo com os mesmos jogadores';

  @override
  String get newGameSuffix => '(novo)';

  @override
  String get rename => 'Renomear';

  @override
  String get delete => 'Excluir';

  @override
  String get confirmDeletion => 'Confirmar exclusão';

  @override
  String confirmDeleteGame(String name) {
    return 'Você realmente deseja excluir o jogo \"$name\"?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get renameGame => 'Renomear jogo';

  @override
  String get gameName => 'Nome do jogo';

  @override
  String get save => 'Salvar';

  @override
  String get filterByGameType => 'Filtrar por tipo de jogo';

  @override
  String get allGames => 'Todos os jogos';

  @override
  String get filterGames => 'Filtrar partidas';

  @override
  String get applyFilter => 'Aplicar';

  @override
  String get resetFilter => 'Redefinir';

  @override
  String get selectGameType => 'Selecione um tipo de jogo';

  @override
  String get gameType => 'Tipo de jogo';

  @override
  String get loadingGameTypes => 'Carregando tipos de jogo...';

  @override
  String get winRule => 'Regra de vitória';

  @override
  String get lowestScoreWins => 'Menor pontuação ganha';

  @override
  String get highestScoreWins => 'Maior pontuação ganha';

  @override
  String get lowestScoreExample => 'Ex: Golfe, Copas';

  @override
  String get highestScoreExample => 'Ex: Buraco, Bridge';

  @override
  String get players => 'Jogadores';

  @override
  String get add => 'Adicionar';

  @override
  String get pleaseEnterName => 'Por favor, insira um nome';

  @override
  String get atLeast2PlayersRequired =>
      'São necessários pelo menos 2 jogadores';

  @override
  String playerNumber(int index) {
    return 'Jogador $index';
  }

  @override
  String get selectPlayer => 'Selecione um jogador...';

  @override
  String get clear => 'Limpar';

  @override
  String get remove => 'Remover';

  @override
  String get createGame => 'Criar jogo';

  @override
  String get game => 'Jogo';

  @override
  String get editGame => 'Editar partida';

  @override
  String get editGameDialogTitle => 'Editar partida';

  @override
  String get gameSettings => 'Configurações da partida';

  @override
  String get removePlayer => 'Remover jogador';

  @override
  String get addPlayerToGame => 'Adicionar jogador';

  @override
  String get warningRemovePlayer =>
      'Atenção! Remover este jogador excluirá todas as suas pontuações desta partida. Esta ação é irreversível.';

  @override
  String confirmRemovePlayer(String playerName) {
    return 'Você realmente deseja remover $playerName desta partida?';
  }

  @override
  String get playerRemoved => 'Jogador removido da partida';

  @override
  String get deleteLastRound => 'Excluir última rodada';

  @override
  String get confirm => 'Confirmar';

  @override
  String get confirmDeleteLastRound => 'Excluir a última rodada?';

  @override
  String get noPlayersInGame => 'Não há jogadores neste jogo';

  @override
  String get round => 'Rodada';

  @override
  String get addRound => 'Adicionar rodada';

  @override
  String get score => 'Pontuação';

  @override
  String get enterScore => 'Inserir pontuação';

  @override
  String get appearance => 'Aparência';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get system => 'Sistema';

  @override
  String get screen => 'Tela';

  @override
  String get keepScreenAwake => 'Manter tela ativa';

  @override
  String get keepScreenAwakeDescription =>
      'Impede que a tela desligue durante um jogo';

  @override
  String get backup => 'Backup';

  @override
  String get exportDatabase => 'Exportar banco de dados';

  @override
  String get exportDatabaseDescription =>
      'Salve todos os seus jogos em um arquivo';

  @override
  String get databaseExportedTo => 'Banco de dados exportado para:';

  @override
  String get errorDuringExport => 'Erro durante a exportação:';

  @override
  String get importDatabase => 'Importar banco de dados';

  @override
  String get importDatabaseDescription =>
      'Restaure seus jogos de um arquivo de backup';

  @override
  String get confirmation => 'Confirmação';

  @override
  String get importWarning =>
      'A importação substituirá todos os seus dados atuais. Um backup automático será criado antes da importação.\n\nDeseja continuar?';

  @override
  String get import => 'Importar';

  @override
  String get databaseImportedSuccessfully =>
      'Banco de dados importado com sucesso';

  @override
  String get importSuccessful => 'Importação bem-sucedida';

  @override
  String get importSuccessMessage =>
      'O banco de dados foi importado com sucesso.\n\nO aplicativo será fechado agora. Por favor, abra-o novamente para ver os novos dados.';

  @override
  String get ok => 'OK';

  @override
  String get errorDuringImport => 'Erro durante a importação:';

  @override
  String get noPlayers => 'Sem jogadores';

  @override
  String playersListSummary(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogadores: $names',
      one: '1 jogador: $names',
      zero: 'Sem jogadores',
    );
    return '$_temp0';
  }

  @override
  String get playersAppearMessage =>
      'Os jogadores aparecerão aqui assim que\nvocê criar jogos';

  @override
  String gamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos',
      one: '1 jogo',
      zero: '0 jogos',
    );
    return '$_temp0';
  }

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vitórias',
      one: '1 vitória',
      zero: '0 vitórias',
    );
    return '$_temp0';
  }

  @override
  String get changeColor => 'Alterar cor';

  @override
  String get renamePlayer => 'Renomear jogador';

  @override
  String get newName => 'Novo nome';

  @override
  String playerRenamedTo(String name) {
    return 'Jogador renomeado para \"$name\"';
  }

  @override
  String get deletePlayer => 'Excluir jogador';

  @override
  String confirmDeletePlayer(String name, int count) {
    return 'Você realmente deseja excluir \"$name\"?\n\nEste jogador será removido de todos os $count jogo(s).';
  }

  @override
  String playerDeleted(String name) {
    return 'Jogador \"$name\" excluído';
  }

  @override
  String get chooseColor => 'Escolha uma cor';

  @override
  String get noGameTypes => 'Sem tipos de jogo';

  @override
  String get predefined => 'Padrão';

  @override
  String get edit => 'Editar';

  @override
  String get newType => 'Novo tipo';

  @override
  String get editType => 'Editar tipo';

  @override
  String get newGameType => 'Novo tipo de jogo';

  @override
  String get gameTypeName => 'Nome do tipo de jogo';

  @override
  String get icon => 'Ícone:';

  @override
  String get color => 'Cor:';

  @override
  String get chooseIcon => 'Escolha um ícone';

  @override
  String get nameIsRequired => 'O nome é obrigatório';

  @override
  String get create => 'Criar';

  @override
  String get ranking => 'Classificação';

  @override
  String get noCurrentGame => 'Nenhum jogo atual';

  @override
  String get noScoresRecorded => 'Nenhuma pontuação registrada';

  @override
  String get playerStatistics => 'Estatísticas do Jogador';

  @override
  String get noStatisticsAvailable => 'Nenhuma estatística disponível';

  @override
  String get gamesPlayed => 'Jogos disputados';

  @override
  String get wins => 'Vitórias';

  @override
  String get winRate => 'Taxa de vitória';

  @override
  String get overallStatistics => 'Estatísticas Gerais';

  @override
  String get byGameType => 'Por tipo de jogo';

  @override
  String get rate => 'Taxa';

  @override
  String version(String version) {
    return 'Versão $version';
  }

  @override
  String get appDescription =>
      'Aplicativo de gerenciamento de pontuação para suas sessões de jogo por Vincent Moreau';

  @override
  String get features => 'Recursos';

  @override
  String get featureDifferentGameTypes => 'Diferentes tipos de jogo';

  @override
  String get featurePlayerManagement => 'Gerenciamento de jogadores';

  @override
  String get featureDetailedStatistics => 'Estatísticas detalhadas';

  @override
  String get featureCustomization => 'Personalização';

  @override
  String get featureDarkLightTheme => 'Tema escuro/claro';

  @override
  String get featureGroupSharing => 'Compartilhamento em grupo';

  @override
  String get featureGameAnalysis => 'Análise de partidas por IA';

  @override
  String get rateApp => 'Avaliar o CountScore';

  @override
  String get credits => 'Créditos';

  @override
  String get appIconCredit => 'Ícone do aplicativo';

  @override
  String get artistName => 'efendi.sign';

  @override
  String get selectPlayerDialogTitle => 'Selecione um jogador';

  @override
  String get search => 'Pesquisar';

  @override
  String get searchOrCreate => 'Pesquisar / Criar';

  @override
  String get createNewPlayer => 'Criar novo jogador';

  @override
  String get newPlayerName => 'Nome do novo jogador';

  @override
  String get noPlayersFound => 'Nenhum jogador encontrado';

  @override
  String get allPlayersSelected => 'Todos os jogadores foram selecionados';

  @override
  String get close => 'Fechar';

  @override
  String get playerEliminationCondition => 'Condição de Eliminação do Jogador';

  @override
  String get gameOverCondition => 'Condição de Fim de Jogo';

  @override
  String get none => 'Nenhuma';

  @override
  String get overThreshold => 'Acima do limite';

  @override
  String get underThreshold => 'Abaixo do limite';

  @override
  String get firstPlayerOver => 'Primeiro jogador acima';

  @override
  String get firstPlayerUnder => 'Primeiro jogador abaixo';

  @override
  String get lastPlayerOver => 'Último jogador acima';

  @override
  String get lastPlayerUnder => 'Último jogador abaixo';

  @override
  String get threshold => 'Limite';

  @override
  String get conditionType => 'Tipo de Condição';

  @override
  String get gameOverTitle => 'Fim de Jogo!';

  @override
  String get gameOverMessage =>
      'Condição de fim de jogo atingida. Terminar agora?';

  @override
  String get continuePlay => 'Continuar Jogando';

  @override
  String get endGame => 'Terminar Jogo';

  @override
  String get reopenGame => 'Reabrir jogo';

  @override
  String get gameFinished => 'Terminado';

  @override
  String get comment => 'Comentário';

  @override
  String get enterComment => 'Escrever um comentário';

  @override
  String get analyzeGame => 'Analisar partida';

  @override
  String get analysisTitle => 'Análise da partida';

  @override
  String get analysisStyle => 'Estilo de análise';

  @override
  String get analysisStyleProfessor => 'O professor';

  @override
  String get analysisStyleCommentator => 'O narrador esportivo';

  @override
  String get analysisStyleDocumentary => 'O documentário de natureza';

  @override
  String get analysisStyleNoir => 'O detetive';

  @override
  String get analysisStyleBard => 'O bardo';

  @override
  String get analysisStyleCoach => 'O treinador';

  @override
  String get analysisStyleConsultant => 'O consultor';

  @override
  String get analysisStyleAstrologer => 'O astrólogo';

  @override
  String get analysisStyleRealityTv => 'O reality show';

  @override
  String get generatingAnalysis => 'Gerando análise…';

  @override
  String get generateAnalysis => 'Gerar análise';

  @override
  String get regenerateAnalysis => 'Regenerar análise';

  @override
  String get deleteAnalysis => 'Excluir análise';

  @override
  String get confirmRegenerateAnalysis =>
      'Regenerar? A análise atual será substituída.';

  @override
  String get confirmDeleteAnalysis => 'Excluir a análise desta partida?';

  @override
  String get analysisError => 'Falha ao gerar a análise';

  @override
  String get analysisErrorUnavailable =>
      'O servidor de análise está temporariamente indisponível. Tente novamente mais tarde.';

  @override
  String analysisErrorStatus(int status) {
    return 'Falha ao gerar a análise (HTTP $status)';
  }

  @override
  String get retry => 'Tentar novamente';

  @override
  String analysisGeneratedAt(String date) {
    return 'Gerado em $date';
  }

  @override
  String get serverSection => 'Servidor';

  @override
  String get backendUrlLabel => 'URL do servidor';

  @override
  String get backendUrlHint => 'https://countscore.example.com';

  @override
  String get backendUrlDescription =>
      'As funcionalidades conectadas precisam de um servidor CountScore. Instale um a partir da pasta backend/ e informe o endereço aqui. Sem servidor, nenhum dado sai deste dispositivo.';

  @override
  String get backendNotConfigured => 'Nenhum servidor configurado';

  @override
  String get backendUrlInvalid =>
      'Endereço inválido. Informe uma URL completa, por exemplo https://countscore.example.com';

  @override
  String get backendUrlInsecure =>
      'http:// só é aceito em uma rede local. Use https:// para um servidor público.';

  @override
  String get testConnection => 'Testar conexão';

  @override
  String get connectionOk => 'O servidor está respondendo';

  @override
  String get connectionFailed => 'O servidor não está respondendo';

  @override
  String get serverUrlSaved => 'Servidor salvo';

  @override
  String get analysisRequiresBackend =>
      'Esta análise precisa de um servidor. Configure um nas configurações.';

  @override
  String get openSettings => 'Abrir configurações';

  @override
  String get serverUrlCleared => 'Servidor removido';

  @override
  String get groupSection => 'Grupo';

  @override
  String get groupDescription =>
      'Partilhe jogos com os outros dispositivos do grupo. Os jogos partilhados, os seus jogadores, pontuações, comentários e análises são enviados para o seu servidor; os restantes jogos ficam neste dispositivo.';

  @override
  String get groupNeedsServer => 'Configure primeiro um servidor acima.';

  @override
  String get groupCreate => 'Criar um grupo';

  @override
  String get groupJoin => 'Entrar num grupo';

  @override
  String get groupNameLabel => 'Nome do grupo';

  @override
  String get deviceLabelLabel => 'Nome deste dispositivo';

  @override
  String get deviceLabelDefault => 'O meu dispositivo';

  @override
  String get shareTokenLabel => 'Código de convite';

  @override
  String get shareTokenHint => 'Cole o código enviado por um membro do grupo';

  @override
  String groupCurrent(String name) {
    return 'Grupo: $name';
  }

  @override
  String get shareTokenExplain =>
      'Envie este código aos dispositivos que devem entrar no grupo. Quem o tiver pode entrar.';

  @override
  String get shareTokenCopy => 'Copiar código';

  @override
  String get shareTokenCopied => 'Código copiado';

  @override
  String get shareTokenRotate => 'Novo código';

  @override
  String get shareTokenRotateConfirm =>
      'O código antigo deixará de permitir entrar no grupo. Os dispositivos que já são membros não são afetados.';

  @override
  String get groupLeave => 'Sair do grupo';

  @override
  String get groupLeaveConfirm =>
      'Este dispositivo sai do grupo. Os jogos partilhados ficam neste dispositivo, mas deixam de ser sincronizados.';

  @override
  String get groupLeft => 'Saiu do grupo';

  @override
  String get groupJoined => 'Entrou no grupo';

  @override
  String get clearServerLeavesGroup =>
      'Apagar o servidor faz sair do grupo. Os jogos partilhados ficam neste dispositivo.';

  @override
  String get syncNow => 'Sincronizar';

  @override
  String syncStatusIdle(String time) {
    return 'Sincronizado às $time';
  }

  @override
  String get syncStatusSyncing => 'A sincronizar…';

  @override
  String get syncStatusOffline =>
      'Servidor inacessível — as alterações serão enviadas mais tarde';

  @override
  String get syncStatusUnauthorized =>
      'O servidor já não aceita este dispositivo. Saia do grupo e volte a entrar.';

  @override
  String get syncStatusError => 'Erro do servidor durante a sincronização';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alterações pendentes',
      one: '1 alteração pendente',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alterações recusadas pelo servidor',
      one: '1 alteração recusada pelo servidor',
    );
    return '$_temp0';
  }

  @override
  String get groupErrorUnknownToken =>
      'Código de convite desconhecido ou substituído';

  @override
  String get groupErrorRateLimited =>
      'Demasiadas tentativas. Tente novamente dentro de um minuto.';

  @override
  String get groupErrorUnreachable => 'Servidor inacessível';

  @override
  String get groupErrorServer => 'Erro do servidor';

  @override
  String get shareWithGroup => 'Partilhar com o grupo';

  @override
  String shareWithGroupSubtitle(String name) {
    return 'Os dispositivos de $name vão ver e editar este jogo';
  }

  @override
  String shareGameConfirm(String name) {
    return 'O jogo, os seus jogadores, pontuações e comentários serão enviados para $name. A partilha não pode ser anulada.';
  }

  @override
  String get gameSharedDone => 'Jogo partilhado com o grupo';

  @override
  String get gameSharedBadge => 'Jogo partilhado';

  @override
  String invalidPlayerNamesForSync(String names) {
    return 'Estes nomes não podem ser partilhados: $names. Use letras, algarismos, espaços, hífenes, apóstrofos ou pontos (32 caracteres no máximo).';
  }

  @override
  String roundRenumbered(int number) {
    return 'Essa ronda já tinha sido registada noutro dispositivo, por isso passou a ser a ronda $number.';
  }

  @override
  String gameDeletedElsewhere(String name) {
    return 'O jogo «$name» foi eliminado noutro dispositivo';
  }

  @override
  String get groupDevices => 'Dispositivos';

  @override
  String get groupDevicesExplain =>
      'Um celular perdido ou vendido pode ser removido do grupo aqui.';

  @override
  String get groupDeviceThisOne => 'Este dispositivo';

  @override
  String groupDeviceLastSeen(String date) {
    return 'Visto pela última vez: $date';
  }

  @override
  String get groupDeviceRevoke => 'Remover';

  @override
  String groupDeviceRevokeConfirm(String label) {
    return 'Remover “$label” do grupo? Ele deixará de sincronizar. O código de convite também muda: os membros mantêm o acesso, mas será preciso compartilhar o novo código para convidar alguém.';
  }

  @override
  String groupDeviceRevoked(String label) {
    return '“$label” foi removido. O código de convite mudou.';
  }

  @override
  String get reportCommentary => 'Denunciar este comentário';

  @override
  String get reportCommentarySubject =>
      'CountScore — denúncia de comentário de IA';

  @override
  String reportCommentaryBody(String reference, String commentary) {
    return 'Qual é o problema deste comentário gerado por IA?\n\n\n---\nReferência: $reference\nComentário:\n$commentary';
  }

  @override
  String reportCommentaryNoMailApp(String email) {
    return 'Nenhum app de e-mail encontrado. Escreva para $email para denunciar este comentário.';
  }

  @override
  String get gameRulesTitle => 'Regras do jogo';

  @override
  String get gameRulesInApp => 'No CountScore';

  @override
  String get gameRulesSection => 'As regras';

  @override
  String get gameRulesNoElimination => 'Sem eliminação durante a partida';

  @override
  String gameRulesEliminationOver(int threshold) {
    return 'Um jogador é eliminado acima de $threshold pontos';
  }

  @override
  String gameRulesEliminationUnder(int threshold) {
    return 'Um jogador é eliminado abaixo de $threshold pontos';
  }

  @override
  String gameRulesEndFirstOver(int threshold) {
    return 'A partida termina assim que um jogador passa de $threshold pontos';
  }

  @override
  String gameRulesEndFirstUnder(int threshold) {
    return 'A partida termina assim que um jogador cai abaixo de $threshold pontos';
  }

  @override
  String gameRulesEndLastOver(int threshold) {
    return 'A partida termina quando todos os jogadores, menos um, passam de $threshold pontos';
  }

  @override
  String gameRulesEndLastUnder(int threshold) {
    return 'A partida termina quando todos os jogadores, menos um, caem abaixo de $threshold pontos';
  }

  @override
  String get gameRulesNoEnd =>
      'Sem fim automático: você decide quando a partida termina';

  @override
  String get gameRulesEmptyTitle => 'Ainda sem regras';

  @override
  String get gameRulesEmptyHint =>
      'Anote como a sua mesa conta os pontos: assim todos terão a mesma versão.';

  @override
  String get gameRulesWrite => 'Escrever as regras';

  @override
  String get gameRulesEditTitle => 'Editar as regras';

  @override
  String get gameRulesEditorHint =>
      'As regras da sua mesa. Markdown é suportado.';

  @override
  String get gameRulesFromGroup => 'Regras do seu grupo';

  @override
  String get gameRulesRestoreDefault => 'Restaurar as regras originais';

  @override
  String get gameRulesSaved => 'Regras salvas';

  @override
  String get gameRulesRestored => 'Regras originais restauradas';

  @override
  String get gameRulesDisclaimer =>
      'Resumo escrito para o CountScore a partir das regras como são normalmente jogadas. Os nomes dos jogos pertencem aos seus proprietários e são citados apenas de forma descritiva.';

  @override
  String get gameTypeNameZapzap => 'ZapZap';

  @override
  String get gameTypeNameUno => 'Uno';

  @override
  String get gameTypeNameScrabble => 'Scrabble';

  @override
  String get gameTypeNameOther => 'Outro';

  @override
  String get gameTypeNameSkyjo => 'Skyjo';

  @override
  String get gameTypeNamePresident => 'Presidente';

  @override
  String get gameTypeNameBelote => 'Belote';

  @override
  String get gameTypeNameTarot => 'Tarô';

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
  String get gameTypeNameSixNimmt => 'Pega em 6';

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
}
