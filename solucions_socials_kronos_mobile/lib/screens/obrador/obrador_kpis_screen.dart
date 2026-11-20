import 'package:flutter/material.dart';

import '../../services/obrador_service.dart';

class ObradorKpisScreen extends StatefulWidget {
  const ObradorKpisScreen({super.key});

  @override
  State<ObradorKpisScreen> createState() => _ObradorKpisScreenState();
}

class _ObradorKpisScreenState extends State<ObradorKpisScreen> {
  static const _monthNames = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  final ObradorService _service = ObradorService();
  bool _loading = true;
  String? _error;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<Map<String, dynamic>> _lots = [];
  List<Map<String, dynamic>> _recepcions = [];
  List<Map<String, dynamic>> _expedicions = [];
  List<Map<String, dynamic>> _incidencies = [];
  List<Map<String, dynamic>> _temperatures = [];
  List<Map<String, dynamic>> _higiene = [];
  List<Map<String, dynamic>> _escandalls = [];
  Map<String, dynamic>? _socialData;

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
        _service.lots(),
        _service.recepcions(),
        _service.expedicions(),
        _service.incidencies(),
        _service.temperatures(),
        _service.registresHigiene(),
        _service.escandalls(),
        _service.kpiMensual(_month),
      ]);
      if (!mounted) return;
      setState(() {
        _lots = results[0] as List<Map<String, dynamic>>;
        _recepcions = results[1] as List<Map<String, dynamic>>;
        _expedicions = results[2] as List<Map<String, dynamic>>;
        _incidencies = results[3] as List<Map<String, dynamic>>;
        _temperatures = results[4] as List<Map<String, dynamic>>;
        _higiene = results[5] as List<Map<String, dynamic>>;
        _escandalls = results[6] as List<Map<String, dynamic>>;
        _socialData = results[7] as Map<String, dynamic>?;
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

  bool _inMonth(dynamic value) {
    final date = DateTime.tryParse('${value ?? ''}')?.toLocal();
    return date != null &&
        date.year == _month.year &&
        date.month == _month.month;
  }

  Future<void> _chooseMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      helpText: 'Elige un día del mes',
    );
    if (picked == null || !mounted) return;
    setState(() => _month = DateTime(picked.year, picked.month));
    await _load();
  }

  String _monthName(DateTime month) =>
      '${_monthNames[month.month - 1]} ${month.year}';

  double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  List<Map<String, dynamic>> _ingredients(Map<String, dynamic> escandall) {
    final rows = escandall['obrador_escandall_ingredients'];
    return rows is List
        ? rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
        : const [];
  }

  double _recipeCost(Map<String, dynamic> escandall) => _ingredients(escandall)
      .fold<double>(0, (sum, item) =>
          sum +
          _number(item['quantitat']) *
              _number(item['cost_unitari']) *
              (1 + _number(item['merma_percent']) / 100));

  ({int lots, double cost, double revenue}) _productionCosts(
    List<Map<String, dynamic>> lots,
  ) {
    final byProduct = <String, Map<String, dynamic>>{
      for (final escandall in _escandalls)
        if (escandall['id_producte'] != null) '${escandall['id_producte']}': escandall,
    };
    var matchedLots = 0;
    var cost = 0.0;
    var revenue = 0.0;
    for (final lot in lots) {
      final escandall = byProduct['${lot['id_producte'] ?? ''}'];
      if (escandall == null || escandall['unitat_rendiment'] != 'kg') continue;
      final yieldKg = _number(escandall['rendiment']);
      final quantityKg = _number(lot['quantitat_kg']);
      if (yieldKg <= 0 || quantityKg <= 0) continue;
      matchedLots++;
      cost += _recipeCost(escandall) / yieldKg * quantityKg;
      revenue += _number(escandall['pvp_unitari']) * quantityKg;
    }
    return (lots: matchedLots, cost: cost, revenue: revenue);
  }

  Future<void> _editSocialData() async {
    final people = TextEditingController(
      text: '${_socialData?['personas_insercion'] ?? 0}',
    );
    final training = TextEditingController(
      text: '${_socialData?['horas_formacion'] ?? 0}',
    );
    final hires = TextEditingController(
      text: '${_socialData?['contrataciones'] ?? 0}',
    );
    final notes = TextEditingController(
      text: '${_socialData?['observaciones'] ?? ''}',
    );
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Datos sociales · ${_monthName(_month)}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: people,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Personas en inserción',
                  ),
                ),
                TextField(
                  controller: training,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Horas de formación'),
                ),
                TextField(
                  controller: hires,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Contrataciones'),
                ),
                TextField(
                  controller: notes,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final parsedPeople = int.tryParse(people.text.trim());
              final parsedTraining = double.tryParse(
                training.text.trim().replaceAll(',', '.'),
              );
              final parsedHires = int.tryParse(hires.text.trim());
              if (parsedPeople == null ||
                  parsedPeople < 0 ||
                  parsedTraining == null ||
                  parsedTraining < 0 ||
                  parsedHires == null ||
                  parsedHires < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Revisa los indicadores sociales.')),
                );
                return;
              }
              Navigator.pop(dialogContext, {
                'people': parsedPeople,
                'training': parsedTraining,
                'hires': parsedHires,
                'notes': notes.text,
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    people.dispose();
    training.dispose();
    hires.dispose();
    notes.dispose();
    if (data == null || !mounted) return;
    try {
      await _service.guardarKpiMensual(
        month: _month,
        personasInsercion: data['people'] as int,
        horasFormacion: data['training'] as double,
        contrataciones: data['hires'] as int,
        observaciones: data['notes'] as String?,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indicadores sociales guardados.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se han podido guardar los indicadores: $error')),
      );
    }
  }

  List<(String, String, String, IconData)> _metrics() {
    final lots = _lots
        .where((item) => _inMonth(item['data_produccio']))
        .toList();
    final receipts = _recepcions
        .where((item) => _inMonth(item['data_recepcio']))
        .toList();
    final shipments = _expedicions
        .where((item) => _inMonth(item['data_sortida']))
        .toList();
    final incidents = _incidencies
        .where((item) => _inMonth(item['data_incidencia']))
        .toList();
    final hygiene = _higiene.where((item) => _inMonth(item['data'])).toList();
    final openedIncidents = incidents
        .where((item) => ['oberta', 'en_curs'].contains(item['estat']))
        .length;
    final incidentPercent = lots.isEmpty
        ? 0.0
        : (incidents.length / lots.length) * 100;
    final productionCosts = _productionCosts(lots);
    final grossMargin = productionCosts.revenue <= 0
        ? null
        : (productionCosts.revenue - productionCosts.cost) /
              productionCosts.revenue *
              100;
    final peopleInInsertion = _socialData?['personas_insercion'];
    final trainingHours = _socialData?['horas_formacion'];
    final hires = _socialData?['contrataciones'];

    final complianceChecks = <bool>[];
    for (final item in receipts) {
      complianceChecks.add(item['estat'] == 'bo');
    }
    for (final item in shipments) {
      complianceChecks.add(
        item['check_sortida'] == true && item['check_client'] == true,
      );
    }
    for (final item in hygiene) {
      final items = item['items'];
      if (items is List && items.isNotEmpty) {
        complianceChecks.add(
          items.every((raw) => raw is Map && raw['ok'] == true),
        );
      }
    }
    for (final item in _temperatures.where(
      (item) => _inMonth(item['mesura_at']),
    )) {
      final value = double.tryParse('${item['valor'] ?? ''}');
      if (value == null) continue;
      final type = '${item['tipus'] ?? 'refrigeracio'}';
      final ok = switch (type) {
        'congelacio' => value >= -22 && value <= -18,
        'conservacio' => value >= 2 && value <= 8,
        'zonaProduccio' => value >= 18 && value <= 25,
        _ => value >= 0 && value <= 4,
      };
      complianceChecks.add(ok);
    }
    final compliance = complianceChecks.isEmpty
        ? null
        : complianceChecks.where((ok) => ok).length /
              complianceChecks.length *
              100;

    return [
      (
        '1',
        'Margen bruto estimado',
        grossMargin == null
            ? 'Vincula escandallos (kg) a los productos producidos'
            : '${grossMargin.toStringAsFixed(1)}% · ingresos ${productionCosts.revenue.toStringAsFixed(2)} €',
        Icons.show_chart,
      ),
      (
        '2',
        'Coste por lote producido',
        productionCosts.lots == 0
            ? 'Sin lotes con escandallo vinculado en el periodo'
            : '${(productionCosts.cost / productionCosts.lots).toStringAsFixed(2)} € de media · ${productionCosts.lots} lotes',
        Icons.euro,
      ),
      (
        '3',
        'Lotes y porcentaje de incidencias',
        '${lots.length} lotes · ${incidentPercent.toStringAsFixed(1)}% · $openedIncidents abiertas',
        Icons.inventory_2_outlined,
      ),
      (
        '4',
        'Cumplimiento APPCC',
        compliance == null
            ? 'Sin datos del periodo'
            : '${compliance.toStringAsFixed(1)}% de controles conformes',
        Icons.fact_check_outlined,
      ),
      (
        '5',
        'Personas en inserción',
        peopleInInsertion == null
            ? 'Dato social pendiente de registrar'
            : '$peopleInInsertion personas en ${_monthName(_month)}',
        Icons.people_outline,
      ),
      (
        '6',
        'Formación y contrataciones',
        trainingHours == null && hires == null
            ? 'Dato social pendiente de registrar'
            : '${_number(trainingHours).toStringAsFixed(1)} h · ${hires ?? 0} contrataciones',
        Icons.school_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics();
    final previousMonth = DateTime(_month.year, _month.month - 1);
    final width = MediaQuery.of(context).size.width;
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
                      'KPIs mensuales',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Cuadro de gestión del obrador',
                      style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              OutlinedButton.icon(
                onPressed: _chooseMonth,
                icon: const Icon(Icons.calendar_month),
                label: Text(_monthName(_month)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _loading ? null : _editSocialData,
                icon: const Icon(Icons.people_outline),
                label: const Text('Datos sociales'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No se han podido cargar los indicadores.\n$_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      Text(
                        'Comparativa prevista: ${_monthName(_month)} vs ${_monthName(previousMonth)}',
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: width > 800 ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: width > 800 ? 1.35 : 1.05,
                        children: metrics
                            .map((metric) => _metricCard(metric))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notas de cálculo',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Los indicadores operativos se calculan con los registros cargados para el mes. Margen, coste por lote e impacto social requieren fuentes de datos adicionales y permanecen pendientes.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _metricCard((String, String, String, IconData) metric) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE7E9ED)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'KPI ${metric.$1}',
              style: const TextStyle(color: Color(0xFF667085), fontSize: 11),
            ),
            const Spacer(),
            Icon(metric.$4, color: const Color(0xFF36A852), size: 20),
          ],
        ),
        Text(
          metric.$2,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        Text(
          metric.$3,
          style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
        ),
      ],
    ),
  );
}
