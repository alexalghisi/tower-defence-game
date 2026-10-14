import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the web host stays dark and names the keep before Flutter boots', () {
    final page = File('web/index.html').readAsStringSync();
    expect(page, contains('<title>Keepward</title>'));
    expect(page, contains('name="theme-color"'));
    expect(page, contains('#0C120B'));
    expect(page, contains('Hold the gate'));
    expect(page, contains('flutter_bootstrap.js'));
    expect(page.contains('<!--'), isFalse);
  });

  test('the install plate uses the same ink as the match', () {
    final manifest = File('web/manifest.json').readAsStringSync();
    expect(manifest, contains('"background_color": "#0C120B"'));
    expect(manifest, contains('"theme_color": "#D7A441"'));
  });
}
