/// One-tap ladders from `design/Veazy.dc.html`: base temperature plus boost
/// and superboost offsets.
enum QuickSetup {
  flavour(base: 175, boost: 10, superBoost: 10),
  balanced(base: 180, boost: 15, superBoost: 15),
  full(base: 190, boost: 10, superBoost: 10);

  const QuickSetup({
    required this.base,
    required this.boost,
    required this.superBoost,
  });

  final int base;
  final int boost;
  final int superBoost;
}
