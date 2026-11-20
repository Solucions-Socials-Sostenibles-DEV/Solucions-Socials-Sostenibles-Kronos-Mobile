import 'package:flutter/material.dart';

import '../../services/obrador_service.dart';

class EscandallsScreen extends StatefulWidget {
  const EscandallsScreen({super.key});

  @override
  State<EscandallsScreen> createState() => _EscandallsScreenState();
}

class _EscandallsScreenState extends State<EscandallsScreen> {
  static const _withoutProduct = '__without_product__';
  final ObradorService _service = ObradorService();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _query = '';

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
      final result = await Future.wait([_service.escandalls(), _service.productes()]);
      if (!mounted) return;
      setState(() {
        _items = result[0];
        _products = result[1];
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

  double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  List<Map<String, dynamic>> _ingredients(Map<String, dynamic> item) {
    final value = item['obrador_escandall_ingredients'];
    return value is List
        ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const [];
  }

  double _lineCost(Map<String, dynamic> item) =>
      _number(item['quantitat']) *
      _number(item['cost_unitari'] ?? item['costUnitari']) *
      (1 + _number(item['merma_percent'] ?? item['merma']) / 100);

  double _recipeCost(Map<String, dynamic> item) =>
      _ingredients(item).fold(0, (total, ingredient) => total + _lineCost(ingredient));

  double _yield(Map<String, dynamic> item) =>
      _number(item['rendiment']).clamp(0.000001, double.infinity);

  double _unitCost(Map<String, dynamic> item) => _recipeCost(item) / _yield(item);

  double _margin(Map<String, dynamic> item) {
    final price = _number(item['pvp_unitari']);
    return price <= 0 ? 0 : (price - _unitCost(item)) / price * 100;
  }

  Future<void> _create() async {
    final name = TextEditingController();
    final yieldController = TextEditingController(text: '1');
    final price = TextEditingController();
    final notes = TextEditingController();
    final ingredients = <Map<String, dynamic>>[];
    var line = 'frescos';
    var unit = 'kg';
    var productId = _withoutProduct;

    final input = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo escandallo'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre de la receta'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: productId,
                    decoration: const InputDecoration(labelText: 'Producto trazable (opcional)'),
                    items: [
                      const DropdownMenuItem(value: _withoutProduct, child: Text('Sin vincular')),
                      ..._products.map((product) => DropdownMenuItem(
                            value: '${product['id']}',
                            child: Text('${product['nom'] ?? 'Producto'}'),
                          )),
                    ],
                    onChanged: (value) => value == null
                        ? null
                        : setDialogState(() => productId = value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: line,
                    decoration: const InputDecoration(labelText: 'Línea'),
                    items: const [
                      DropdownMenuItem(value: 'frescos', child: Text('Frescos')),
                      DropdownMenuItem(value: 'fred', child: Text('Frío')),
                      DropdownMenuItem(value: 'rebosteria', child: Text('Repostería')),
                    ],
                    onChanged: (value) => value == null
                        ? null
                        : setDialogState(() => line = value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: yieldController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Rendimiento'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: unit,
                          decoration: const InputDecoration(labelText: 'Unidad'),
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'unidad', child: Text('unidad')),
                            DropdownMenuItem(value: 'l', child: Text('l')),
                          ],
                          onChanged: (value) => value == null
                              ? null
                              : setDialogState(() => unit = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'PVP por $unit (€)'),
                  ),
                  const SizedBox(height: 14),
                  const Text('Ingredientes', style: TextStyle(fontWeight: FontWeight.bold)),
                  for (final entry in ingredients.asMap().entries)
                    ListTile(
                      dense: true,
                      title: Text('${entry.value['nom']}'),
                      subtitle: Text('${entry.value['quantitat']} ${entry.value['unitat']} · ${entry.value['costUnitari']} € · merma ${entry.value['merma']}%'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar ingrediente',
                        onPressed: () => setDialogState(() => ingredients.removeAt(entry.key)),
                      ),
                    ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir ingrediente'),
                    onPressed: () async {
                      final ingredient = await _createIngredient(context);
                      if (ingredient != null) {
                        setDialogState(() => ingredients.add(ingredient));
                      }
                    },
                  ),
                  if (ingredients.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Coste de receta: ${ingredients.fold<double>(0, (total, item) => total + _lineCost(item)).toStringAsFixed(2)} €'),
                    ),
                  const SizedBox(height: 8),
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
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final parsedYield = double.tryParse(yieldController.text.replaceAll(',', '.'));
                final parsedPrice = double.tryParse(price.text.replaceAll(',', '.'));
                if (name.text.trim().isEmpty ||
                    parsedYield == null || parsedYield <= 0 ||
                    parsedPrice == null || parsedPrice < 0 ||
                    ingredients.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa nombre, rendimiento, PVP y al menos un ingrediente.')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, {
                  'nom': name.text.trim(),
                  'linia': line,
                  'idProducte': productId == _withoutProduct ? null : productId,
                  'rendiment': parsedYield,
                  'unitatRendiment': unit,
                  'pvpUnitari': parsedPrice,
                  'observacions': notes.text,
                  'ingredients': ingredients,
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    yieldController.dispose();
    price.dispose();
    notes.dispose();
    if (input == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await _service.crearEscandall(
        nom: input['nom'] as String,
        linia: input['linia'] as String,
        idProducte: input['idProducte'] as String?,
        rendiment: input['rendiment'] as double,
        unitatRendiment: input['unitatRendiment'] as String,
        pvpUnitari: input['pvpUnitari'] as double,
        observacions: input['observacions'] as String?,
        ingredients: List<Map<String, dynamic>>.from(input['ingredients'] as List),
      );
      if (!mounted) return;
      _message('Escandallo guardado en Supabase.');
      await _load();
    } catch (error) {
      _message('No se pudo guardar el escandallo: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<Map<String, dynamic>?> _createIngredient(BuildContext context) async {
    final name = TextEditingController();
    final quantity = TextEditingController(text: '1');
    final cost = TextEditingController();
    final waste = TextEditingController(text: '0');
    var unit = 'kg';
    final ingredient = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ingrediente'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Ingrediente o materia prima')),
              TextField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cantidad')),
              DropdownButtonFormField<String>(
                value: unit,
                decoration: const InputDecoration(labelText: 'Unidad'),
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'g', child: Text('g')),
                  DropdownMenuItem(value: 'l', child: Text('l')),
                  DropdownMenuItem(value: 'ml', child: Text('ml')),
                  DropdownMenuItem(value: 'unidad', child: Text('unidad')),
                ],
                onChanged: (value) => value == null ? null : setDialogState(() => unit = value),
              ),
              TextField(controller: cost, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Coste por unidad (€)')),
              TextField(controller: waste, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Merma (%)')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final parsedQuantity = double.tryParse(quantity.text.replaceAll(',', '.'));
                final parsedCost = double.tryParse(cost.text.replaceAll(',', '.'));
                final parsedWaste = double.tryParse(waste.text.replaceAll(',', '.'));
                if (name.text.trim().isEmpty || parsedQuantity == null || parsedQuantity <= 0 || parsedCost == null || parsedCost < 0 || parsedWaste == null || parsedWaste < 0 || parsedWaste > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revisa los datos del ingrediente.')));
                  return;
                }
                Navigator.pop(dialogContext, {
                  'nom': name.text.trim(), 'quantitat': parsedQuantity,
                  'unitat': unit, 'costUnitari': parsedCost, 'merma': parsedWaste,
                });
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    quantity.dispose();
    cost.dispose();
    waste.dispose();
    return ingredient;
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar escandallo'),
        content: Text('Se eliminará «${item['nom']}» y sus ingredientes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _service.eliminarEscandall('${item['id']}');
      if (!mounted) return;
      _message('Escandallo eliminado.');
      await _load();
    } catch (error) {
      _message('No se pudo eliminar el escandallo: $error');
    }
  }

  void _message(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items.where((item) {
      final product = item['obrador_productes'];
      final productName = product is Map ? '${product['nom'] ?? ''}' : '';
      return '${item['nom'] ?? ''} ${item['linia'] ?? ''} $productName'.toLowerCase().contains(_query.toLowerCase());
    }).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
        child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Escandallos', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            SizedBox(height: 3),
            Text('Recetas, costes y margen bruto por producto.', style: TextStyle(fontSize: 12, color: Color(0xFF667085))),
          ])),
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
          FilledButton.icon(onPressed: _loading || _saving ? null : _create, icon: const Icon(Icons.add), label: Text(_saving ? 'Guardando…' : 'Nuevo')),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No se han podido cargar los escandallos.\n$_error\n\nEjecuta database/alter_obrador_escandalls_kpis.sql en Supabase.', textAlign: TextAlign.center),
                  ))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(padding: const EdgeInsets.fromLTRB(14, 6, 14, 24), children: [
                      TextField(
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Buscar escandallo', border: OutlineInputBorder()),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      const SizedBox(height: 14),
                      if (visible.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay escandallos todavía. Crea el primero para calcular costes y márgenes.'))),
                      ...visible.map((item) {
                        final ingredients = _ingredients(item);
                        final recipeCost = _recipeCost(item);
                        final unitCost = _unitCost(item);
                        final price = _number(item['pvp_unitari']);
                        final product = item['obrador_productes'];
                        final productName = product is Map ? product['nom'] : null;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ExpansionTile(
                            leading: const Icon(Icons.restaurant_menu),
                            title: Text('${item['nom'] ?? 'Escandallo'}'),
                            subtitle: Text('${item['linia'] ?? 'Sin línea'} · Coste/${item['unitat_rendiment'] ?? 'unidad'} ${unitCost.toStringAsFixed(2)} € · Margen ${_margin(item).toStringAsFixed(1)}%'),
                            trailing: IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Eliminar', onPressed: () => _delete(item)),
                            children: [
                              if (productName != null) ListTile(dense: true, leading: const Icon(Icons.link), title: Text('Vinculado a: $productName')),
                              ...ingredients.map((ingredient) => ListTile(
                                dense: true,
                                title: Text('${ingredient['nom'] ?? 'Ingrediente'}'),
                                subtitle: Text('${ingredient['quantitat']} ${ingredient['unitat']} × ${_number(ingredient['cost_unitari']).toStringAsFixed(2)} € · merma ${_number(ingredient['merma_percent']).toStringAsFixed(1)}%'),
                                trailing: Text('${_lineCost(ingredient).toStringAsFixed(2)} €'),
                              )),
                              const Divider(height: 1),
                              ListTile(title: Text('Coste receta (${_yield(item).toStringAsFixed(2)} ${item['unitat_rendiment']})'), trailing: Text('${recipeCost.toStringAsFixed(2)} €')),
                              ListTile(title: const Text('PVP por unidad de rendimiento'), trailing: Text('${price.toStringAsFixed(2)} €')),
                              ListTile(title: const Text('Margen bruto estimado'), trailing: Text('${(price - unitCost).toStringAsFixed(2)} € (${_margin(item).toStringAsFixed(1)}%)')),
                            ],
                          ),
                        );
                      }),
                    ]),
                  ),
      ),
    ]);
  }
}
