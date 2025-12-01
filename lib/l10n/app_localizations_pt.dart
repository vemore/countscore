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
  String get version => 'Versão 1.0.0';

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
}
