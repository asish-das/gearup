import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user.dart';
import '../models/vehicle.dart';
import 'package:intl/intl.dart';

class ExportService {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF5D40D4); // Indigo
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF1E293B); // Slate
  static const PdfColor accentColor = PdfColor.fromInt(0xFFF1F5F9); // Light Slate
  static const PdfColor successColor = PdfColor.fromInt(0xFF10B981); // Emerald

  /// Exports users and their vehicles to a high-quality PDF report.
  static Future<String> exportToPDF(List<User> users, List<Vehicle> vehicles) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM dd, yyyy').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) => _buildFooter(context),
        build: (pw.Context context) {
          return [
            _buildHeader('Vehicle Owners & Fleet Report', dateStr),
            pw.SizedBox(height: 24),
            _buildStatsRow(users.length, vehicles.length),
            pw.SizedBox(height: 24),
            pw.TableHelper.fromTextArray(
              headers: ['Owner Name', 'Email', 'Phone', 'Vehicles', 'Status'],
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(color: primaryColor),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
              },
              border: pw.TableBorder.all(color: accentColor, width: 0.5),
              data: users.map((user) {
                final userVehiclesCount = vehicles.where((v) => v.userId == user.uid).length;
                return [
                  user.name,
                  user.email,
                  user.phoneNumber ?? 'N/A',
                  userVehiclesCount.toString(),
                  (user.status ?? 'active').toUpperCase(),
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ];
        },
      ),
    );

    return await _saveOrPrint(pdf, 'vehicle_owners_report_${now.millisecondsSinceEpoch}.pdf');
  }

  /// Exports a generic list of data to a high-quality PDF report.
  static Future<String> exportGenericToPDF({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    String fileNamePrefix = 'report',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM dd, yyyy').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) => _buildFooter(context),
        build: (pw.Context context) {
          return [
            _buildHeader(title, dateStr),
            pw.SizedBox(height: 24),
            pw.TableHelper.fromTextArray(
              headers: headers,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(color: primaryColor),
              cellHeight: 30,
              border: pw.TableBorder.all(color: accentColor, width: 0.5),
              data: data,
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ];
        },
      ),
    );

    return await _saveOrPrint(pdf, '${fileNamePrefix}_${now.millisecondsSinceEpoch}.pdf');
  }

  static pw.Widget _buildHeader(String title, String date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Official Administrative Report',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              date,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Generated by Antigravity Admin',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStatsRow(int userCount, int vehicleCount) {
    return pw.Row(
      children: [
        _buildStatBox('Total Owners', userCount.toString(), primaryColor),
        pw.SizedBox(width: 16),
        _buildStatBox('Total Vehicles', vehicleCount.toString(), successColor),
      ],
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: accentColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
      ),
    );
  }

  static Future<String> _saveOrPrint(pw.Document pdf, String fileName) async {
    final bytes = await pdf.save();
    
    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
      return 'Displayed in print preview';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }

  // Legacy methods kept for backward compatibility if needed, but updated to use PDF
  static Future<String> exportToCSV(List<User> users, List<Vehicle> vehicles) async {
    return await exportToPDF(users, vehicles);
  }

  static Future<String> exportToText(List<User> users, List<Vehicle> vehicles) async {
    return await exportToPDF(users, vehicles);
  }
}
