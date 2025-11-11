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
    defaultValue: '', // p.ej. SolucionsSocials
  );
  static const String githubRepo = String.fromEnvironment(
    'GITHUB_REPO_NAME',
    defaultValue: '', // p.ej. Solucions-Socials-Sostenibles-Kronos-Mobile
  );
  static const String githubReleasesUrl = String.fromEnvironment(
    'GITHUB_RELEASES_URL',
    defaultValue: '', // si no se pasa, se construye con owner/repo
  );
  static const String githubApiBase = String.fromEnvironment(
    'GITHUB_API_BASE',
    defaultValue: 'https://api.github.com',
  );
}
