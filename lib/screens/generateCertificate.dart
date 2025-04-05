import 'dart:io' show File; // For mobile and desktop
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart'; // For mobile and desktop
import 'dart:html' as html; // For web
import 'package:flutter/material.dart';

Future<void> generateCertificate({
  required BuildContext context,
  required String userName,
  required String courseTitle,
  required int score,
}) async {
  try {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Certificate of Achievement',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'This is to certify that',
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                userName, // User's name
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'has successfully completed the course',
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                courseTitle, // Course title
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'with a score of $score/100.',
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Congratulations!',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (kIsWeb) {
      // For web: Download the PDF in the browser
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = 'certificate.pdf'
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile and desktop: Save the PDF to a file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/certificate.pdf');
      await file.writeAsBytes(await pdf.save());

      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Certificate downloaded to ${file.path}')),
      );
    }
  } catch (e) {
    print('Error generating certificate: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to generate certificate.')),
    );
  }
}