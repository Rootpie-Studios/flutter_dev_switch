/// The words the picker and menu show. English by default; [DevToolsStrings.sv]
/// for the Swedish apps. Pass your own instance to change any of them.
class DevToolsStrings {
  final String server;
  final String serverPrefix;
  final String customAddress;
  final String customAddressHint;
  final String customAddressTitle;
  final String customAddressHelp;
  final String resetToDefault;
  final String buildPointsAt;
  final String invalidAddress;
  final String cancel;
  final String use;
  final String devMenuTitle;
  final String devLogin;
  final String devLoginTitle;
  final String devLoggingIn;
  final String devLoginFailed;

  const DevToolsStrings({
    this.server = 'Server',
    this.serverPrefix = 'Server: ',
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
    this.devMenuTitle = 'Developer',
    this.devLogin = 'Test login',
    this.devLoginTitle = 'Test login on {server}',
    this.devLoggingIn = 'Logging in…',
    this.devLoginFailed = 'Test login as {email} failed on {server}.',
  });

  const DevToolsStrings.sv()
    : this(
        server: 'Server',
        serverPrefix: 'Server: ',
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
        devMenuTitle: 'Utvecklare',
        devLogin: 'Testinloggning',
        devLoginTitle: 'Testinloggning på {server}',
        devLoggingIn: 'Loggar in…',
        devLoginFailed:
            'Testinloggningen som {email} misslyckades på {server}.',
      );
}
