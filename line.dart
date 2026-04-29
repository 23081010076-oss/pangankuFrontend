import 'dart:io';

void main() {
  var lines = File('lib/features/analytics/widgets/analytics_sections.dart')
      .readAsLinesSync();
  for (int i = 570; i <= 600; i++) {
    stdout.writeln('${i + 1}: ${lines[i]}');
  }
}
