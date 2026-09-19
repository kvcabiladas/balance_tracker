import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

class PdfService {
  static final _dateFormat = DateFormat('dd MMMM yyyy HH:mm');
  static final _currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

  /// Generates a PDF statement for a specific person's tab and opens the native printing/sharing panel
  static Future<void> exportPersonTabPdf(PersonTab personTab) async {
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    final doc = pw.Document(
      title: 'Balance Tracker Statement - ${personTab.name}',
      author: 'Balance Tracker App',
      theme: pw.ThemeData.withFont(
        base: font,
        bold: fontBold,
        italic: fontItalic,
      ),
    );

    final primaryColor = PdfColor.fromHex('#0F172A'); // Slate 900
    final secondaryColor = PdfColor.fromHex('#475569'); // Slate 600
    final emeraldColor = PdfColor.fromHex('#059669'); // Emerald 600
    final roseColor = PdfColor.fromHex('#B91C1C'); // Rose 600
    final greyColor = PdfColor.fromHex('#94A3B8'); // Slate 400
    final lightBg = PdfColor.fromHex('#F8FAFC'); // Slate 50
    final borderBg = PdfColor.fromHex('#E2E8F0'); // Slate 200

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final netBalance = personTab.netBalance;
          final isOwedToMe = netBalance >= 0;

          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BALANCE TRACKER',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'STATEMENT OF ACCOUNT',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                    pw.Text(
                      'Generated: ${_dateFormat.format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: greyColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: borderBg, height: 24),

            // Tab Details Card
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: borderBg, width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TAB OWNER',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        personTab.name,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'NET TAB BALANCE',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _currencyFormat.format(netBalance.abs()),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: netBalance == 0
                              ? primaryColor
                              : (isOwedToMe ? emeraldColor : roseColor),
                        ),
                      ),
                      pw.Text(
                        netBalance == 0
                            ? 'SETTLED'
                            : (isOwedToMe ? 'Owed to Me' : 'I Owe Them'),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: netBalance == 0
                              ? greyColor
                              : (isOwedToMe ? emeraldColor : roseColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Transactions Table
            pw.Text(
              'TRANSACTION HISTORY',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(color: borderBg, width: 0.5),
                bottom: pw.BorderSide(color: borderBg, width: 1),
              ),
              columnWidths: const {
                0: pw.FixedColumnWidth(80),
                1: pw.FlexColumnWidth(3),
                2: pw.FixedColumnWidth(85),
                3: pw.FixedColumnWidth(70),
                4: pw.FixedColumnWidth(70),
                5: pw.FixedColumnWidth(50),
              },
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: primaryColor),
                  children: [
                    _buildTableHeaderCell('Date'),
                    _buildTableHeaderCell('Description'),
                    _buildTableHeaderCell('Method'),
                    _buildTableHeaderCell('Original', align: pw.Alignment.centerRight),
                    _buildTableHeaderCell('Outstanding', align: pw.Alignment.centerRight),
                    _buildTableHeaderCell('Status', align: pw.Alignment.center),
                  ],
                ),
                ...personTab.transactions.map((tx) {
                  final isOwedTx = tx.type == TransactionType.owedToMe;
                  final textStyle = tx.isPaid
                      ? pw.TextStyle(
                          color: greyColor,
                          fontSize: 8,
                          decoration: pw.TextDecoration.lineThrough,
                        )
                      : pw.TextStyle(
                          color: primaryColor,
                          fontSize: 9,
                        );

                  return pw.TableRow(
                    children: [
                      _buildTableCell(
                        DateFormat('dd MMM yyyy').format(tx.date),
                        style: pw.TextStyle(color: secondaryColor, fontSize: 8),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              tx.description.isEmpty ? '-' : tx.description,
                              style: textStyle,
                            ),
                            if (tx.payments.isNotEmpty) ...[
                              pw.SizedBox(height: 4),
                              ...tx.payments.map((p) {
                                return pw.Text(
                                  '  • Paid ${_currencyFormat.format(p.amount)} via ${p.method} (${DateFormat('dd MMM yyyy').format(p.date)})',
                                  style: pw.TextStyle(
                                    fontSize: 7,
                                    color: secondaryColor,
                                    fontStyle: pw.FontStyle.italic,
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                      _buildTableCell(
                        tx.methodOfUtang,
                        style: tx.isPaid
                            ? pw.TextStyle(color: greyColor, fontSize: 8)
                            : pw.TextStyle(
                                color: isOwedTx ? emeraldColor : roseColor,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8,
                              ),
                      ),
                      _buildTableCell(
                        _currencyFormat.format(tx.amount),
                        align: pw.Alignment.centerRight,
                        style: tx.isPaid
                            ? pw.TextStyle(
                                color: greyColor,
                                fontSize: 8,
                                decoration: pw.TextDecoration.lineThrough,
                              )
                            : pw.TextStyle(
                                color: primaryColor,
                                fontSize: 9,
                              ),
                      ),
                      _buildTableCell(
                        _currencyFormat.format(tx.remainingAmount),
                        align: pw.Alignment.centerRight,
                        style: tx.isPaid
                            ? pw.TextStyle(
                                color: greyColor,
                                fontSize: 8,
                                decoration: pw.TextDecoration.lineThrough,
                              )
                            : pw.TextStyle(
                                color: isOwedTx ? emeraldColor : roseColor,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9,
                              ),
                      ),
                      _buildTableCell(
                        tx.isPaid ? 'PAID' : 'ACTIVE',
                        align: pw.Alignment.center,
                        style: pw.TextStyle(
                          color: tx.isPaid ? greyColor : primaryColor,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 30),

            // Summary Totals Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _buildSummaryRow(
                        'Total Owed to Me (Outstanding):',
                        _currencyFormat.format(personTab.totalOwedToMe),
                        style: pw.TextStyle(color: emeraldColor, fontSize: 9),
                      ),
                      pw.SizedBox(height: 4),
                      _buildSummaryRow(
                        'Total I Owe Them (Outstanding):',
                        _currencyFormat.format(personTab.totalIOweThem),
                        style: pw.TextStyle(color: roseColor, fontSize: 9),
                      ),
                      pw.Divider(color: borderBg, thickness: 1, height: 12),
                      _buildSummaryRow(
                        'NET TAB BALANCE:',
                        _currencyFormat.format(netBalance.abs()),
                        style: pw.TextStyle(
                          color: netBalance == 0
                              ? primaryColor
                              : (isOwedToMe ? emeraldColor : roseColor),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 50),
            pw.Center(
              child: pw.Text(
                'Generated statement is for personal tracking purposes only.',
                style: pw.TextStyle(
                  fontSize: 7,
                  color: greyColor,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Statement-${personTab.name.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, {pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {pw.Alignment align = pw.Alignment.centerLeft, required pw.TextStyle style}) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        text,
        style: style,
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, {required pw.TextStyle style}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#475569')),
        ),
        pw.Text(
          value,
          style: style,
        ),
      ],
    );
  }
}
