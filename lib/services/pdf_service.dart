import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class PdfService {
  // Builds a simple text-based PDF report (reading plan, report card, etc.)
  static Future<File> generateTextReport({
    required String title,
    required String body,
    required String childName,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, text: title),
          pw.Text('Child: $childName', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 12),
          pw.Text(body, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        '${title.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  // Opens the system print/share sheet for the generated PDF.
  static Future<void> printOrShare(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.uri.pathSegments.last,
    );
  }
}
