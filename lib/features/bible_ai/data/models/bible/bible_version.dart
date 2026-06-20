enum BibleVersion {
  kjv('KJV', 'King James Version', 'assets/json/kjv.json'),
  web('WEB', 'World English Bible', 'assets/json/web.json'),
  asv('ASV', 'American Standard Version', 'assets/json/asv.json');

  final String abbreviation;
  final String fullName;
  final String assetPath;

  const BibleVersion(this.abbreviation, this.fullName, this.assetPath);

  static BibleVersion fromAbbreviation(String abbreviation) {
    final normalized = abbreviation.trim().toUpperCase();
    return BibleVersion.values.firstWhere(
      (version) => version.abbreviation.toUpperCase() == normalized,
      orElse: () => BibleVersion.kjv,
    );
  }
}
