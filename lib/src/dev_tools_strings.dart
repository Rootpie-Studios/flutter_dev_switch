/// The words the menu and its sheets show. English by default;
/// [DevToolsStrings.sv] for the Swedish apps. Pass your own instance to
/// change any of them. `{name}` placeholders are filled in.
class DevToolsStrings {
  final String devMenuTitle;
  final String server;
  final String customAddress;
  final String customAddressHint;
  final String customAddressTitle;
  final String customAddressHelp;
  final String resetToDefault;
  final String buildPointsAt;
  final String invalidAddress;
  final String cancel;
  final String use;
  final String slowRequests;
  final String slowRequestsHelp;
  final String off;
  final String seconds;
  final String offline;
  final String offlineHelp;
  final String refuseWrites;
  final String refuseWritesHelp;
  final String devLogin;
  final String devLoginTitle;
  final String devLoggingIn;
  final String devLoginFailed;
  final String resetApp;
  final String resetAppHelp;
  final String resetConfirm;
  final String resetDone;
  final String resetStepFailed;
  final String clear;
  final String latency;
  final String instant;
  final String requestCount;
  final String noRequestsYet;
  final String offlineStatus;

  const DevToolsStrings({
    this.devMenuTitle = 'Developer',
    this.server = 'Server',
    this.customAddress = 'Custom address',
    this.customAddressHint = 'Tap to enter, e.g. ',
    this.customAddressTitle = 'Custom server address',
    this.customAddressHelp =
        'A computer\'s .local name keeps working when its IP changes; an IP '
        'works too. http:// and /api are filled in when missing.',
    this.resetToDefault = 'Reset to default',
    this.buildPointsAt = 'This build points at {url} when nothing is picked.',
    this.invalidAddress = 'That is not a valid address',
    this.cancel = 'Cancel',
    this.use = 'Use',
    this.slowRequests = 'Slow requests',
    this.slowRequestsHelp =
        'Every request waits this long before it is sent, to look at '
        'loading states.',
    this.off = 'Off',
    this.seconds = '{n} s',
    this.offline = 'Offline',
    this.offlineHelp = 'Every request fails to connect',
    this.refuseWrites = 'Refuse writes',
    this.refuseWritesHelp = 'Writes get a 500; reads still work',
    this.devLogin = 'Test login',
    this.devLoginTitle = 'Test login on {server}',
    this.devLoggingIn = 'Logging in as {email}…',
    this.devLoginFailed = 'Test login as {email} failed on {server}: {reason}',
    this.resetApp = 'Reset app data',
    this.resetAppHelp = 'Wipe what the app stores on this device',
    this.resetConfirm = 'As freshly installed. This wipes:',
    this.resetDone = 'Wiped. Restart the app to start clean.',
    this.resetStepFailed = 'Could not wipe {step}: {reason}',
    this.clear = 'Clear',
    this.latency = 'Latency',
    this.instant = 'Instant',
    this.requestCount = '{n} requests',
    this.noRequestsYet = 'Nothing yet. Open a screen and save something.',
    this.offlineStatus = 'offline',
  });

  const DevToolsStrings.sv()
    : this(
        devMenuTitle: 'Utvecklare',
        server: 'Server',
        customAddress: 'Egen adress',
        customAddressHint: 'Tryck för att ange, t.ex. ',
        customAddressTitle: 'Egen serveradress',
        customAddressHelp:
            'Datorns .local-namn följer med när IP-adressen byts; ett IP '
            'fungerar också. http:// och /api fylls i om de saknas.',
        resetToDefault: 'Återställ till standard',
        buildPointsAt: 'Bygget pekar på {url} när inget är valt.',
        invalidAddress: 'Det är ingen giltig adress',
        cancel: 'Avbryt',
        use: 'Använd',
        slowRequests: 'Långsamma anrop',
        slowRequestsHelp:
            'Varje anrop väntar så här länge innan det skickas, för att '
            'titta på laddningslägen.',
        off: 'Av',
        seconds: '{n} s',
        offline: 'Offline',
        offlineHelp: 'Varje anrop misslyckas att ansluta',
        refuseWrites: 'Neka skrivningar',
        refuseWritesHelp: 'Skrivningar får 500; läsningar fungerar',
        devLogin: 'Testinloggning',
        devLoginTitle: 'Testinloggning på {server}',
        devLoggingIn: 'Loggar in som {email}…',
        devLoginFailed:
            'Testinloggningen som {email} misslyckades på {server}: {reason}',
        resetApp: 'Nollställ appdata',
        resetAppHelp: 'Rensar det appen sparat på den här enheten',
        resetConfirm: 'Som nyinstallerad. Detta rensas:',
        resetDone: 'Rensat. Starta om appen för en ren start.',
        resetStepFailed: 'Kunde inte rensa {step}: {reason}',
        clear: 'Rensa',
        latency: 'Latens',
        instant: 'Direkt',
        requestCount: '{n} anrop',
        noRequestsYet: 'Inget än. Öppna en skärm och spara något.',
        offlineStatus: 'offline',
      );
}

/// `'{a} and {b}'.fill({'a': 'x', 'b': 'y'})` is `'x and y'`.
extension FillPlaceholders on String {
  String fill(Map<String, String> values) => values.entries.fold(
    this,
    (String s, MapEntry<String, String> e) =>
        s.replaceAll('{${e.key}}', e.value),
  );
}
