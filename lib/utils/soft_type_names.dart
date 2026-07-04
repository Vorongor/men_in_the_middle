/// Display names for `software_types` ids (Phishing/Bruteforce/DDoS/Exploit).
/// Seeded 1:1 by `DatabaseHelper._seedSoftwareTypes`; kept as a constant map
/// rather than a DB round-trip since the four ids are effectively fixed enum
/// values for the life of the alpha.
const Map<int, String> kSoftwareTypeNames = {
  1: 'Phishing',
  2: 'Bruteforce',
  3: 'DDoS',
  4: 'Exploit',
};

String softwareTypeName(int id) => kSoftwareTypeNames[id] ?? 'Utility';
