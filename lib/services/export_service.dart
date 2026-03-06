// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:universal_html/html.dart' as html;
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/vehicle.dart';

class ExportService {
  static Future<String> exportToPDF(
    List<User> users,
    List<Vehicle> vehicles,
  ) async {
    try {
      final pdf = pw.Document();

      // Add title page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Vehicle Owners Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Total Users: ${users.length}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Total Vehicles: ${vehicles.length}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Add users page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Vehicle Owners',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    ['Name', 'Email', 'Phone', 'Role', 'Status'],
                    ...users.map(
                      (user) => [
                        user.name,
                        user.email,
                        user.phoneNumber ?? 'N/A',
                        user.role.displayName,
                        user.status ?? 'active',
                      ],
                    ),
                  ],
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(fontSize: 10),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerLeft,
                    3: pw.Alignment.center,
                    4: pw.Alignment.center,
                  },
                ),
              ],
            );
          },
        ),
      );

      // Add vehicles page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Vehicles',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    [
                      'Make',
                      'Model',
                      'Year',
                      'License Plate',
                      'Color',
                      'User ID',
                    ],
                    ...vehicles.map(
                      (vehicle) => [
                        vehicle.make,
                        vehicle.model,
                        vehicle.year,
                        vehicle.licensePlate,
                        vehicle.color,
                        vehicle.userId,
                      ],
                    ),
                  ],
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(fontSize: 10),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                    4: pw.Alignment.centerLeft,
                    5: pw.Alignment.centerLeft,
                  },
                ),
              ],
            );
          },
        ),
      );

      final fileName =
          'vehicle_owners_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        // Web: Download file directly
        final bytes = await pdf.save();
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return 'Downloaded: $fileName';
      } else {
        // Mobile/Desktop: Save to local storage
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(await pdf.save());
        return file.path;
      }
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  static Future<String> exportToCSV(
    List<User> users,
    List<Vehicle> vehicles,
  ) async {
    try {
      final buffer = StringBuffer();

      // Users CSV
      buffer.writeln('VEHICLE OWNERS');
      buffer.writeln('Name,Email,Phone,Role,Status,Business Name');
      for (var user in users) {
        buffer.writeln(
          '"${user.name}","${user.email}","${user.phoneNumber ?? ''}","${user.role.displayName}","${user.status ?? 'active'}","${user.businessName ?? ''}"',
        );
      }

      buffer.writeln('');
      buffer.writeln('VEHICLES');
      buffer.writeln(
        'Make,Model,Year,License Plate,Color,Battery Level,User ID',
      );
      for (var vehicle in vehicles) {
        buffer.writeln(
          '"${vehicle.make}","${vehicle.model}","${vehicle.year}","${vehicle.licensePlate}","${vehicle.color}","${vehicle.batteryLevel}%","${vehicle.userId}"',
        );
      }

      final fileName =
          'vehicle_owners_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      if (kIsWeb) {
        // Web: Download file directly
        final bytes = buffer.toString().codeUnits;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return 'Downloaded: $fileName';
      } else {
        // Mobile/Desktop: Save to local storage
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(buffer.toString());
        return file.path;
      }
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  static Future<String> exportToText(
    List<User> users,
    List<Vehicle> vehicles,
  ) async {
    try {
      final buffer = StringBuffer();

      buffer.writeln('VEHICLE OWNERS REPORT');
      buffer.writeln('=' * 50);
      buffer.writeln(
        'Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
      );
      buffer.writeln('Total Users: ${users.length}');
      buffer.writeln('Total Vehicles: ${vehicles.length}');
      buffer.writeln('');

      buffer.writeln('VEHICLE OWNERS');
      buffer.writeln('-' * 50);
      for (var user in users) {
        buffer.writeln('Name: ${user.name}');
        buffer.writeln('Email: ${user.email}');
        buffer.writeln('Phone: ${user.phoneNumber ?? 'N/A'}');
        buffer.writeln('Role: ${user.role.displayName}');
        buffer.writeln('Status: ${user.status ?? 'active'}');
        if (user.businessName != null) {
          buffer.writeln('Business: ${user.businessName}');
        }
        buffer.writeln('');
      }

      buffer.writeln('VEHICLES');
      buffer.writeln('-' * 50);
      for (var vehicle in vehicles) {
        buffer.writeln('Make: ${vehicle.make}');
        buffer.writeln('Model: ${vehicle.model}');
        buffer.writeln('Year: ${vehicle.year}');
        buffer.writeln('License Plate: ${vehicle.licensePlate}');
        buffer.writeln('Color: ${vehicle.color}');
        buffer.writeln('Battery Level: ${vehicle.batteryLevel}%');
        buffer.writeln('User ID: ${vehicle.userId}');
        buffer.writeln('');
      }

      final fileName =
          'vehicle_owners_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';

      if (kIsWeb) {
        // Web: Download file directly
        final bytes = buffer.toString().codeUnits;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return 'Downloaded: $fileName';
      } else {
        // Mobile/Desktop: Save to local storage
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(buffer.toString());
        return file.path;
      }
    } catch (e) {
      throw Exception('Failed to export Text: $e');
    }
  }

  static Future<String> exportGenericToPDF({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    required String fileNamePrefix,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 20),
            ],
          ),
          build: (pw.Context context) {
            return [
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[headers, ...data],
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(5),
              ),
            ];
          },
        ),
      );

      final fileName =
          '${fileNamePrefix}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        final bytes = await pdf.save();
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return 'Downloaded: $fileName';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(await pdf.save());
        return file.path;
      }
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  static Future<String> exportGenericToCSV({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    required String fileNamePrefix,
  }) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln(title.toUpperCase());
      buffer.writeln(
        'Generated on,${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
      );
      buffer.writeln('');
      buffer.writeln(headers.join(','));
      for (var row in data) {
        buffer.writeln(
          row.map((e) => '"${e.replaceAll('"', '""')}"').join(','),
        );
      }

      final fileName =
          '${fileNamePrefix}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      if (kIsWeb) {
        final bytes = buffer.toString().codeUnits;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return 'Downloaded: $fileName';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(buffer.toString());
        return file.path;
      }
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  static Future<String> exportGenericToText({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    required String fileNamePrefix,
  }) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln(title.toUpperCase());
      buffer.writeln('=' * title.length);
      buffer.writeln(
        'Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
      );
      buffer.writeln('');

      for (int i = 0; i < data.length; i++) {
        buffer.writeln('Record #${i + 1}');
        buffer.writeln('-' * 20);
        for (int j = 0; j < headers.length; j++) {
          final value = j < data[i].length ? data[i][j] : '';
          buffer.writeln('${headers[j]}: $value');
        }
        buffer.writeln('');
      }

      final fileName =
          '${fileNamePrefix}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';

      if (kIsWeb) {
        final bytes = buffer.toString().codeUnits;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        return 'Downloaded: $fileName';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(buffer.toString());
        return file.path;
      }
    } catch (e) {
      throw Exception('Failed to export Text: $e');
    }
  }
}
