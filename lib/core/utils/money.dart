import 'package:intl/intl.dart';

/// Money helpers. The backend speaks **minor units** (poisha) everywhere;
/// the UI never does arithmetic on formatted strings.
abstract final class Money {
  static final _fmt = NumberFormat.decimalPattern('en');

  /// 4000 -> "৳40" (BDT has no fractional display in courier surfaces).
  static String bdt(int minor) => '৳${_fmt.format(minor ~/ 100)}';

  /// Tabular-figure friendly, used inside offer totals / countdown centers.
  static String bdtCompact(int minor) => '৳${_fmt.format(minor ~/ 100)}';
}
