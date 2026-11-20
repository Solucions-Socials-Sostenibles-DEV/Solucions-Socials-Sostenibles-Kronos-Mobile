import 'package:flutter/material.dart';

import '../../services/obrador_service.dart';

class ObradorHigieneScreen extends StatefulWidget {
  const ObradorHigieneScreen({super.key});

  @override
  State<ObradorHigieneScreen> createState() => _ObradorHigieneScreenState();
}

class _ObradorHigieneScreenState extends State<ObradorHigieneScreen> {
  static const _checklists = <String, List<(String, String, bool)>>{
    'neteja_setmanal': [
      ('prestatges_cuina', 'Estantes de la cocina', false),
      ('campana', 'Campana extractora', false),
      ('neveres', 'Interior de las neveras', false),
      ('cubells', 'Cubos de residuos', false),
      ('magatzem', 'Estantes y suelo del almacén', false),
    ],
    'neteja_forn': [('forn', 'Horno', false)],
    'neteja_mensual': [
      ('parets_cuina', 'Paredes altas de la cocina', false),
      ('parets_magatzem', 'Paredes altas del almacén', false),
      ('prestatges_magatzem', 'Estantes del almacén', false),
    ],
    'neteja_congelador': [('congelador', 'Congelador', false)],
  };

  final ObradorService _service = ObradorService();
  List<Map<String, dynamic>> _tipus = [];
  List<Map<String, dynamic>> _registres = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.tipusRegistreHigiene(),
        _service.registresHigiene(),
      ]);
      if (!mounted) return;
      setState(() {
        _tipus = results[0];
        _registres = results[1];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _nouRegistre() async {
    if (_tipus.isEmpty) {
      _msg('No hay tipos de registro activos en Supabase.');
      return;
    }

    String codi = '${_tipus.first['codi']}';
    DateTime data = DateTime.now();
    final notes = TextEditingController();
    final detall = TextEditingController();
    final valor = TextEditingController();
    final answers = <String, bool?>{};
    Map<String, dynamic>? result;

    result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final type = _tipus.firstWhere(
            (item) => '${item['codi']}' == codi,
            orElse: () => _tipus.first,
          );
          final isChecklist = type['es_checklist'] != false;
          final questions = _questionsFor(codi, type);
          final blocked = isChecklist && questions.isEmpty;
          final isWater = codi == 'aigua_clor';

          return Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              14,
              18,
              MediaQuery.of(sheetContext).viewInsets.bottom + 18,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nuevo registro de higiene',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: codi,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de registro',
                    ),
                    items: _tipus
                        .map(
                          (item) => DropdownMenuItem(
                            value: '${item['codi']}',
                            child: Text('${item['etiqueta'] ?? item['codi']}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setSheet(() {
                        codi = value;
                        answers.clear();
                        notes.clear();
                        detall.clear();
                        valor.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Text('Fecha del registro')),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: sheetContext,
                            initialDate: data,
                            firstDate: DateTime(DateTime.now().year - 3),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setSheet(() => data = picked);
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                        ),
                      ),
                    ],
                  ),
                  if (blocked)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Este checklist todavía no tiene puntos configurados. Añade el equipo o las tareas al registro en el proyecto antes de guardarlo.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    )
                  else if (isChecklist)
                    ...questions.map(
                      (question) => _questionWidget(
                        question,
                        answers,
                        setSheet,
                        valueController: question.$3 ? valor : null,
                      ),
                    )
                  else if (isWater)
                    TextField(
                      controller: valor,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cloro libre residual medido',
                        hintText: 'Introduce el valor del análisis',
                      ),
                    )
                  else
                    TextField(
                      controller: detall,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: switch (codi) {
                          'formacio_sessio' => 'Sesión, asistentes y contenido',
                          'residus_retirada' => 'Tipo de residuo y retirada',
                          'manteniment_equips' => 'Equipo, tarea y resultado',
                          _ => 'Detalle del registro',
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: blocked
                              ? null
                              : () {
                                  if (isChecklist &&
                                      questions.any(
                                        (q) => answers[q.$1] == null,
                                      )) {
                                    _msg(
                                      'Responde todos los puntos del checklist.',
                                    );
                                    return;
                                  }
                                  if (questions.any(
                                    (q) => q.$3 && valor.text.trim().isEmpty,
                                  )) {
                                    _msg('Introduce el valor medido.');
                                    return;
                                  }
                                  if (!isChecklist &&
                                      detall.text.trim().isEmpty &&
                                      !isWater) {
                                    _msg('Completa el detalle del registro.');
                                    return;
                                  }
                                  if (isWater && valor.text.trim().isEmpty) {
                                    _msg('Introduce el valor del análisis.');
                                    return;
                                  }
                                  final items = questions.map((question) {
                                    final (key, label, asksValue) = question;
                                    return <String, dynamic>{
                                      'clau': key,
                                      'etiqueta': label,
                                      'ok': answers[key],
                                      'valor': asksValue
                                          ? valor.text.trim()
                                          : null,
                                      'nota': null,
                                    };
                                  }).toList();
                                  Navigator.pop(sheetContext, {
                                    'codi': codi,
                                    'data': data,
                                    'items': items,
                                    'notes': notes.text,
                                    'incidencia': items.any(
                                      (item) => item['ok'] == false,
                                    ),
                                    'detall': isChecklist
                                        ? null
                                        : <String, dynamic>{
                                            if (isWater)
                                              'valor': valor.text.trim(),
                                            if (!isWater)
                                              'nota': detall.text.trim(),
                                          },
                                  });
                                },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result != null) {
      try {
        await _service.crearRegistreHigiene(
          tipusCodi: result['codi'] as String,
          data: result['data'] as DateTime,
          observacions: result['notes'] as String,
          incidenciaDetectada: result['incidencia'] as bool,
          items: (result['items'] as List).cast<Map<String, dynamic>>(),
          detall: result['detall'] as Map<String, dynamic>?,
        );
        _msg('Registro guardado.');
        await _load();
      } catch (error) {
        _msg('No se pudo guardar el registro: $error');
      }
    }
    notes.dispose();
    detall.dispose();
    valor.dispose();
  }

  List<(String, String, bool)> _questionsFor(
    String code,
    Map<String, dynamic> type,
  ) {
    if (_checklists.containsKey(code)) return _checklists[code]!;
    if (code == 'torn_inici') {
      return const [
        ('cambres', 'Cámaras frigoríficas encendidas y cerradas', false),
        ('congeladors', 'Congeladores encendidos y cerrados', false),
        ('temperatura_cambres', 'Temperatura de las cámaras', true),
        ('temperatura_congeladors', 'Temperatura de los congeladores', true),
        ('neteja_superficies', 'Superficies limpias antes de empezar', false),
        ('utillatge', 'Utillaje limpio y en buen estado', false),
        ('higiene_personal', 'Higiene personal correcta', false),
      ];
    }
    if (code == 'torn_produccio') {
      return const [
        ('temperatures_coccio', 'Temperaturas de cocción anotadas', true),
        ('separacio_allergens', 'Alérgenos separados', false),
        ('mostres', 'Muestras guardadas e identificadas', false),
      ];
    }
    if (code == 'torn_tancament') {
      return const [
        ('neteja', 'Limpieza de superficies y equipos realizada', false),
        ('residus', 'Residuos retirados', false),
        ('tancament_cambres', 'Cámaras y congeladores cerrados', false),
        ('producte_sobrant', 'Producto sobrante etiquetado y guardado', false),
      ];
    }
    final configured = _checklists[code];
    if (configured != null) return configured;
    if (type['es_checklist'] == true) {
      if (code == 'temperatures_equips' || code == 'neteja_cuina') {
        return const [];
      }
      return [('$code', '${type['etiqueta'] ?? 'Control'} realizado', false)];
    }
    return const [];
  }

  Widget _questionWidget(
    (String, String, bool) question,
    Map<String, bool?> answers,
    StateSetter setSheet, {
    TextEditingController? valueController,
  }) {
    final (key, label, asksValue) = question;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7E9ED)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (asksValue && valueController != null) ...[
            const SizedBox(height: 8),
            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor medido',
                suffixText: '°C',
              ),
            ),
          ],
          const SizedBox(height: 4),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Correcto')),
              ButtonSegment(value: false, label: Text('Incidencia')),
            ],
              emptySelectionAllowed: true,
            selected: answers[key] == null ? {} : {answers[key]!},
            onSelectionChanged: (selection) =>
                setSheet(() => answers[key] = selection.first),
          ),
        ],
      ),
    );
  }

  void _msg(String message) {
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
                      'Planes de higiene',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Controles y registros guardados en Supabase',
                      style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              FilledButton.icon(
                onPressed: _nouRegistre,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _errorView()
              : _registres.isEmpty
              ? const Center(
                  child: Text('Todavía no hay registros de higiene.'),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                    itemCount: _registres.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 7),
                    itemBuilder: (context, index) =>
                        _recordCard(_registres[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _recordCard(Map<String, dynamic> record) {
    final type = record['obrador_tipus_registre'];
    final title = type is Map
        ? '${type['etiqueta'] ?? record['tipus_codi']}'
        : '${record['tipus_codi'] ?? 'Registro'}';
    final date = DateTime.tryParse('${record['data'] ?? ''}');
    final hasIssue = record['incidencia_detectada'] == true;
    final items = record['items'];
    return Card(
      child: ExpansionTile(
        leading: Icon(
          hasIssue ? Icons.warning_amber : Icons.fact_check_outlined,
          color: hasIssue ? Colors.orange : const Color(0xFF268443),
        ),
        title: Text(title),
        subtitle: Text(
          '${date == null ? record['data'] ?? 'Sin fecha' : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'}${hasIssue ? ' · Incidencia detectada' : ''}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
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
                title: Text('${item['etiqueta'] ?? item['clau'] ?? 'Control'}'),
                subtitle: item['valor'] == null || '${item['valor']}'.isEmpty
                    ? null
                    : Text('Valor: ${item['valor']}'),
              );
            }),
          if (record['detall'] != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Detalle: ${record['detall']}'),
            ),
          if ('${record['observacions'] ?? ''}'.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Observaciones: ${record['observacions']}'),
            ),
        ],
      ),
    );
  }

  Widget _errorView() => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const Icon(Icons.cloud_off, size: 40, color: Colors.grey),
      const SizedBox(height: 10),
      const Text(
        'No se pudieron cargar los planes de higiene.',
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
