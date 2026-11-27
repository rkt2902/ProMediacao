/// Datas por extenso curto, em hora local (DESIGN.md, "A voz"):
/// "26 nov 2026" e "26 nov 2026, 14:32". Nunca "há 3 dias".
abstract final class AppDates {
  static const List<String> _months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  static String date(DateTime d) {
    final l = d.toLocal();
    return '${l.day} ${_months[l.month - 1]} ${l.year}';
  }

  static String dateTime(DateTime d) {
    final l = d.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date(l)}, ${two(l.hour)}:${two(l.minute)}';
  }
}
