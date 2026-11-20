import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' show PdfColors, PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;

import '../../services/obrador_service.dart';

class ObradorExportacioScreen extends StatefulWidget {
  const ObradorExportacioScreen({super.key});

  @override
  State<ObradorExportacioScreen> createState() =>
      _ObradorExportacioScreenState();
}

class _ObradorExportacioScreenState extends State<ObradorExportacioScreen> {
  final ObradorService _service = ObradorService();
  late DateTime _desde;
  late DateTime _fins;
  String? _working;
  String? _error;
  Map<String, List<Map<String, dynamic>>>? _summary;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _desde = DateTime(now.year, now.month, 1);
    _fins = DateTime(now.year, now.month, now.day);
  }

  String _date(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  String _iso(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  void _thisMonth() {
    final now = DateTime.now();
    setState(() {
      _desde = DateTime(now.year, now.month, 1);
      _fins = DateTime(now.year, now.month, now.day);
      _error = null;
    });
  }

  void _lastMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 0);
    setState(() {
      _desde = start;
      _fins = end;
      _error = null;
    });
  }

  Future<void> _chooseDate({required bool start}) async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: start ? _desde : _fins,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (chosen == null || !mounted) return;
    setState(() {
      if (start) {
        _desde = chosen;
        if (_fins.isBefore(_desde)) _fins = _desde;
      } else {
        _fins = chosen;
        if (_fins.isBefore(_desde)) _desde = _fins;
      }
      _error = null;
    });
  }

  Future<void> _export(String format) async {
    setState(() {
      _working = format;
      _error = null;
    });
    try {
      final data = await _service.exportacio(desde: _desde, fins: _fins);
      if (!mounted) return;
      setState(() => _summary = data);
      final stamp = '${_iso(_desde)}_${_iso(_fins)}';
      final bytes = format == 'pdf' ? await _pdf(data) : _csv(data);
      final extension = format == 'pdf' ? 'pdf' : 'csv';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar exportación del obrador',
        fileName: 'obrador_inspeccion_$stamp.$extension',
        type: FileType.custom,
        allowedExtensions: [extension],
        bytes: Uint8List.fromList(bytes),
      );
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo guardado: $path'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  List<int> _csv(Map<String, List<Map<String, dynamic>>> data) {
    final buffer = StringBuffer('\uFEFF');
    for (final entry in data.entries) {
      buffer.writeln(_row([entry.key]));
      buffer.writeln(_row(['Periodo', '${_iso(_desde)} - ${_iso(_fins)}']));
      final rows = entry.value;
      if (rows.isEmpty) {
        buffer.writeln(_row(['Sin registros']));
        buffer.writeln();
        continue;
      }
      final keys = <String>{};
      for (final item in rows) {
        keys.addAll(item.keys);
      }
      final columns = keys.toList();
      buffer.writeln(_row(columns));
      for (final item in rows) {
        buffer.writeln(_row(columns.map((key) => _cell(item[key])).toList()));
      }
      buffer.writeln();
    }
    return utf8.encode(buffer.toString());
  }

  String _row(List<Object?> values) => values
      .map((value) {
        final text = '$value';
        return '"${text.replaceAll('"', '""')}"';
      })
      .join(';');

  String _cell(dynamic value) {
    if (value == null) return '';
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }

  Future<List<int>> _pdf(Map<String, List<Map<String, dynamic>>> data) async {
    final document = pw.Document();
    final titleStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(595, 842, marginAll: 34),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Obrador · Informe de inspección', style: titleStyle),
              pw.Text('${_date(_desde)} - ${_date(_fins)}'),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Página ${context.pageNumber}'),
        ),
        build: (context) => [
          pw.Text('Registros incluidos en el periodo seleccionado.'),
          pw.SizedBox(height: 16),
          ...data.entries.expand((entry) {
            final rows = entry.value;
            return <pw.Widget>[
              pw.Text('${entry.key} (${rows.length})', style: titleStyle),
              pw.SizedBox(height: 5),
              if (rows.isEmpty)
                pw.Text('Sin registros en este periodo.')
              else
                ...rows.map(
                  (row) => pw.Container(
                    width: double.infinity,
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.all(7),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: row.entries
                          .where((item) => item.value != null)
                          .map(
                            (item) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              child: pw.Text(
                                '${item.key}: ${_cell(item.value)}',
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              pw.SizedBox(height: 13),
            ];
          }),
        ],
      ),
    );
    return document.save();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Exportación para inspección',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        const Text(
          'Descarga recepciones, lotes, expediciones, incidencias, registros de turno y temperaturas del periodo.',
          style: TextStyle(color: Color(0xFF667085), fontSize: 13),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _thisMonth,
                      child: const Text('Este mes'),
                    ),
                    OutlinedButton(
                      onPressed: _lastMonth,
                      child: const Text('Mes anterior'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _chooseDate(start: true),
                      icon: const Icon(Icons.calendar_month),
                      label: Text('Desde: ${_date(_desde)}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _chooseDate(start: false),
                      icon: const Icon(Icons.calendar_month),
                      label: Text('Hasta: ${_date(_fins)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _working == null ? () => _export('pdf') : null,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        _working == 'pdf' ? 'Preparando PDF…' : 'Descargar PDF',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _working == null ? () => _export('csv') : null,
                      icon: const Icon(Icons.table_chart_outlined),
                      label: Text(
                        _working == 'csv' ? 'Preparando CSV…' : 'Descargar CSV',
                      ),
                    ),
                  ],
                ),
                if (_working != null) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
        if (_error != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('No se pudo preparar la exportación.\n$_error'),
            ),
          ),
        if (_summary != null) ...[
          const SizedBox(height: 14),
          const Text(
            'Resumen del archivo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ..._summary!.entries.map(
            (entry) => Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(entry.key),
                trailing: Text('${entry.value.length}'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
