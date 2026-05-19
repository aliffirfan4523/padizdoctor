import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/format_Name.dart';
import '../../../model/MyActivityData.dart';

class ReportService {
  /// Generate and download the PDF report.
  /// [onProgress] is called with a human-readable status message at each step.
  static Future<void> generateAndDownloadReport(
    ActivityData data, {
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Loading fonts...');
    final fontBase = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontBase,
        bold: fontBold,
      ),
    );
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

    onProgress?.call('Building summary pages...');

    // ── Page 1+: Summary ──────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: _buildFooter,
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
                pw.PdfLogo(),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // Summary Stats
            pw.Text('Summary Statistics',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
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
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
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
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 30),

            // Recent Scans
            pw.Text('Recent Scans (Last 20)',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Date/Time', 'Disease', 'Severity', 'Location'],
              data: data.scans.take(20).map((scan) {
                final timestamp = scan['record']['timestamp'];
                final dateStr = timestamp != null
                    ? DateFormat('MM/dd HH:mm').format(timestamp.toDate())
                    : 'N/A';
                final diseaseName = scan['disease']?['disease_name'] ??
                    scan['result']?['disease_id'] ??
                    "Healthy";
                final severity = scan['result']['severity'] ?? 'N/A';
                final location = scan['record']['location_name'] ?? 'N/A';

                return [dateStr, formatName(diseaseName), severity, location];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    // ── Detail Pages: one per scan record ─────────────────────────────────
    final db = FirebaseFirestore.instance;
    final scansToDetail = data.scans.take(20).toList();
    for (int i = 0; i < scansToDetail.length; i++) {
      onProgress
          ?.call('Processing record ${i + 1} of ${scansToDetail.length}...');

      final scan = scansToDetail[i];
      final record = scan['record'] as Map<String, dynamic>? ?? {};
      final image = scan['image'] as Map<String, dynamic>? ?? {};
      final recordId = scan['record_id']?.toString() ?? '';

      // ── Fetch ALL results for this record ──
      List<Map<String, dynamic>> allResults = [];
      List<dynamic> allBoxes = [];
      try {
        final resultSnap = await db
            .collection('DiagnosisResult')
            .where('record_id', isEqualTo: recordId)
            .get();
        allResults = resultSnap.docs.map((d) => d.data()).toList();
        for (final r in allResults) {
          final boxes = r['bounding_boxes'] as List<dynamic>? ?? [];
          allBoxes.addAll(boxes);
        }
      } catch (_) {}

      // ── Fetch diseases for each result ──
      final diseaseIds = allResults
          .map((r) => r['disease_id']?.toString())
          .where((id) => id != null)
          .toSet();
      Map<String, Map<String, dynamic>> diseasesMap = {};
      try {
        final diseaseSnaps = await Future.wait(
          diseaseIds.map((id) => db.collection('Disease').doc(id!).get()),
        );
        for (final doc in diseaseSnaps) {
          if (doc.exists) diseasesMap[doc.id] = doc.data() ?? {};
        }
      } catch (_) {}

      // ── Fetch treatment suggestions ──
      List<Map<String, dynamic>> suggestions = [];
      try {
        final sugSnap = await db
            .collection('TreatmentSuggestion')
            .where('record_id', isEqualTo: recordId)
            .get();
        suggestions = sugSnap.docs.map((d) => d.data()).toList();
      } catch (_) {}

      // ── Format metadata ──
      String dateStr = 'N/A';
      final ts = record['timestamp'];
      if (ts != null && ts is Timestamp) {
        dateStr = DateFormat('M/d/yyyy, h:mm:ss a').format(ts.toDate());
      }

      String coordStr = 'N/A';
      final lat = record['latitude'] as num?;
      final lng = record['longitude'] as num?;
      if (lat != null && lng != null) {
        coordStr = '${lat.toDouble()}, ${lng.toDouble()}';
      }

      final locationName = record['location_name']?.toString() ?? '';

      // ── Download image & draw bounding boxes ──
      final imageUrl = image['file_name'] as String?;
      pw.Widget imageWidget;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            final annotatedBytes =
                await _drawBoundingBoxes(response.bodyBytes, allBoxes);
            final pdfImage = pw.MemoryImage(annotatedBytes);
            imageWidget = pw.Center(
              child: pw.Image(pdfImage,
                  fit: pw.BoxFit.contain, width: 350),
            );
          } else {
            imageWidget = _buildImagePlaceholder('Image unavailable');
          }
        } catch (e) {
          debugPrint('Report image error: $e');
          imageWidget = _buildImagePlaceholder('Image load failed');
        }
      } else {
        imageWidget = _buildImagePlaceholder('No image');
      }

      // ── Build disease info rows ──
      final List<pw.Widget> diseaseWidgets = [];
      for (int j = 0; j < allResults.length; j++) {
        final r = allResults[j];
        final diseaseId = r['disease_id']?.toString() ?? '';
        final disease = diseasesMap[diseaseId];
        final name =
            formatName(disease?['disease_name']?.toString() ?? diseaseId);
        final conf =
            ((r['confidence_score'] as num?)?.toDouble() ?? 0.0) * 100;
        final sev = r['severity']?.toString() ?? 'N/A';

        diseaseWidgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${j + 1}. $name',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(
                    'Severity: $sev  |  Confidence: ${conf.toStringAsFixed(1)}%',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );
      }

      // ── Build treatment widgets ──
      final List<pw.Widget> treatmentWidgets = [];
      if (suggestions.isNotEmpty) {
        treatmentWidgets.add(pw.SizedBox(height: 12));
        treatmentWidgets.add(pw.Text('Treatment Suggestions',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)));
        treatmentWidgets.add(pw.SizedBox(height: 6));
        for (final sug in suggestions) {
          final text = sug['text']?.toString() ?? '';
          final source = sug['source']?.toString() ?? '';
          if (text.isNotEmpty) {
            treatmentWidgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green200),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(text,
                        style: const pw.TextStyle(fontSize: 10)),
                    if (source.isNotEmpty)
                      pw.Text('Source: $source',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ),
            );
          }
        }
      }

      // ── Add page(s) using MultiPage for overflow ──
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          footer: _buildFooter,
          build: (pw.Context context) {
            return [
              pw.Text('Detail Analysis - Record #${i + 1}',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Date: $dateStr',
                  style: const pw.TextStyle(fontSize: 11)),
              if (locationName.isNotEmpty)
                pw.Text('Location: $locationName',
                    style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Coordinate: $coordStr',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 12),
              imageWidget,
              pw.SizedBox(height: 16),
              pw.Text('Detected Diseases (${allResults.length})',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              ...diseaseWidgets,
              ...treatmentWidgets,
            ];
          },
        ),
      );
    }

    onProgress?.call('Finalizing PDF...');

    // Show preview and print/save options
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'PadizDoctor_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  /// Draw bounding boxes on an image using dart:ui and return PNG bytes.
  static Future<Uint8List> _drawBoundingBoxes(
      Uint8List imageBytes, List<dynamic> boxes) async {
    if (boxes.isEmpty) return imageBytes;

    // Decode the original image
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final original = frame.image;

    final int imgW = original.width;
    final int imgH = original.height;

    // Create a picture recorder & canvas at original resolution
    final recorder = ui.PictureRecorder();
    final canvas =
        Canvas(recorder, Rect.fromLTWH(0, 0, imgW.toDouble(), imgH.toDouble()));

    // Draw the original image
    canvas.drawImage(original, Offset.zero, Paint());

    // Draw each bounding box
    final boxPaint = Paint()
      ..color = const Color(0xFF00E676) // green
      ..style = PaintingStyle.stroke
      ..strokeWidth = (imgW * 0.004).clamp(2.0, 6.0);

    final bgPaint = Paint()
      ..color = const Color(0xCC00E676)
      ..style = PaintingStyle.fill;

    final fontSize = (imgW * 0.025).clamp(12.0, 32.0);

    for (final box in boxes) {
      final double x1 = (box['x1'] as num?)?.toDouble() ?? 0;
      final double y1 = (box['y1'] as num?)?.toDouble() ?? 0;
      final double x2 = (box['x2'] as num?)?.toDouble() ?? 0;
      final double y2 = (box['y2'] as num?)?.toDouble() ?? 0;
      final String label = box['label']?.toString() ?? '';
      final double conf = (box['confidence'] as num?)?.toDouble() ?? 0;

      // Skip boxes that cover the entire image (same size as image)
      final boxW = (x2 - x1).abs();
      final boxH = (y2 - y1).abs();
      if (boxW >= imgW * 0.95 && boxH >= imgH * 0.95) continue;

      // Draw the rectangle
      canvas.drawRect(Rect.fromLTRB(x1, y1, x2, y2), boxPaint);

      // Draw label background + text
      final labelText = '$label: ${(conf * 100).toStringAsFixed(1)}%';
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final labelH = textPainter.height + 4;
      final labelW = textPainter.width + 8;

      // Place label above the box, or inside if there's no room above
      final bool placeAbove = y1 - labelH >= 0;
      final double labelY = placeAbove ? y1 - labelH : y1 + 2;

      final labelRect = Rect.fromLTWH(x1, labelY, labelW, labelH);
      canvas.drawRect(labelRect, bgPaint);
      textPainter.paint(canvas, Offset(x1 + 4, labelY + 2));
    }

    // Render to image
    final picture = recorder.endRecording();
    final rendered = await picture.toImage(imgW, imgH);
    final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PadizDoctor',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Disclaimer: Detection results are generated by AI and may not be 100% accurate. '
                  'Always consult a qualified agricultural expert before taking action.',
                  style: const pw.TextStyle(
                      fontSize: 7, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildImagePlaceholder(String message) {
    return pw.Container(
      height: 200,
      width: double.infinity,
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      child: pw.Center(child: pw.Text(message)),
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
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
