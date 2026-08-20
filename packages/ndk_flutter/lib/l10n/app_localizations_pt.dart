// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get createAccount => 'Criar a sua conta';

  @override
  String get newHere => 'É novo aqui?';

  @override
  String get nostrAddress => 'Endereço Nostr';

  @override
  String get publicKey => 'Chave pública';

  @override
  String get privateKey => 'Chave privada (insegura)';

  @override
  String get browserExtension => 'Extensão do navegador';

  @override
  String get connect => 'Ligar';

  @override
  String get install => 'Instalar';

  @override
  String get logout => 'Terminar sessão';

  @override
  String get nostrAddressHint => 'nome@exemplo.com';

  @override
  String get invalidAddress => 'Endereço inválido';

  @override
  String get unableToConnect => 'Não foi possível estabelecer ligação';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => 'Novo no Nostr?';

  @override
  String get getStarted => 'Começar';

  @override
  String get bunker => 'Bunker';

  @override
  String get bunkerAuthentication => 'Autenticação Bunker';

  @override
  String tapToOpen(String url) {
    return 'Toque para abrir: $url';
  }

  @override
  String get showNostrConnectQrcode => 'Mostrar código QR do Nostr Connect';

  @override
  String get loginWithSignerApp => 'Iniciar sessão com app de assinatura';

  @override
  String get nostrConnectUrl => 'URL de ligação Nostr';

  @override
  String get copy => 'Copiar';

  @override
  String get addAccount => 'Adicionar conta';

  @override
  String get readOnly => 'Só de leitura';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => 'Extensão';

  @override
  String get userMetadata => 'Metadados do utilizador';

  @override
  String get shortTextNote => 'Nota de texto curta';

  @override
  String get recommendRelay => 'Recomendar relay';

  @override
  String get follows => 'Seguidos';

  @override
  String get encryptedDirectMessages => 'Mensagens diretas cifradas';

  @override
  String get eventDeletionRequest => 'Pedido de eliminação de evento';

  @override
  String get repost => 'Republicação';

  @override
  String get reaction => 'Reação';

  @override
  String get badgeAward => 'Atribuição de badge';

  @override
  String get chatMessage => 'Mensagem de chat';

  @override
  String get groupChatThreadedReply => 'Resposta em fio de chat de grupo';

  @override
  String get thread => 'Fio';

  @override
  String get groupThreadReply => 'Resposta em fio de grupo';

  @override
  String get seal => 'Selo';

  @override
  String get directMessage => 'Mensagem direta';

  @override
  String get fileMessage => 'Mensagem de ficheiro';

  @override
  String get genericRepost => 'Republicação genérica';

  @override
  String get reactionToWebsite => 'Reação a um site';

  @override
  String get picture => 'Imagem';

  @override
  String get videoEvent => 'Evento de vídeo';

  @override
  String get shortFormPortraitVideoEvent => 'Evento de vídeo vertical curto';

  @override
  String get internalReference => 'Referência interna';

  @override
  String get externalReference => 'Referência externa';

  @override
  String get hardcopyReference => 'Referência em papel';

  @override
  String get promptReference => 'Referência de prompt';

  @override
  String get channelCreation => 'Criação de canal';

  @override
  String get channelMetadata => 'Metadados do canal';

  @override
  String get channelMessage => 'Mensagem do canal';

  @override
  String get channelHideMessage => 'Ocultar mensagem do canal';

  @override
  String get channelMuteUser => 'Silenciar utilizador do canal';

  @override
  String get requestToVanish => 'Pedido para desaparecer';

  @override
  String get chessPgn => 'Xadrez (PGN)';

  @override
  String get mlsKeyPackage => 'Pacote de chaves MLS';

  @override
  String get mlsWelcome => 'Boas-vindas MLS';

  @override
  String get mlsGroupEvent => 'Evento de grupo MLS';

  @override
  String get mergeRequests => 'Pedidos de merge';

  @override
  String get pollResponse => 'Resposta a sondagem';

  @override
  String get marketplaceBid => 'Licitação do marketplace';

  @override
  String get marketplaceBidConfirmation =>
      'Confirmação de licitação do marketplace';

  @override
  String get openTimestamps => 'OpenTimestamps';

  @override
  String get giftWrap => 'Embrulho de presente';

  @override
  String get fileMetadata => 'Metadados do ficheiro';

  @override
  String get poll => 'Sondagem';

  @override
  String get comment => 'Comentário';

  @override
  String get voiceMessage => 'Mensagem de voz';

  @override
  String get voiceMessageComment => 'Comentário de mensagem de voz';

  @override
  String get liveChatMessage => 'Mensagem de chat em direto';

  @override
  String get codeSnippet => 'Excerto de código';

  @override
  String get gitPatch => 'Patch Git';

  @override
  String get gitPullRequest => 'Pull request Git';

  @override
  String get gitStatusUpdate => 'Atualização de estado Git';

  @override
  String get gitIssue => 'Issue Git';

  @override
  String get gitIssueUpdate => 'Atualização de issue Git';

  @override
  String get status => 'Estado';

  @override
  String get statusUpdate => 'Atualização de estado';

  @override
  String get statusDelete => 'Eliminação de estado';

  @override
  String get statusReply => 'Resposta de estado';

  @override
  String get problemTracker => 'Rastreador de problemas';

  @override
  String get reporting => 'Denúncia';

  @override
  String get label => 'Etiqueta';

  @override
  String get relayReviews => 'Avaliações de relays';

  @override
  String get aiEmbeddings => 'Embeddings de IA / Listas vetoriais';

  @override
  String get torrent => 'Torrent';

  @override
  String get torrentComment => 'Comentário de torrent';

  @override
  String get coinjoinPool => 'Pool Coinjoin';

  @override
  String get communityPostApproval => 'Aprovação de publicação da comunidade';

  @override
  String get jobRequest => 'Pedido de trabalho';

  @override
  String get jobResult => 'Resultado de trabalho';

  @override
  String get jobFeedback => 'Feedback de trabalho';

  @override
  String get cashuWalletToken => 'Token da carteira Cashu';

  @override
  String get cashuWalletProofs => 'Provas da carteira Cashu';

  @override
  String get cashuWalletHistory => 'Histórico da carteira Cashu';

  @override
  String get geocacheCreate => 'Criar geocache';

  @override
  String get geocacheUpdate => 'Atualizar geocache';

  @override
  String get groupControlEvent => 'Evento de controlo de grupo';

  @override
  String get zapGoal => 'Objetivo de Zap';

  @override
  String get nutzap => 'Nutzap';

  @override
  String get tidalLogin => 'Início de sessão Tidal';

  @override
  String get zapRequest => 'Pedido de Zap';

  @override
  String get zap => 'Zap';

  @override
  String get highlights => 'Destaques';

  @override
  String get muteList => 'Lista de silenciados';

  @override
  String get pinList => 'Lista de fixados';

  @override
  String get relayListMetadata => 'Metadados da lista de relays';

  @override
  String get bookmarkList => 'Lista de favoritos';

  @override
  String get communitiesList => 'Lista de comunidades';

  @override
  String get publicChatsList => 'Lista de chats públicos';

  @override
  String get blockedRelaysList => 'Lista de relays bloqueados';

  @override
  String get searchRelaysList => 'Lista de relays de pesquisa';

  @override
  String get userGroups => 'Grupos de utilizadores';

  @override
  String get favoritesList => 'Lista de favoritos';

  @override
  String get privateEventsList => 'Lista de eventos privados';

  @override
  String get interestsList => 'Lista de interesses';

  @override
  String get mediaFollowsList => 'Lista de media seguidos';

  @override
  String get peopleFollowsList => 'Lista de pessoas seguidas';

  @override
  String get userEmojiList => 'Lista de emojis do utilizador';

  @override
  String get dmRelayList => 'Lista de relays de DM';

  @override
  String get keyPackageRelayList => 'Lista de relays KeyPackage';

  @override
  String get userServerList => 'Lista de servidores do utilizador';

  @override
  String get fileStorageServerList =>
      'Lista de servidores de armazenamento de ficheiros';

  @override
  String get relayMonitorAnnouncement => 'Anúncio de monitor de relay';

  @override
  String get roomPresence => 'Presença na sala';

  @override
  String get proxyAnnouncement => 'Anúncio de proxy';

  @override
  String get transportMethodAnnouncement => 'Anúncio de método de transporte';

  @override
  String get walletInfo => 'Informações da carteira';

  @override
  String get cashuWalletEvent => 'Evento de carteira Cashu';

  @override
  String get lightningPubRpc => 'RPC Lightning Pub';

  @override
  String get clientAuthentication => 'Autenticação do cliente';

  @override
  String get walletRequest => 'Pedido de carteira';

  @override
  String get walletResponse => 'Resposta da carteira';

  @override
  String get nostrConnectEvent => 'Nostr Connect';

  @override
  String get blobsStoredOnMediaservers =>
      'Blobs armazenados em servidores de media';

  @override
  String get httpAuth => 'Autenticação HTTP';

  @override
  String get categorizedPeopleList => 'Lista de pessoas categorizada';

  @override
  String get categorizedBookmarkList => 'Lista de favoritos categorizada';

  @override
  String get categorizedRelayList => 'Lista de relays categorizada';

  @override
  String get bookmarkSets => 'Conjuntos de favoritos';

  @override
  String get curationSets => 'Conjuntos de curadoria';

  @override
  String get videoSets => 'Conjuntos de vídeos';

  @override
  String get kindMuteSets => 'Conjuntos de kinds silenciados';

  @override
  String get profileBadges => 'Badges de perfil';

  @override
  String get badgeDefinition => 'Definição de badge';

  @override
  String get interestSets => 'Conjuntos de interesses';

  @override
  String get createOrUpdateStall => 'Criar ou atualizar banca';

  @override
  String get createOrUpdateProduct => 'Criar ou atualizar produto';

  @override
  String get marketplaceUiUx => 'UI/UX do marketplace';

  @override
  String get productSoldAsAuction => 'Produto vendido em leilão';

  @override
  String get longFormContent => 'Conteúdo longo';

  @override
  String get draftLongFormContent => 'Rascunho de conteúdo longo';

  @override
  String get emojiSets => 'Conjuntos de emojis';

  @override
  String get curatedPublicationItem => 'Item de publicação curada';

  @override
  String get curatedPublicationDraft => 'Rascunho de publicação curada';

  @override
  String get releaseArtifactSets => 'Conjuntos de artefactos de release';

  @override
  String get applicationSpecificData => 'Dados específicos da aplicação';

  @override
  String get relayDiscovery => 'Descoberta de relays';

  @override
  String get appCurationSets => 'Conjuntos de curadoria de apps';

  @override
  String get liveEvent => 'Evento em direto';

  @override
  String get userStatus => 'Estado do utilizador';

  @override
  String get slideSet => 'Conjunto de diapositivos';

  @override
  String get classifiedListing => 'Anúncio classificado';

  @override
  String get draftClassifiedListing => 'Rascunho de anúncio classificado';

  @override
  String get repositoryAnnouncement => 'Anúncio de repositório';

  @override
  String get repositoryStateAnnouncement => 'Anúncio de estado do repositório';

  @override
  String get wikiArticle => 'Artigo wiki';

  @override
  String get redirects => 'Redirecionamentos';

  @override
  String get draftEvent => 'Evento de rascunho';

  @override
  String get linkSet => 'Conjunto de links';

  @override
  String get feed => 'Feed';

  @override
  String get dateBasedCalendarEvent => 'Evento de calendário por data';

  @override
  String get timeBasedCalendarEvent => 'Evento de calendário por hora';

  @override
  String get calendar => 'Calendário';

  @override
  String get calendarEventRsvp => 'RSVP de evento de calendário';

  @override
  String get handlerRecommendation => 'Recomendação de handler';

  @override
  String get handlerInformation => 'Informações do handler';

  @override
  String get softwareApplication => 'Aplicação de software';

  @override
  String get videoView => 'Visualização de vídeo';

  @override
  String get communityDefinition => 'Definição de comunidade';

  @override
  String get geocacheListing => 'Listagem de geocache';

  @override
  String get mintAnnouncement => 'Anúncio de mint';

  @override
  String get mintQuote => 'Cotação de mint';

  @override
  String get peerToPeerOrder => 'Ordem peer-to-peer';

  @override
  String get groupMetadata => 'Metadados do grupo';

  @override
  String get groupAdminMetadata => 'Metadados do admin do grupo';

  @override
  String get groupMemberMetadata => 'Metadados do membro do grupo';

  @override
  String get groupAdminsList => 'Lista de admins do grupo';

  @override
  String get groupMembersList => 'Lista de membros do grupo';

  @override
  String get groupRoles => 'Funções do grupo';

  @override
  String get groupPermissions => 'Permissões do grupo';

  @override
  String get groupChatMessage => 'Mensagem de chat do grupo';

  @override
  String get groupChatThread => 'Fio de chat do grupo';

  @override
  String get groupPinned => 'Fixado do grupo';

  @override
  String get starterPacks => 'Pacotes iniciais';

  @override
  String get mediaStarterPacks => 'Pacotes iniciais de media';

  @override
  String get webBookmarks => 'Favoritos da Web';

  @override
  String unknownEventKind(int kind) {
    return 'Tipo de evento $kind';
  }

  @override
  String get walletsTitle => 'Carteiras';

  @override
  String get recentActivityTitle => 'Atividade recente';

  @override
  String get addCashuWallet => 'Adicionar carteira Cashu';

  @override
  String get addNwcWallet => 'Adicionar carteira NWC';

  @override
  String get addLnurlWallet => 'Adicionar carteira LNURL';

  @override
  String get addCashuTooltip => 'Adicionar carteira Cashu';

  @override
  String get addNwcTooltip => 'Adicionar carteira NWC';

  @override
  String get addLnurlTooltip => 'Adicionar carteira LNURL';

  @override
  String get addCashuWalletTitle => 'Adicionar carteira Cashu';

  @override
  String get enterMintUrl =>
      'Introduza o URL da mint para adicionar uma carteira Cashu.';

  @override
  String get mintUrl => 'URL da mint';

  @override
  String get mintUrlHint => 'https://mint.exemplo.com';

  @override
  String get pleaseEnterMintUrl => 'Introduza um URL da mint';

  @override
  String get cashuWalletAdded => 'Carteira Cashu adicionada com sucesso!';

  @override
  String get failedToAddMint =>
      'Falha ao adicionar a mint. Verifique o URL e tente novamente.';

  @override
  String get addNwcWalletTitle => 'Adicionar carteira NWC';

  @override
  String get faucet => 'Faucet';

  @override
  String get manual => 'Manual';

  @override
  String get nwcFaucetDescription =>
      'Crie uma carteira de teste com sats do faucet NWC.';

  @override
  String get startingBalance => 'Saldo inicial';

  @override
  String get startingBalanceHint => '10000';

  @override
  String get nwcConnectionUri => 'URI de ligação NWC';

  @override
  String get nwcConnectionUriHint => 'nostr+walletconnect://...';

  @override
  String get nwcWalletAdded => 'Carteira NWC adicionada com sucesso!';

  @override
  String nwcFaucetWalletAdded(int balance) {
    return 'Carteira faucet NWC adicionada com $balance sats!';
  }

  @override
  String get invalidFaucetResponse => 'Resposta inválida do faucet';

  @override
  String get errorCreatingWallet => 'Erro ao criar carteira';

  @override
  String get addLnurlWalletTitle => 'Adicionar carteira LNURL';

  @override
  String get enterLnurlIdentifier =>
      'Introduza o seu identificador LNURL (utilizador@dominio.com).';

  @override
  String get lnurlIdentifierHint => 'utilizador@exemplo.com';

  @override
  String get pleaseEnterValidIdentifier =>
      'Introduza um identificador válido (utilizador@dominio.com)';

  @override
  String get lnurlWalletAdded => 'Carteira LNURL adicionada com sucesso!';

  @override
  String get cancel => 'Cancelar';

  @override
  String get add => 'Adicionar';

  @override
  String get send => 'Enviar';

  @override
  String get receive => 'Receber';

  @override
  String get setAsDefaultForReceiving =>
      'Definir como predefinida para receber';

  @override
  String get setAsDefaultForSending => 'Definir como predefinida para enviar';

  @override
  String get defaultForReceiving => 'Predefinida para receber';

  @override
  String get defaultForSending => 'Predefinida para enviar';

  @override
  String get defaultWalletForReceivingTooltip =>
      'Esta carteira é a predefinida para receber pagamentos.';

  @override
  String get defaultWalletForSendingTooltip =>
      'Esta carteira é a predefinida para enviar pagamentos.';

  @override
  String get sendOptionsTitle => 'Opções de envio';

  @override
  String get sendByToken => 'Enviar por token';

  @override
  String get sendByTokenDescription => 'Criar um token Cashu para enviar';

  @override
  String get sendByLightning => 'Enviar por Lightning';

  @override
  String get sendByLightningDescription => 'Pagar uma fatura Lightning';

  @override
  String get payInvoiceTitle => 'Pagar fatura';

  @override
  String get invoice => 'Fatura';

  @override
  String get invoiceHint => 'lnbc...';

  @override
  String get pleaseEnterInvoice => 'Introduza uma fatura';

  @override
  String get invoicePaid => 'Fatura paga!';

  @override
  String paymentFailed(String message) {
    return 'Pagamento falhou: $message';
  }

  @override
  String get receiveOptionsTitle => 'Opções de receção';

  @override
  String get receiveByToken => 'Receber por token';

  @override
  String get receiveByTokenDescription => 'Receber um token Cashu';

  @override
  String get receiveByLightning => 'Receber por Lightning';

  @override
  String get receiveByLightningDescription => 'Criar uma fatura Lightning';

  @override
  String get receiveByTokenTitle => 'Receber por token';

  @override
  String get token => 'Token';

  @override
  String get tokenHint => 'Cole o token aqui...';

  @override
  String get pleaseEnterToken => 'Introduza um token';

  @override
  String get tokenReceived => 'Token recebido!';

  @override
  String get createInvoiceTitle => 'Criar fatura';

  @override
  String get amount => 'Montante';

  @override
  String get amountHint => '100';

  @override
  String get pleaseEnterValidAmount => 'Introduza um montante válido';

  @override
  String get tokenCopiedToClipboard =>
      'Token copiado para a área de transferência!';

  @override
  String get invoiceCreatedAndCopied => 'Fatura criada e copiada!';

  @override
  String get invoiceTrackingTitle => 'Fatura Lightning';

  @override
  String get invoiceCreatedMessage => 'Fatura criada e copiada!';

  @override
  String get close => 'Fechar';

  @override
  String get copyAgain => 'Copiar novamente';

  @override
  String get copied => 'Copiado!';

  @override
  String get paymentReceived => 'Pagamento recebido!';

  @override
  String get waitingForPayment => 'A aguardar pagamento...';

  @override
  String get paid => 'Pago!';

  @override
  String get createToken => 'Criar token';

  @override
  String get pay => 'Pagar';

  @override
  String get create => 'Criar';

  @override
  String get pendingTransactions => 'Pendentes';

  @override
  String get backupSeedWarning =>
      'Faça backup da sua frase de recuperação cashu';

  @override
  String get backupSeedTitle => 'Backup da frase de recuperação cashu';

  @override
  String get backupSeedInstructions =>
      'Anote estas palavras em ordem e guarde-as em um lugar seguro. Elas são a única forma de recuperar seus fundos cashu se você perder este dispositivo.';

  @override
  String get backupSeedConfirm =>
      'Anotei minha frase de recuperação e a guardei com segurança';

  @override
  String get backupSeedDone => 'Já fiz o backup';

  @override
  String get reclaimPendingFunds => 'Recuperar fundos pendentes';

  @override
  String get reclaimPendingTitle => 'Recuperar fundos pendentes';

  @override
  String get recentTransactions => 'Transações recentes';

  @override
  String get noRecentTransactions => 'Sem transações recentes';

  @override
  String get noWalletsYet => 'Ainda não existem carteiras';

  @override
  String get noWalletsAvailable => 'Não existem carteiras disponíveis';

  @override
  String get tapToAddWallet => 'Toque em + para adicionar uma';

  @override
  String get delete => 'Eliminar';

  @override
  String error(String message) {
    return 'Erro: $message';
  }

  @override
  String get unknownWalletType => 'Desconhecido';

  @override
  String get cashuWallet => 'Cashu';

  @override
  String get nwcWallet => 'NWC';

  @override
  String get lnurlWallet => 'LNURL';

  @override
  String get nwcWalletSubtitle => 'Carteira NWC';

  @override
  String get balance => 'Saldo';

  @override
  String get sats => 'sats';

  @override
  String get selected => 'SELECIONADO';

  @override
  String get receiveOnlyWallet => 'Carteira apenas para receber';

  @override
  String receiveRange(int min, int max) {
    return 'Receber: $min - $max sats';
  }

  @override
  String get limitsUnavailable => 'Limites indisponíveis';

  @override
  String get tokenCopied => 'Token copiado';

  @override
  String get deleteWalletConfirmation => 'Eliminar carteira?';

  @override
  String get deleteWalletConfirmationMessage =>
      'Tem a certeza de que pretende eliminar esta carteira? Esta ação não pode ser anulada.';

  @override
  String get addWalletTitle => 'Adicionar carteira';

  @override
  String get chooseWalletType => 'Escolha o tipo de carteira';

  @override
  String get nwcWalletTypeTitle => 'Nostr Wallet Connect';

  @override
  String get nwcWalletTypeSubtitle => 'Ligar a uma carteira remota com NWC';

  @override
  String get lnurlWalletTypeTitle => 'Endereço Lightning (LNURL)';

  @override
  String get lnurlWalletTypeSubtitle =>
      'Use um endereço Lightning (LNURL) apenas para receber';

  @override
  String get cashuWalletTypeTitle => 'Cashu';

  @override
  String get cashuWalletTypeSubtitle =>
      'Use uma carteira ecash suportada por uma mint Cashu';

  @override
  String get cashuOption => 'Cashu';

  @override
  String get nwcOption => 'NWC';

  @override
  String get lnurlOption => 'LNURL';

  @override
  String get connectNwcTitle => 'Ligar NWC';

  @override
  String get chooseNwcMethod => 'Escolha o método de ligação';

  @override
  String get albyGoOption => 'Alby Go';

  @override
  String get manualOption => 'Manual';

  @override
  String get faucetOption => 'Faucet';

  @override
  String get invalidNwcQrCode => 'Código QR NWC inválido';

  @override
  String get scanNwcQrCodeTitle => 'Ler código QR NWC';

  @override
  String get cameraNotAvailable => 'Câmara não disponível';

  @override
  String get scanNwcInstructions =>
      'Leia o código QR da sua app de carteira NWC';

  @override
  String get invalidNwcUri => 'URI NWC inválido';

  @override
  String get paste => 'Colar';

  @override
  String get fromYourProfile => 'Do seu perfil';

  @override
  String get orEnterManually => 'Ou introduza manualmente:';

  @override
  String get renameWallet => 'Renomear';

  @override
  String get pickColor => 'Escolher cor';

  @override
  String get deleteWallet => 'Eliminar';

  @override
  String get walletName => 'Nome da carteira';

  @override
  String get walletNameHint => 'Introduza o nome da carteira';

  @override
  String get save => 'Guardar';

  @override
  String get walletRenamed => 'Carteira renomeada';

  @override
  String budgetUsedOf(int used, int total) {
    final intl.NumberFormat usedNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String usedString = usedNumberFormat.format(used);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Orçamento: $usedString / $totalString';
  }

  @override
  String budgetRenewsIn(int days) {
    return 'Renova em $days dias';
  }

  @override
  String get budgetDaily => 'Diário';

  @override
  String get budgetWeekly => 'Semanal';

  @override
  String get budgetMonthly => 'Mensal';

  @override
  String get budgetYearly => 'Anual';

  @override
  String get budgetNever => 'Nunca';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get cashuBackupTitle => 'Cashu Backup';

  @override
  String get cashuBackupWarning =>
      'This backup contains your ecash proofs, which are bearer funds. Keep it private and store it somewhere safe. Your seed phrase is backed up separately.';

  @override
  String get generatingBackup => 'Generating backup...';

  @override
  String get copyBackup => 'Copy backup';

  @override
  String get backupCopiedToClipboard => 'Backup copied to clipboard';

  @override
  String get cashuRestoreTitle => 'Restore Cashu Backup';

  @override
  String get backupJson => 'Backup JSON';

  @override
  String get backupJsonHint => 'Paste your backup JSON here';

  @override
  String get pleaseEnterBackup => 'Please enter a backup';

  @override
  String get restoringBackup => 'Restoring backup...';

  @override
  String restoreSuccess(int count) {
    return 'Restored $count proofs from backup';
  }
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get createAccount => 'Criar sua conta';

  @override
  String get newHere => 'Você é novo aqui?';

  @override
  String get nostrAddress => 'Endereço Nostr';

  @override
  String get publicKey => 'Chave pública';

  @override
  String get privateKey => 'Chave privada (insegura)';

  @override
  String get browserExtension => 'Extensão do navegador';

  @override
  String get connect => 'Conectar';

  @override
  String get install => 'Instalar';

  @override
  String get logout => 'Sair';

  @override
  String get nostrAddressHint => 'nome@exemplo.com';

  @override
  String get invalidAddress => 'Endereço inválido';

  @override
  String get unableToConnect => 'Não foi possível conectar';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => 'Novo no Nostr?';

  @override
  String get getStarted => 'Começar';

  @override
  String get bunker => 'Bunker';

  @override
  String get bunkerAuthentication => 'Autenticação Bunker';

  @override
  String tapToOpen(String url) {
    return 'Toque para abrir: $url';
  }

  @override
  String get showNostrConnectQrcode => 'Mostrar QR code de conexão Nostr';

  @override
  String get loginWithSignerApp => 'Entrar com app de assinatura';

  @override
  String get nostrConnectUrl => 'URL de conexão Nostr';

  @override
  String get copy => 'Copiar';

  @override
  String get addAccount => 'Adicionar conta';

  @override
  String get readOnly => 'Somente leitura';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => 'Extensão';

  @override
  String get userMetadata => 'Metadados do usuário';

  @override
  String get shortTextNote => 'Nota de texto curta';

  @override
  String get recommendRelay => 'Recomendar relay';

  @override
  String get follows => 'Seguindo';

  @override
  String get encryptedDirectMessages => 'Mensagens diretas criptografadas';

  @override
  String get eventDeletionRequest => 'Solicitação de exclusão de evento';

  @override
  String get repost => 'Repostar';

  @override
  String get reaction => 'Reação';

  @override
  String get badgeAward => 'Concessão de badge';

  @override
  String get chatMessage => 'Mensagem de chat';

  @override
  String get groupChatThreadedReply => 'Resposta em thread de chat em grupo';

  @override
  String get thread => 'Thread';

  @override
  String get groupThreadReply => 'Resposta em thread de grupo';

  @override
  String get seal => 'Selo';

  @override
  String get directMessage => 'Mensagem direta';

  @override
  String get fileMessage => 'Mensagem de arquivo';

  @override
  String get genericRepost => 'Repostagem genérica';

  @override
  String get reactionToWebsite => 'Reação a um site';

  @override
  String get picture => 'Imagem';

  @override
  String get videoEvent => 'Evento de vídeo';

  @override
  String get shortFormPortraitVideoEvent => 'Evento de vídeo vertical curto';

  @override
  String get internalReference => 'Referência interna';

  @override
  String get externalReference => 'Referência externa';

  @override
  String get hardcopyReference => 'Referência em papel';

  @override
  String get promptReference => 'Referência de prompt';

  @override
  String get channelCreation => 'Criação de canal';

  @override
  String get channelMetadata => 'Metadados do canal';

  @override
  String get channelMessage => 'Mensagem do canal';

  @override
  String get channelHideMessage => 'Ocultar mensagem do canal';

  @override
  String get channelMuteUser => 'Silenciar usuário do canal';

  @override
  String get requestToVanish => 'Solicitação para desaparecer';

  @override
  String get chessPgn => 'Xadrez (PGN)';

  @override
  String get mlsKeyPackage => 'MLS KeyPackage';

  @override
  String get mlsWelcome => 'MLS Welcome';

  @override
  String get mlsGroupEvent => 'MLS Group Event';

  @override
  String get mergeRequests => 'Solicitações de merge';

  @override
  String get pollResponse => 'Resposta de enquete';

  @override
  String get marketplaceBid => 'Lance do marketplace';

  @override
  String get marketplaceBidConfirmation =>
      'Confirmação de lance do marketplace';

  @override
  String get openTimestamps => 'OpenTimestamps';

  @override
  String get giftWrap => 'Embalagem de presente';

  @override
  String get fileMetadata => 'Metadados do arquivo';

  @override
  String get poll => 'Enquete';

  @override
  String get comment => 'Comentário';

  @override
  String get voiceMessage => 'Mensagem de voz';

  @override
  String get voiceMessageComment => 'Comentário de mensagem de voz';

  @override
  String get liveChatMessage => 'Mensagem de chat ao vivo';

  @override
  String get codeSnippet => 'Trecho de código';

  @override
  String get gitPatch => 'Patch do Git';

  @override
  String get gitPullRequest => 'Pull request do Git';

  @override
  String get gitStatusUpdate => 'Atualização de status do Git';

  @override
  String get gitIssue => 'Issue do Git';

  @override
  String get gitIssueUpdate => 'Atualização de issue do Git';

  @override
  String get status => 'Status';

  @override
  String get statusUpdate => 'Atualização de status';

  @override
  String get statusDelete => 'Exclusão de status';

  @override
  String get statusReply => 'Resposta de status';

  @override
  String get problemTracker => 'Rastreador de problemas';

  @override
  String get reporting => 'Denúncia';

  @override
  String get label => 'Rótulo';

  @override
  String get relayReviews => 'Avaliações de relays';

  @override
  String get aiEmbeddings => 'Embeddings de IA / Listas vetoriais';

  @override
  String get torrent => 'Torrent';

  @override
  String get torrentComment => 'Comentário de torrent';

  @override
  String get coinjoinPool => 'Pool Coinjoin';

  @override
  String get communityPostApproval => 'Aprovação de post da comunidade';

  @override
  String get jobRequest => 'Solicitação de trabalho';

  @override
  String get jobResult => 'Resultado de trabalho';

  @override
  String get jobFeedback => 'Feedback de trabalho';

  @override
  String get cashuWalletToken => 'Token da carteira Cashu';

  @override
  String get cashuWalletProofs => 'Provas da carteira Cashu';

  @override
  String get cashuWalletHistory => 'Histórico da carteira Cashu';

  @override
  String get geocacheCreate => 'Criar geocache';

  @override
  String get geocacheUpdate => 'Atualizar geocache';

  @override
  String get groupControlEvent => 'Evento de controle de grupo';

  @override
  String get zapGoal => 'Meta de Zap';

  @override
  String get nutzap => 'Nutzap';

  @override
  String get tidalLogin => 'Login Tidal';

  @override
  String get zapRequest => 'Solicitação de Zap';

  @override
  String get zap => 'Zap';

  @override
  String get highlights => 'Destaques';

  @override
  String get muteList => 'Lista de silenciados';

  @override
  String get pinList => 'Lista de fixados';

  @override
  String get relayListMetadata => 'Metadados da lista de relays';

  @override
  String get bookmarkList => 'Lista de favoritos';

  @override
  String get communitiesList => 'Lista de comunidades';

  @override
  String get publicChatsList => 'Lista de chats públicos';

  @override
  String get blockedRelaysList => 'Lista de relays bloqueados';

  @override
  String get searchRelaysList => 'Lista de relays de busca';

  @override
  String get userGroups => 'Grupos de usuários';

  @override
  String get favoritesList => 'Lista de favoritos';

  @override
  String get privateEventsList => 'Lista de eventos privados';

  @override
  String get interestsList => 'Lista de interesses';

  @override
  String get mediaFollowsList => 'Lista de mídia seguida';

  @override
  String get peopleFollowsList => 'Lista de pessoas seguidas';

  @override
  String get userEmojiList => 'Lista de emojis do usuário';

  @override
  String get dmRelayList => 'Lista de relays de DM';

  @override
  String get keyPackageRelayList => 'Lista de relays KeyPackage';

  @override
  String get userServerList => 'Lista de servidores do usuário';

  @override
  String get fileStorageServerList =>
      'Lista de servidores de armazenamento de arquivos';

  @override
  String get relayMonitorAnnouncement => 'Anúncio de monitor de relay';

  @override
  String get roomPresence => 'Presença na sala';

  @override
  String get proxyAnnouncement => 'Anúncio de proxy';

  @override
  String get transportMethodAnnouncement => 'Anúncio de método de transporte';

  @override
  String get walletInfo => 'Informações da carteira';

  @override
  String get cashuWalletEvent => 'Evento de carteira Cashu';

  @override
  String get lightningPubRpc => 'RPC Lightning Pub';

  @override
  String get clientAuthentication => 'Autenticação do cliente';

  @override
  String get walletRequest => 'Solicitação de carteira';

  @override
  String get walletResponse => 'Resposta da carteira';

  @override
  String get nostrConnectEvent => 'Nostr Connect';

  @override
  String get blobsStoredOnMediaservers =>
      'Blobs armazenados em servidores de mídia';

  @override
  String get httpAuth => 'Autenticação HTTP';

  @override
  String get categorizedPeopleList => 'Lista de pessoas categorizada';

  @override
  String get categorizedBookmarkList => 'Lista de favoritos categorizada';

  @override
  String get categorizedRelayList => 'Lista de relays categorizada';

  @override
  String get bookmarkSets => 'Conjuntos de favoritos';

  @override
  String get curationSets => 'Conjuntos de curadoria';

  @override
  String get videoSets => 'Conjuntos de vídeos';

  @override
  String get kindMuteSets => 'Conjuntos de kinds silenciados';

  @override
  String get profileBadges => 'Badges de perfil';

  @override
  String get badgeDefinition => 'Definição de badge';

  @override
  String get interestSets => 'Conjuntos de interesses';

  @override
  String get createOrUpdateStall => 'Criar ou atualizar banca';

  @override
  String get createOrUpdateProduct => 'Criar ou atualizar produto';

  @override
  String get marketplaceUiUx => 'UI/UX do marketplace';

  @override
  String get productSoldAsAuction => 'Produto vendido em leilão';

  @override
  String get longFormContent => 'Conteúdo longo';

  @override
  String get draftLongFormContent => 'Rascunho de conteúdo longo';

  @override
  String get emojiSets => 'Conjuntos de emojis';

  @override
  String get curatedPublicationItem => 'Item de publicação curada';

  @override
  String get curatedPublicationDraft => 'Rascunho de publicação curada';

  @override
  String get releaseArtifactSets => 'Conjuntos de artefatos de release';

  @override
  String get applicationSpecificData => 'Dados específicos do aplicativo';

  @override
  String get relayDiscovery => 'Descoberta de relays';

  @override
  String get appCurationSets => 'Conjuntos de curadoria de apps';

  @override
  String get liveEvent => 'Evento ao vivo';

  @override
  String get userStatus => 'Status do usuário';

  @override
  String get slideSet => 'Conjunto de slides';

  @override
  String get classifiedListing => 'Anúncio classificado';

  @override
  String get draftClassifiedListing => 'Rascunho de anúncio classificado';

  @override
  String get repositoryAnnouncement => 'Anúncio de repositório';

  @override
  String get repositoryStateAnnouncement => 'Anúncio de estado do repositório';

  @override
  String get wikiArticle => 'Artigo wiki';

  @override
  String get redirects => 'Redirecionamentos';

  @override
  String get draftEvent => 'Evento de rascunho';

  @override
  String get linkSet => 'Conjunto de links';

  @override
  String get feed => 'Feed';

  @override
  String get dateBasedCalendarEvent => 'Evento de calendário por data';

  @override
  String get timeBasedCalendarEvent => 'Evento de calendário por hora';

  @override
  String get calendar => 'Calendário';

  @override
  String get calendarEventRsvp => 'RSVP de evento de calendário';

  @override
  String get handlerRecommendation => 'Recomendação de handler';

  @override
  String get handlerInformation => 'Informações do handler';

  @override
  String get softwareApplication => 'Aplicativo de software';

  @override
  String get videoView => 'Visualização de vídeo';

  @override
  String get communityDefinition => 'Definição de comunidade';

  @override
  String get geocacheListing => 'Listagem de geocache';

  @override
  String get mintAnnouncement => 'Anúncio de mint';

  @override
  String get mintQuote => 'Cotação de mint';

  @override
  String get peerToPeerOrder => 'Ordem peer-to-peer';

  @override
  String get groupMetadata => 'Metadados do grupo';

  @override
  String get groupAdminMetadata => 'Metadados do admin do grupo';

  @override
  String get groupMemberMetadata => 'Metadados do membro do grupo';

  @override
  String get groupAdminsList => 'Lista de admins do grupo';

  @override
  String get groupMembersList => 'Lista de membros do grupo';

  @override
  String get groupRoles => 'Funções do grupo';

  @override
  String get groupPermissions => 'Permissões do grupo';

  @override
  String get groupChatMessage => 'Mensagem de chat do grupo';

  @override
  String get groupChatThread => 'Thread de chat do grupo';

  @override
  String get groupPinned => 'Fixado do grupo';

  @override
  String get starterPacks => 'Pacotes iniciais';

  @override
  String get mediaStarterPacks => 'Pacotes iniciais de mídia';

  @override
  String get webBookmarks => 'Favoritos da Web';

  @override
  String unknownEventKind(int kind) {
    return 'Tipo de evento $kind';
  }

  @override
  String get walletsTitle => 'Carteiras';

  @override
  String get recentActivityTitle => 'Atividade recente';

  @override
  String get addCashuWallet => 'Adicionar carteira Cashu';

  @override
  String get addNwcWallet => 'Adicionar carteira NWC';

  @override
  String get addLnurlWallet => 'Adicionar carteira LNURL';

  @override
  String get addCashuTooltip => 'Adicionar carteira Cashu';

  @override
  String get addNwcTooltip => 'Adicionar carteira NWC';

  @override
  String get addLnurlTooltip => 'Adicionar carteira LNURL';

  @override
  String get addCashuWalletTitle => 'Adicionar carteira Cashu';

  @override
  String get enterMintUrl =>
      'Digite a URL da mint para adicionar uma carteira Cashu.';

  @override
  String get mintUrl => 'URL da mint';

  @override
  String get mintUrlHint => 'https://mint.exemplo.com';

  @override
  String get pleaseEnterMintUrl => 'Por favor, digite uma URL da mint';

  @override
  String get cashuWalletAdded => 'Carteira Cashu adicionada com sucesso!';

  @override
  String get failedToAddMint =>
      'Falha ao adicionar a mint. Verifique a URL e tente novamente.';

  @override
  String get addNwcWalletTitle => 'Adicionar carteira NWC';

  @override
  String get faucet => 'Faucet';

  @override
  String get manual => 'Manual';

  @override
  String get nwcFaucetDescription =>
      'Crie uma carteira de teste com sats do faucet NWC.';

  @override
  String get startingBalance => 'Saldo inicial';

  @override
  String get startingBalanceHint => '10000';

  @override
  String get nwcConnectionUri => 'URI de conexão NWC';

  @override
  String get nwcConnectionUriHint => 'nostr+walletconnect://...';

  @override
  String get nwcWalletAdded => 'Carteira NWC adicionada com sucesso!';

  @override
  String nwcFaucetWalletAdded(int balance) {
    return 'Carteira faucet NWC adicionada com $balance sats!';
  }

  @override
  String get invalidFaucetResponse => 'Resposta inválida do faucet';

  @override
  String get errorCreatingWallet => 'Erro ao criar carteira';

  @override
  String get addLnurlWalletTitle => 'Adicionar carteira LNURL';

  @override
  String get enterLnurlIdentifier =>
      'Digite seu identificador LNURL (usuario@dominio.com).';

  @override
  String get lnurlIdentifierHint => 'usuario@exemplo.com';

  @override
  String get pleaseEnterValidIdentifier =>
      'Por favor, digite um identificador válido (usuario@dominio.com)';

  @override
  String get lnurlWalletAdded => 'Carteira LNURL adicionada com sucesso!';

  @override
  String get cancel => 'Cancelar';

  @override
  String get add => 'Adicionar';

  @override
  String get send => 'Enviar';

  @override
  String get receive => 'Receber';

  @override
  String get setAsDefaultForReceiving => 'Definir como padrão para receber';

  @override
  String get setAsDefaultForSending => 'Definir como padrão para enviar';

  @override
  String get defaultForReceiving => 'Padrão para receber';

  @override
  String get defaultForSending => 'Padrão para enviar';

  @override
  String get defaultWalletForReceivingTooltip =>
      'Esta carteira é a padrão para receber pagamentos.';

  @override
  String get defaultWalletForSendingTooltip =>
      'Esta carteira é a padrão para enviar pagamentos.';

  @override
  String get sendOptionsTitle => 'Opções de envio';

  @override
  String get sendByToken => 'Enviar por token';

  @override
  String get sendByTokenDescription => 'Criar um token Cashu para enviar';

  @override
  String get sendByLightning => 'Enviar por Lightning';

  @override
  String get sendByLightningDescription => 'Pagar uma fatura Lightning';

  @override
  String get payInvoiceTitle => 'Pagar fatura';

  @override
  String get invoice => 'Fatura';

  @override
  String get invoiceHint => 'lnbc...';

  @override
  String get pleaseEnterInvoice => 'Por favor, digite uma fatura';

  @override
  String get invoicePaid => 'Fatura paga!';

  @override
  String paymentFailed(String message) {
    return 'Pagamento falhou: $message';
  }

  @override
  String get receiveOptionsTitle => 'Opções de recebimento';

  @override
  String get receiveByToken => 'Receber por token';

  @override
  String get receiveByTokenDescription => 'Receber um token Cashu';

  @override
  String get receiveByLightning => 'Receber por Lightning';

  @override
  String get receiveByLightningDescription => 'Criar uma fatura Lightning';

  @override
  String get receiveByTokenTitle => 'Receber por token';

  @override
  String get token => 'Token';

  @override
  String get tokenHint => 'Cole o token aqui...';

  @override
  String get pleaseEnterToken => 'Por favor, digite um token';

  @override
  String get tokenReceived => 'Token recebido!';

  @override
  String get createInvoiceTitle => 'Criar fatura';

  @override
  String get amount => 'Valor';

  @override
  String get amountHint => '100';

  @override
  String get pleaseEnterValidAmount => 'Por favor, digite um valor válido';

  @override
  String get tokenCopiedToClipboard =>
      'Token copiado para a área de transferência!';

  @override
  String get invoiceCreatedAndCopied => 'Fatura criada e copiada!';

  @override
  String get invoiceTrackingTitle => 'Fatura Lightning';

  @override
  String get invoiceCreatedMessage => 'Fatura criada e copiada!';

  @override
  String get close => 'Fechar';

  @override
  String get copyAgain => 'Copiar novamente';

  @override
  String get copied => 'Copiado!';

  @override
  String get paymentReceived => 'Pagamento recebido!';

  @override
  String get waitingForPayment => 'Aguardando pagamento...';

  @override
  String get paid => 'Pago!';

  @override
  String get createToken => 'Criar token';

  @override
  String get pay => 'Pagar';

  @override
  String get create => 'Criar';

  @override
  String get pendingTransactions => 'Pendentes';

  @override
  String get backupSeedWarning =>
      'Faça backup da sua frase de recuperação cashu';

  @override
  String get backupSeedTitle => 'Backup da frase de recuperação cashu';

  @override
  String get backupSeedInstructions =>
      'Anote estas palavras em ordem e guarde-as em um lugar seguro. Elas são a única forma de recuperar seus fundos cashu se você perder este dispositivo.';

  @override
  String get backupSeedConfirm =>
      'Anotei minha frase de recuperação e a guardei com segurança';

  @override
  String get backupSeedDone => 'Já fiz o backup';

  @override
  String get reclaimPendingFunds => 'Recuperar fundos pendentes';

  @override
  String get reclaimPendingTitle => 'Recuperar fundos pendentes';

  @override
  String get recentTransactions => 'Transações recentes';

  @override
  String get noRecentTransactions => 'Nenhuma transação recente';

  @override
  String get noWalletsYet => 'Nenhuma carteira ainda';

  @override
  String get noWalletsAvailable => 'Nenhuma carteira disponível';

  @override
  String get tapToAddWallet => 'Toque em + para adicionar uma';

  @override
  String get delete => 'Excluir';

  @override
  String error(String message) {
    return 'Erro: $message';
  }

  @override
  String get unknownWalletType => 'Desconhecido';

  @override
  String get cashuWallet => 'Cashu';

  @override
  String get nwcWallet => 'NWC';

  @override
  String get lnurlWallet => 'LNURL';

  @override
  String get nwcWalletSubtitle => 'Carteira NWC';

  @override
  String get balance => 'Saldo';

  @override
  String get sats => 'sats';

  @override
  String get selected => 'SELECIONADO';

  @override
  String get receiveOnlyWallet => 'Carteira somente para receber';

  @override
  String receiveRange(int min, int max) {
    return 'Receber: $min - $max sats';
  }

  @override
  String get limitsUnavailable => 'Limites indisponíveis';

  @override
  String get tokenCopied => 'Token copiado';

  @override
  String get deleteWalletConfirmation => 'Excluir carteira?';

  @override
  String get deleteWalletConfirmationMessage =>
      'Tem certeza de que deseja excluir esta carteira? Esta ação não pode ser desfeita.';

  @override
  String get addWalletTitle => 'Adicionar carteira';

  @override
  String get chooseWalletType => 'Escolha o tipo de carteira';

  @override
  String get nwcWalletTypeTitle => 'Nostr Wallet Connect';

  @override
  String get nwcWalletTypeSubtitle => 'Conectar a uma carteira remota com NWC';

  @override
  String get lnurlWalletTypeTitle => 'Endereço Lightning (LNURL)';

  @override
  String get lnurlWalletTypeSubtitle =>
      'Use um endereço Lightning (LNURL) apenas para receber';

  @override
  String get cashuWalletTypeTitle => 'Cashu';

  @override
  String get cashuWalletTypeSubtitle =>
      'Use uma carteira ecash com suporte de uma mint Cashu';

  @override
  String get cashuOption => 'Cashu';

  @override
  String get nwcOption => 'NWC';

  @override
  String get lnurlOption => 'LNURL';

  @override
  String get connectNwcTitle => 'Conectar NWC';

  @override
  String get chooseNwcMethod => 'Escolha o método de conexão';

  @override
  String get albyGoOption => 'Alby Go';

  @override
  String get manualOption => 'Manual';

  @override
  String get faucetOption => 'Faucet';

  @override
  String get invalidNwcQrCode => 'QR code NWC inválido';

  @override
  String get scanNwcQrCodeTitle => 'Escanear QR Code NWC';

  @override
  String get cameraNotAvailable => 'Câmera não disponível';

  @override
  String get scanNwcInstructions =>
      'Escaneie o QR code do seu app de carteira NWC';

  @override
  String get invalidNwcUri => 'URI NWC inválido';

  @override
  String get paste => 'Colar';

  @override
  String get fromYourProfile => 'Do seu perfil';

  @override
  String get orEnterManually => 'Ou digite manualmente:';

  @override
  String get renameWallet => 'Renomear';

  @override
  String get pickColor => 'Escolher cor';

  @override
  String get deleteWallet => 'Excluir';

  @override
  String get walletName => 'Nome da carteira';

  @override
  String get walletNameHint => 'Digite o nome da carteira';

  @override
  String get save => 'Salvar';

  @override
  String get walletRenamed => 'Carteira renomeada';

  @override
  String budgetUsedOf(int used, int total) {
    final intl.NumberFormat usedNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String usedString = usedNumberFormat.format(used);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Orçamento: $usedString / $totalString';
  }

  @override
  String budgetRenewsIn(int days) {
    return 'Renova em $days dias';
  }

  @override
  String get budgetDaily => 'Diário';

  @override
  String get budgetWeekly => 'Semanal';

  @override
  String get budgetMonthly => 'Mensal';

  @override
  String get budgetYearly => 'Anual';

  @override
  String get budgetNever => 'Nunca';
}
