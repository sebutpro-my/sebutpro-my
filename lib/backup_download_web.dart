
import 'dart:convert';
import 'dart:html' as html;

Future<void> muatTurunJson(
  String namaFail,
  String kandungan,
) async {
  final blob = html.Blob(
    [utf8.encode(kandungan)],
    'application/json;charset=utf-8',
  );

  final url = html.Url.createObjectUrlFromBlob(blob);

  final pautan = html.AnchorElement(href: url)
    ..download = namaFail;

  try {
    pautan.click();

    await Future<void>.delayed(
      const Duration(seconds: 2),
    );
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
