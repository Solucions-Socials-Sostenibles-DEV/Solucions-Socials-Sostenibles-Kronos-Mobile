import 'package:flutter/material.dart';

import '../../services/obrador_service.dart';

class ObradorRegistresTornScreen extends StatefulWidget {
  const ObradorRegistresTornScreen({super.key});

  @override
  State<ObradorRegistresTornScreen> createState() =>
      _ObradorRegistresTornScreenState();
}

class _ObradorRegistresTornScreenState
    extends State<ObradorRegistresTornScreen> {
  static const _moments = <String, String>{
    'inici': 'Inicio de turno',
    'produccio': 'Producción',
    'tancament': 'Cierre de turno',
  };

  static const _checklists = <String, List<(String, String, bool)>>{
    'inici': [
      ('cambres', 'Cámaras frigoríficas encendidas y cerradas', false),
      ('congeladors', 'Congeladores encendidos y cerrados', false),
      ('temperatura_cambres', 'Temperatura de las cámaras', true),
      ('temperatura_congeladors', 'Temperatura de los congeladores', true),
      ('neteja_superficies', 'Superficies limpias antes de empezar', false),
      ('utillatge', 'Utillaje limpio y en buen estado', false),
      ('higiene_personal', 'Higiene personal correcta', false),
    ],
    'produccio': [
      ('temperatures_coccio', 'Temperaturas de cocción anotadas', true),
      (
        'separacio_allergens',
        'Alérgenos separados durante la elaboración',
        false,
      ),
      ('mostres', 'Muestras guardadas e identificadas', false),
    ],
    'tancament': [
      ('neteja', 'Limpieza de superficies y equipos realizada', false),
      ('residus', 'Residuos retirados y contenedores cerrados', false),
      ('tancament_cambres', 'Cámaras y congeladores cerrados', false),
      ('producte_sobrant', 'Producto sobrante etiquetado y guardado', false),
    ],
  };

  final ObradorService _service = ObradorService();
  final TextEditingController _observacions = TextEditingController();
  final Map<String, bool?> _answers = {};
  final Map<String, TextEditingController> _values = {};
  String _moment = 'inici';
  DateTime _data = DateTime.now();
  List<Map<String, dynamic>> _registres = [];
  Map<String, dynamic>? _registreDelDia;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _observacions.dispose();
    for (final controller in _values.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _dateKey =>
      '${_data.year.toString().padLeft(4, '0')}-${_data.month.toString().padLeft(2, '0')}-${_data.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.registresTorn(),
        _service.registreTornDelDia(data: _dateKey, moment: _moment),
      ]);
      if (!mounted) return;
      setState(() {
        _registres = (results[0] as List<Map<String, dynamic>>)
            .where((record) => record['moment'] != null)
            .toList();
        _registreDelDia = results[1] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    setState(() => _data = date);
    await _load();
  }

  Future<void> _save() async {
    final checklist = _checklists[_moment]!;
    final unanswered = checklist.where((item) => _answers[item.$1] == null);
    if (unanswered.isNotEmpty) {
      _message('Responde todos los puntos del checklist antes de guardar.');
      return;
    }
    for (final (key, label, asksValue) in checklist) {
      if (asksValue && _values[key]!.text.trim().isEmpty) {
        _message('Indica el valor registrado para: $label.');
        return;
      }
    }

    final items = checklist.map((item) {
      final (key, label, _) = item;
      return <String, dynamic>{
        'clau': key,
        'etiqueta': label,
        'ok': _answers[key],
        'valor': _values[key]?.text.trim(),
        'nota': null,
      };
    }).toList();

    setState(() => _saving = true);
    try {
      await _service.crearRegistreTorn(
        data: _dateKey,
        moment: _moment,
        items: items,
        observacions: _observacions.text,
      );
      if (!mounted) return;
      _answers.clear();
      for (final controller in _values.values) {
        controller.clear();
      }
      _observacions.clear();
      _message('Checklist de turno guardado.');
      await _load();
    } catch (error) {
      _message('No se pudo guardar el checklist: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registros de turno',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Checklist de inicio, producción y cierre',
                      style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _pickDate,
                                    icon: const Icon(Icons.calendar_month),
                                    label: Text(
                                      '${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}',
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: _moment,
                                    items: _moments.entries
                                        .map(
                                          (entry) => DropdownMenuItem(
                                            value: entry.key,
                                            child: Text(entry.value),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) async {
                                      if (value == null) return;
                                      setState(() => _moment = value);
                                      await _load();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_registreDelDia != null)
                                _savedChecklist(_registreDelDia!)
                              else ...[
                                ..._checklists[_moment]!.map(_checklistItem),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _observacions,
                                  minLines: 2,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Observaciones del turno',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _saving ? null : _save,
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.save_outlined),
                                    label: Text(
                                      _saving
                                          ? 'Guardando…'
                                          : 'Guardar checklist',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Últimos registros',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_registres.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Todavía no hay registros.'),
                          ),
                        )
                      else
                        ..._registres.take(20).map(_recordCard),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _checklistItem((String, String, bool) item) {
    final (key, label, asksValue) = item;
    final controller = _values.putIfAbsent(key, TextEditingController.new);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE7E9ED)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            if (asksValue) ...[
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor leído',
                  suffixText: '°C',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 4),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Correcto')),
                ButtonSegment(value: false, label: Text('Incidencia')),
              ],
              // El checklist empieza sin respuesta y se valida al guardar.
              // Material 3 exige declararlo explícitamente; de lo contrario
              // lanza la aserción selected.length > 0.
              emptySelectionAllowed: true,
              selected: _answers[key] == null ? {} : {_answers[key]!},
              onSelectionChanged: (selection) =>
                  setState(() => _answers[key] = selection.first),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedChecklist(Map<String, dynamic> record) {
    final items = record['items'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.verified, color: Color(0xFF268443)),
            SizedBox(width: 8),
            Expanded(
              child: Text('Este checklist ya está guardado para este turno.'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items is List)
          ...items.map((raw) {
            if (raw is! Map) return const SizedBox.shrink();
            final item = Map<String, dynamic>.from(raw);
            final ok = item['ok'] == true;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                ok ? Icons.check_circle : Icons.warning_amber,
                color: ok ? const Color(0xFF268443) : Colors.orange,
              ),
              title: Text('${item['etiqueta'] ?? item['clau'] ?? 'Punto'}'),
              subtitle: item['valor'] == null || '${item['valor']}'.isEmpty
                  ? null
                  : Text('Valor: ${item['valor']} °C'),
            );
          }),
        if ('${record['observacions'] ?? ''}'.isNotEmpty)
          Text('Observaciones: ${record['observacions']}'),
      ],
    );
  }

  Widget _recordCard(Map<String, dynamic> record) {
    final moment =
        _moments['${record['moment']}'] ??
        '${record['tipus_codi'] ?? 'Registro'}';
    final date = DateTime.tryParse('${record['data'] ?? ''}');
    final hasIssue = record['incidencia_detectada'] == true;
    return Card(
      child: ListTile(
        leading: Icon(
          hasIssue ? Icons.warning_amber : Icons.fact_check_outlined,
          color: hasIssue ? Colors.orange : const Color(0xFF268443),
        ),
        title: Text(moment),
        subtitle: Text(
          '${date == null ? record['data'] ?? 'Sin fecha' : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'}${hasIssue ? ' · Con incidencias' : ' · Correcto'}',
        ),
      ),
    );
  }

  Widget _errorView() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Icon(Icons.cloud_off, size: 42, color: Colors.grey),
      const SizedBox(height: 10),
      const Text(
        'No se han podido cargar los registros de turno.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(_error!, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Center(
        child: OutlinedButton(
          onPressed: _load,
          child: const Text('Reintentar'),
        ),
      ),
    ],
  );
}
