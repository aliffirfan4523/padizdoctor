import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../model/MyActivityData.dart';

class ReportService {
  static Future<void> generateAndDownloadReport(ActivityData data) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PadizDoctor Activity Report',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Generated on: $formattedDate',
                        style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                // Placeholder for logo if any
                pw.PdfLogo(),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // Summary Stats
            pw.Text('Summary Statistics',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBox('Total Scans', data.totalScans.toString()),
                _buildStatBox('Healthy', data.healthyCount.toString()),
                _buildStatBox('Alerts', data.alertsCount.toString()),
                _buildStatBox('Avg Processing', data.avgTimeStr),
              ],
            ),
            pw.SizedBox(height: 30),

            // Disease Distribution Table
            pw.Text('Disease Distribution',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Disease Name', 'Count', 'Percentage'],
              data: data.diseaseDistribution.entries.map((entry) {
                final percentage = (entry.value / data.totalScans) * 100;
                return [
                  entry.key,
                  entry.value.toString(),
                  '${percentage.toStringAsFixed(1)}%',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 30),

            // Recent Scans
            pw.Text('Recent Scans (Last 20)',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Date/Time', 'Disease', 'Severity', 'Location'],
              data: data.scans.take(20).map((scan) {
                final timestamp = scan['record']['timestamp'];
                final dateStr = timestamp != null 
                  ? DateFormat('MM/dd HH:mm').format(timestamp.toDate())
                  : 'N/A';
                final diseaseName = scan['disease']?['disease_name'] ?? 
                                   scan['result']?['disease_id'] ?? "Healthy";
                final severity = scan['result']['severity'] ?? 'N/A';
                final location = scan['record']['location_name'] ?? 'N/A';

                return [dateStr, diseaseName, severity, location];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    // Show preview and print/save options
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'PadizDoctor_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
