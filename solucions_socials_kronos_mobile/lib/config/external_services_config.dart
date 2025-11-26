class ExternalServicesConfig {
  // URLs de ping para comprobar estado de servicios externos
  static const String holdedSolucionsUrl = String.fromEnvironment(
    'HOLDED_SOLUCIONS_URL',
    defaultValue: '', // p.ej. https://api.holded.com/some/health
  );
  static const String holdedMenjadorUrl = String.fromEnvironment(
    'HOLDED_MENJADOR_URL',
    defaultValue: '',
  );

  // Tokens opcionales para autorización (si aplica)
  static const String holdedSolucionsToken = String.fromEnvironment(
    'HOLDED_SOLUCIONS_TOKEN',
    defaultValue: '',
  );
  static const String holdedMenjadorToken = String.fromEnvironment(
    'HOLDED_MENJADOR_TOKEN',
    defaultValue: '',
  );

  // Configuración de actualizaciones (GitHub)
  static const String githubOwner = String.fromEnvironment(
    'GITHUB_REPO_OWNER',
    defaultValue: 'Marcausente',
  );
  static const String githubRepo = String.fromEnvironment(
    'GITHUB_REPO_NAME',
    defaultValue: 'Solucions-Socials-Sostenibles-Kronos-Mobile',
  );
  static const String githubReleasesUrl = String.fromEnvironment(
    'GITHUB_RELEASES_URL',
    defaultValue: '', // si no se pasa, se construye con owner/repo
  );
  static const String githubApiBase = String.fromEnvironment(
    'GITHUB_API_BASE',
    defaultValue: 'https://api.github.com',
  );

  // Holded API real (para llamadas autenticadas por empresa)
  static const String holdedBaseUrl = String.fromEnvironment(
    'HOLDED_BASE_URL',
    defaultValue: 'https://api.holded.com/api/invoicing/v1',
  );
  static const String holdedApiKeySolucions = String.fromEnvironment(
    'HOLDED_API_KEY_SOLUCIONS',
    defaultValue: 'cfe50911f41fe8de885b167988773e09',
  );
  static const String holdedApiKeyMenjar = String.fromEnvironment(
    'HOLDED_API_KEY_MENJAR',
    defaultValue: '44758c63e2fc4dc5dd37a3eedc1ae580',
  );
}
