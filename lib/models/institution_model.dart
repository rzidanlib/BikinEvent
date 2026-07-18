enum InstitutionLevel { smp, sma, mahasiswa }

InstitutionLevel institutionLevelFromString(String value) {
  return InstitutionLevel.values.firstWhere(
    (e) => e.name == value,
    orElse: () => InstitutionLevel.sma,
  );
}

String institutionLevelLabel(InstitutionLevel level) {
  switch (level) {
    case InstitutionLevel.smp:
      return 'SMP';
    case InstitutionLevel.sma:
      return 'SMA';
    case InstitutionLevel.mahasiswa:
      return 'Mahasiswa';
  }
}

class InstitutionModel {
  final String id;
  final String name;
  final InstitutionLevel level;
  final String? emailDomain;

  InstitutionModel({
    required this.id,
    required this.name,
    required this.level,
    this.emailDomain,
  });

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    return InstitutionModel(
      id: json['id'],
      name: json['name'],
      level: institutionLevelFromString(json['level']),
      emailDomain: json['email_domain'],
    );
  }
}
