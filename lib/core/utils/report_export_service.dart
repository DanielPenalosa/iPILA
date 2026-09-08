import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/report_model.dart';
import 'download_helper.dart' as dl;

class ReportExportService {
  static const _dateFormat = 'MMM d, yyyy h:mm a';

  // ── CSV ────────────────────────────────────────────────────────────────────

  static void exportCsv(List<ReportModel> reports, {String? filePrefix}) {
    final rows = <List<dynamic>>[
      [
        'ID',
        'Category',
        'Description',
        'Barangay',
        'Address',
        'Reporter',
        'Status',
        'Urgency',
        'Assigned Dept.',
        'Date Submitted',
        'Last Updated',
      ],
      ...reports.map(
        (r) => [
          r.id,
          r.category,
          r.description.replaceAll('\n', ' '),
          r.barangay,
          r.address,
          r.isAnonymous ? 'Anonymous' : r.userFullName,
          r.currentStatus,
          r.urgencyLevel ?? '',
          r.assignedDepartment ?? '',
          DateFormat(_dateFormat).format(r.createdAt),
          DateFormat(_dateFormat).format(r.updatedAt),
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final bytes = csv.codeUnits;
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final prefix = filePrefix ?? 'reports';
    dl.downloadFile('${prefix}_$ts.csv', bytes);
  }

  // ── PDF ────────────────────────────────────────────────────────────────────

  static Future<void> exportPdf(
    BuildContext context,
    List<ReportModel> reports, {
    String? title,
  }) async {
    final doc = pw.Document();
    final now = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final reportTitle = title ?? 'Reports Export';

    // Split into pages of 20 rows
    const pageSize = 20;
    final pages = <List<ReportModel>>[];
    for (var i = 0; i < reports.length; i += pageSize) {
      pages.add(
        reports.sublist(
          i,
          i + pageSize > reports.length ? reports.length : i + pageSize,
        ),
      );
    }

    for (final page in pages) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'iPILA — Municipality of Pila, Laguna',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        reportTitle,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Generated: $now  |  ${reports.length} report${reports.length != 1 ? 's' : ''}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // Table
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.2), // Category
                  1: const pw.FlexColumnWidth(2.5), // Description
                  2: const pw.FlexColumnWidth(1.0), // Barangay
                  3: const pw.FlexColumnWidth(1.2), // Reporter
                  4: const pw.FlexColumnWidth(1.0), // Status
                  5: const pw.FlexColumnWidth(0.7), // Urgency
                  6: const pw.FlexColumnWidth(1.2), // Dept
                  7: const pw.FlexColumnWidth(1.4), // Date
                },
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children:
                        [
                              'Category',
                              'Description',
                              'Barangay',
                              'Reporter',
                              'Status',
                              'Urgency',
                              'Department',
                              'Submitted',
                            ]
                            .map(
                              (h) => pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 5,
                                ),
                                child: pw.Text(
                                  h,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  // Data rows
                  ...page.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    final bg = i.isEven ? PdfColors.white : PdfColors.grey50;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: bg),
                      children:
                          [
                                r.category,
                                r.description.length > 80
                                    ? '${r.description.substring(0, 80)}...'
                                    : r.description,
                                'Brgy. ${r.barangay}',
                                r.isAnonymous ? 'Anonymous' : r.userFullName,
                                r.currentStatus,
                                r.urgencyLevel ?? '—',
                                r.assignedDepartment ?? '—',
                                DateFormat('MMM d, yyyy').format(r.createdAt),
                              ]
                              .map(
                                (cell) => pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: pw.Text(
                                    cell,
                                    style: const pw.TextStyle(fontSize: 7.5),
                                  ),
                                ),
                              )
                              .toList(),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: reportTitle,
    );
  }

  // ── Export dialog ──────────────────────────────────────────────────────────

  static Future<void> showExportDialog(
    BuildContext context,
    List<ReportModel> reports, {
    String? label,
    String? filePrefix,
  }) async {
    if (reports.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No reports to export')));
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.download_outlined, size: 20),
            const SizedBox(width: 8),
            Text(label ?? 'Export Reports'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${reports.length} report${reports.length != 1 ? 's' : ''} will be exported.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            _ExportOption(
              icon: Icons.table_chart_outlined,
              color: const Color(0xFF10B981),
              title: 'Export as CSV',
              subtitle: 'Spreadsheet-friendly, opens in Excel / Google Sheets',
              onTap: () {
                Navigator.pop(ctx);
                try {
                  exportCsv(reports, filePrefix: filePrefix);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('CSV downloaded'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              },
            ),
            const SizedBox(height: 8),
            _ExportOption(
              icon: Icons.picture_as_pdf_outlined,
              color: const Color(0xFFDC2626),
              title: 'Export as PDF',
              subtitle: 'Print-ready document, opens browser print dialog',
              onTap: () async {
                Navigator.pop(ctx);
                await exportPdf(
                  context,
                  reports,
                  title: label ?? 'Reports Export',
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _ExportOption extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_ExportOption> createState() => _ExportOptionState();
}

class _ExportOptionState extends State<_ExportOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.06)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.3)
                  : const Color(0xFFF3F4F6),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, size: 18, color: widget.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: _hovered ? widget.color : const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
