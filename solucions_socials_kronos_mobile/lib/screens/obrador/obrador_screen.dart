import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/obrador_service.dart';
import '../../utils/roles.dart';
import 'escandalls_screen.dart';
import 'obrador_exportacio_screen.dart';
import 'obrador_higiene_screen.dart';
import 'obrador_kpis_screen.dart';
import 'obrador_registres_torn_screen.dart';

class ObradorScreen extends StatefulWidget {
  const ObradorScreen({super.key});

  @override
  State<ObradorScreen> createState() => _ObradorScreenState();
}

class _ObradorScreenState extends State<ObradorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final List<int> _visibleTabIndices;
  final ObradorService _service = ObradorService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _recepcions = [];
  List<Map<String, dynamic>> _lots = [];
  List<Map<String, dynamic>> _expedicions = [];
  List<Map<String, dynamic>> _incidencies = [];
  List<Map<String, dynamic>> _productes = [];
  List<Map<String, dynamic>> _temperatures = [];
  List<Map<String, dynamic>> _proveidors = [];
  List<Map<String, dynamic>> _sensors = [];

  @override
  void initState() {
    super.initState();
    final role = RoleUtils.toCanonical(
      Supabase.instance.client.auth.currentUser?.userMetadata?['role']
          ?.toString(),
    );
    const restricted = <int>{2, 5, 9, 10};
    _visibleTabIndices = List<int>.generate(11, (index) => index)
        .where(
          (index) =>
              !restricted.contains(index) ||
              const {'admin', 'management', 'manager'}.contains(role),
        )
        .toList();
    _tabs = TabController(length: _visibleTabIndices.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.recepcions(),
        _service.lots(),
        _service.expedicions(),
        _service.incidencies(),
        _service.productes(),
        _service.temperatures(),
        _service.proveidors(),
        _service.sensors(),
      ]);
      if (!mounted) return;
      setState(() {
        _recepcions = results[0];
        _lots = results[1];
        _expedicions = results[2];
        _incidencies = results[3];
        _productes = results[4];
        _temperatures = results[5];
        _proveidors = results[6];
        _sensors = results[7];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('permission') || s.contains('42501')) {
      return 'No tienes permisos para consultar el Obrador. Revisa las políticas RLS de Supabase.';
    }
    if (s.contains('relation') ||
        s.contains('does not exist') ||
        s.contains('PGRST')) {
      return 'No se encuentran algunas tablas o relaciones del Obrador. Comprueba que las migraciones SQL estén aplicadas.';
    }
    return 'No se han podido cargar los datos del Obrador. Comprueba la conexión y los permisos.\n$s';
  }

  void _message(String message) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _newReception() async {
    if (_proveidors.isEmpty) {
      _message('No hay proveedores registrados en Supabase.');
      return;
    }
    if (_productes.isEmpty) {
      _message('Crea primero la ficha del producto que vas a recibir.');
      return;
    }
    final formKey = GlobalKey<FormState>();
    String? product = _productes.first['id'] as String?;
    final initialSuppliers = _suppliersForProduct(_productes.first);
    if (initialSuppliers.isEmpty) {
      _message(
        'Este producto tiene proveedores vinculados, pero no aparecen en la lista de proveedores.',
      );
      return;
    }
    String? supplier = initialSuppliers.first['id'] as String?;
    String status = 'bo';
    String category = 'fred';
    String unit = 'kg';
    DateTime? expiry;
    final lotCtrl = TextEditingController();
    final invoiceCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final tempCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nueva recepción',
                    style: Theme.of(ctx).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: supplier,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Proveedor'),
                    items:
                        _suppliersForProduct(
                              _productes.firstWhere(
                                (p) => p['id'].toString() == product,
                              ),
                            )
                            .map(
                              (p) => DropdownMenuItem<String>(
                                value: p['id'] as String,
                                child: Text('${p['nom'] ?? 'Sin nombre'}'),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setModal(() => supplier = v),
                  ),
                  if (supplier == null)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Vincula un proveedor compatible en la ficha del producto.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    value: product,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Producto'),
                    items: _productes
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p['id'] as String,
                            child: Text('${p['nom'] ?? 'Sin nombre'}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModal(() {
                      product = v;
                      final matched = _productes.firstWhere(
                        (p) => p['id'].toString() == v,
                      );
                      final providers = _suppliersForProduct(matched);
                      supplier = providers.isEmpty
                          ? null
                          : providers.first['id'] as String?;
                    }),
                  ),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de producto',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'fred',
                        child: Text('Refrigerado'),
                      ),
                      DropdownMenuItem(value: 'sec', child: Text('Seco')),
                      DropdownMenuItem(
                        value: 'congelat',
                        child: Text('Congelado'),
                      ),
                    ],
                    onChanged: (v) => setModal(() => category = v ?? category),
                  ),
                  TextFormField(
                    controller: invoiceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Número de albarán',
                    ),
                  ),
                  TextFormField(
                    controller: lotCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lote del proveedor',
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantityCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                          ),
                          validator: _optionalDouble,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: unit,
                          decoration: const InputDecoration(
                            labelText: 'Unidad',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(
                              value: 'unitat',
                              child: Text('Unidad'),
                            ),
                          ],
                          onChanged: (v) => setModal(() => unit = v ?? unit),
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: tempCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Temperatura de llegada (°C)',
                    ),
                    validator: (v) =>
                        (v != null &&
                            v.trim().isNotEmpty &&
                            double.tryParse(v.replaceAll(',', '.')) == null)
                        ? 'Introduce una temperatura válida'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Estado de recepción',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'bo', child: Text('Correcto')),
                      DropdownMenuItem(
                        value: 'rebutjat',
                        child: Text('Rechazado'),
                      ),
                    ],
                    onChanged: (v) => setModal(() => status = v ?? 'bo'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          expiry == null
                              ? 'Sin fecha de caducidad'
                              : 'Caducidad: ${expiry!.day}/${expiry!.month}/${expiry!.year}',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: expiry ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) setModal(() => expiry = picked);
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Fecha'),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: status == 'rebutjat'
                          ? 'Motivo del rechazo (obligatorio)'
                          : 'Observaciones',
                    ),
                    validator: (v) =>
                        status == 'rebutjat' && (v == null || v.trim().isEmpty)
                        ? 'Indica el motivo del rechazo'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                          onPressed: () {
                            if (formKey.currentState!.validate() &&
                                supplier != null)
                              Navigator.pop(ctx, true);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (ok == true && supplier != null && product != null) {
      try {
        final temp = tempCtrl.text.trim().isEmpty
            ? null
            : double.parse(tempCtrl.text.replaceAll(',', '.'));
        final quantity = quantityCtrl.text.trim().isEmpty
            ? null
            : _doubleOrNull(quantityCtrl.text);
        final receiptId = await _service.crearRecepcio(
          idProveidor: supplier!,
          idProducte: product!,
          lotProveidor: lotCtrl.text,
          numeroAlbara: invoiceCtrl.text,
          quantitat: quantity,
          unitat: unit,
          tipus: category,
          temperatura: temp,
          estat: status,
          caducitat: expiry,
          congelat: category == 'congelat',
          observacions: notesCtrl.text,
        );
        if (status == 'rebutjat') {
          try {
            await _service.crearIncidenciaRecepcio(
              idRecepcio: receiptId,
              tipus: temp == null ? 'qualitat' : 'temperatura',
              descripcio: notesCtrl.text,
            );
          } catch (e) {
            _message(
              'Recepción guardada; no se pudo crear la incidencia asociada: $e',
            );
          }
        }
        _message('Recepción guardada correctamente');
        await _load();
      } catch (e) {
        _message('No se pudo guardar la recepción: $e');
      }
    }
    lotCtrl.dispose();
    invoiceCtrl.dispose();
    quantityCtrl.dispose();
    tempCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _closeIncident(Map<String, dynamic> item) async {
    final notes = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar incidencia'),
        content: TextField(
          controller: notes,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Acción correctiva',
            hintText: 'Describe qué se ha hecho para resolverla',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar incidencia'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      notes.dispose();
      return;
    }
    if (notes.text.trim().length < 10) {
      _message('La acción correctiva debe tener al menos 10 caracteres.');
      notes.dispose();
      return;
    }
    try {
      await _service.tancarIncidencia(item['id'].toString(), notes: notes.text);
      _message('Incidencia cerrada');
      await _load();
    } catch (e) {
      _message('No se pudo cerrar la incidencia: $e');
    }
    notes.dispose();
  }

  Future<void> _markIncidentInProgress(Map<String, dynamic> item) async {
    try {
      await _service.marcarIncidenciaEnCurs(item['id'].toString());
      _message('Incidencia marcada en revisión.');
      await _load();
    } catch (e) {
      _message('No se pudo actualizar la incidencia: $e');
    }
  }

  Future<void> _verifyIncident(Map<String, dynamic> item) async {
    try {
      await _service.verificarIncidencia(item['id'].toString());
      _message('Acción correctiva verificada.');
      await _load();
    } catch (e) {
      _message('No se pudo verificar la incidencia: $e');
    }
  }

  Future<void> _newProduct({Map<String, dynamic>? existing}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: '${existing?['nom'] ?? ''}');
    final expiry = TextEditingController(
      text: '${existing?['caducitat_dies'] ?? ''}',
    );
    final cooking = TextEditingController(
      text: '${existing?['temp_coccio'] ?? ''}',
    );
    final storage = TextEditingController(
      text: '${existing?['temp_conservacio'] ?? ''}',
    );
    final allergens = TextEditingController(
      text: _allergensInput(existing?['allergens']),
    );
    final technical = TextEditingController(
      text: '${existing?['fitxa_tecnica'] ?? ''}',
    );
    final supplierIngredients = <String, TextEditingController>{};
    final selectedSuppliers = <String>{};
    final currentLinks = existing?['obrador_producte_proveidors'];
    if (currentLinks is List) {
      for (final link in currentLinks) {
        if (link is Map && link['id_proveidor'] != null) {
          final supplierId = link['id_proveidor'].toString();
          selectedSuppliers.add(supplierId);
          supplierIngredients[supplierId] = TextEditingController(
            text: '${link['ingredient_nom'] ?? ''}',
          );
        }
      }
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Nuevo producto' : 'Editar producto'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Indica un nombre'
                          : null,
                    ),
                    TextFormField(
                      controller: expiry,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Caducidad (días)',
                      ),
                      validator: _requiredInteger,
                    ),
                    TextFormField(
                      controller: cooking,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Temperatura de cocción (°C)',
                      ),
                      validator: _optionalDouble,
                    ),
                    TextFormField(
                      controller: storage,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Temperatura de conservación (°C)',
                      ),
                      validator: _optionalDouble,
                    ),
                    TextFormField(
                      controller: allergens,
                      decoration: const InputDecoration(
                        labelText: 'Alérgenos (separados por coma)',
                      ),
                    ),
                    TextFormField(
                      controller: technical,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Ficha técnica',
                      ),
                    ),
                    if (_proveidors.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Proveedores e ingredientes',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      ..._proveidors.expand((supplier) {
                        final id = supplier['id'].toString();
                        final selected = selectedSuppliers.contains(id);
                        return <Widget>[
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: selected,
                            title: Text('${supplier['nom'] ?? 'Proveedor'}'),
                            onChanged: (value) => setDialog(() {
                              if (value == true) {
                                selectedSuppliers.add(id);
                                supplierIngredients.putIfAbsent(
                                  id,
                                  TextEditingController.new,
                                );
                              } else {
                                selectedSuppliers.remove(id);
                                supplierIngredients.remove(id)?.dispose();
                              }
                            }),
                          ),
                          if (selected)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 36,
                                bottom: 6,
                              ),
                              child: TextField(
                                controller: supplierIngredients[id],
                                decoration: const InputDecoration(
                                  labelText: 'Ingrediente asociado (opcional)',
                                ),
                              ),
                            ),
                        ];
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      try {
        final args = <String, dynamic>{
          'nom': name.text.trim(),
          'caducitatDies': _intOrNull(expiry.text),
          'tempCoccio': _doubleOrNull(cooking.text),
          'tempConservacio': _doubleOrNull(storage.text),
          'allergens': allergens.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          'fitxaTecnica': technical.text,
        };
        late final String productId;
        if (existing == null) {
          productId = await _service.crearProducte(
            nom: args['nom'] as String,
            caducitatDies: args['caducitatDies'] as int?,
            tempCoccio: args['tempCoccio'] as double?,
            tempConservacio: args['tempConservacio'] as double?,
            allergens: args['allergens'] as List<String>,
            fitxaTecnica: args['fitxaTecnica'] as String,
          );
        } else {
          productId = existing['id'].toString();
          await _service.actualitzarProducte(
            id: existing['id'].toString(),
            nom: args['nom'] as String,
            caducitatDies: args['caducitatDies'] as int?,
            tempCoccio: args['tempCoccio'] as double?,
            tempConservacio: args['tempConservacio'] as double?,
            allergens: args['allergens'] as List<String>,
            fitxaTecnica: args['fitxaTecnica'] as String,
          );
        }
        if (selectedSuppliers.isNotEmpty ||
            currentLinks is List && currentLinks.isNotEmpty) {
          await _service.setProducteProveidors(productId, {
            for (final id in selectedSuppliers)
              id: supplierIngredients[id]?.text ?? '',
          });
        }
        _message(
          existing == null ? 'Producto creado.' : 'Producto actualizado.',
        );
        await _load();
      } catch (e) {
        _message('No se pudo guardar el producto: $e');
      }
    }
    name.dispose();
    expiry.dispose();
    cooking.dispose();
    storage.dispose();
    allergens.dispose();
    technical.dispose();
    for (final controller in supplierIngredients.values) {
      controller.dispose();
    }
  }

  Future<void> _archiveProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archivar producto'),
        content: Text(
          '¿Quieres archivar “${product['nom']}”? Dejará de aparecer en producción.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.arxivarProducte(product['id'].toString());
      _message('Producto archivado.');
      await _load();
    } catch (e) {
      _message('No se pudo archivar: $e');
    }
  }

  Future<void> _newLot() async {
    final products = _productes
        .where((item) => item['actiu'] != false)
        .toList();
    final receipts = _recepcions
        .where((item) => item['estat'] == 'bo')
        .toList();
    if (products.isEmpty || receipts.isEmpty) {
      _message(
        'Para crear un lote necesitas un producto activo y una recepción correcta.',
      );
      return;
    }
    String productId = products.first['id'].toString();
    var compatibleReceipts = _recepcionsForProduct(products.first, receipts);
    if (compatibleReceipts.isEmpty) {
      _message(
        'No hay recepciones correctas de un proveedor vinculado a este producto.',
      );
      return;
    }
    final selectedReceipts = <String>{
      compatibleReceipts.first['id'].toString(),
    };
    bool sample = false;
    final amount = TextEditingController();
    final temperature = TextEditingController();
    final notes = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            14,
            18,
            MediaQuery.of(ctx).viewInsets.bottom + 18,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nuevo lote de producción',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: productId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Producto'),
                    items: products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p['id'].toString(),
                            child: Text('${p['nom']}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModal(() {
                      if (v == null) return;
                      productId = v;
                      final product = products.firstWhere(
                        (p) => p['id'].toString() == v,
                      );
                      compatibleReceipts = _recepcionsForProduct(
                        product,
                        receipts,
                      );
                      selectedReceipts.clear();
                      if (compatibleReceipts.isNotEmpty) {
                        selectedReceipts.add(
                          compatibleReceipts.first['id'].toString(),
                        );
                      }
                    }),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Recepciones de origen',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  ...compatibleReceipts.map((receipt) {
                    final id = receipt['id'].toString();
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selectedReceipts.contains(id),
                      title: Text(
                        '${_nestedName(receipt, 'obrador_proveidors', 'nom', 'Proveedor')} · ${receipt['lot_proveidor'] ?? 'sin lote'}',
                      ),
                      subtitle: Text(
                        '${receipt['quantitat'] ?? '—'} ${receipt['unitat'] ?? ''} · ${_date(receipt['data_recepcio'])}',
                      ),
                      onChanged: (checked) => setModal(() {
                        if (checked == true) {
                          selectedReceipts.add(id);
                        } else {
                          selectedReceipts.remove(id);
                        }
                      }),
                    );
                  }),
                  TextFormField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad (kg)',
                    ),
                    validator: (v) =>
                        _requiredPositive(v, 'Introduce una cantidad válida'),
                  ),
                  TextFormField(
                    controller: temperature,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Temperatura final de cocción (°C)',
                    ),
                    validator: _optionalDouble,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: sample,
                    title: const Text('Muestra de conservación guardada'),
                    onChanged: (v) => setModal(() => sample = v),
                  ),
                  TextFormField(
                    controller: notes,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            if (selectedReceipts.isEmpty) {
                              _message(
                                'Selecciona al menos una recepción compatible.',
                              );
                              return;
                            }
                            if (formKey.currentState!.validate())
                              Navigator.pop(ctx, true);
                          },
                          icon: const Icon(Icons.qr_code_2),
                          label: const Text('Crear lote y etiqueta'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (confirmed == true) {
      final product = products.firstWhere(
        (p) => p['id'].toString() == productId,
      );
      try {
        final result = await _service.crearLot(
          idProducte: productId,
          idsRecepcions: selectedReceipts.toList(),
          quantitatKg: _doubleOrNull(amount.text)!,
          temperaturaFinal: _doubleOrNull(temperature.text),
          mostraGuardada: sample,
          caducitatDies: int.tryParse('${product['caducitat_dies'] ?? 3}') ?? 3,
          allergens: product['allergens'] is List
              ? List<String>.from(product['allergens'])
              : const [],
          observacions: notes.text,
        );
        _message(
          'Lote creado${result['lot'] is Map && result['lot']['codi_lot'] != null ? ': ${result['lot']['codi_lot']}' : ''}.',
        );
        await _load();
      } catch (e) {
        _message('No se pudo crear el lote: $e');
      }
    }
    amount.dispose();
    temperature.dispose();
    notes.dispose();
  }

  Future<void> _packageLot(Map<String, dynamic> lot) async {
    final productId = lot['id_producte']?.toString();
    final matchingProducts = _productes.where(
      (item) => item['id'].toString() == productId,
    );
    final product = matchingProducts.isEmpty ? null : matchingProducts.first;
    if (product == null) {
      _message(
        'No se encontró la ficha del producto para preparar la etiqueta.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Envasar lote'),
        content: Text(
          'Se creará una etiqueta y el lote ${lot['codi_lot'] ?? ''} pasará a estar disponible para expedición.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Envasar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.crearEtiqueta(
        lot['id'].toString(),
        caducitatDies: int.tryParse('${product['caducitat_dies'] ?? 3}') ?? 3,
        allergens: product['allergens'] is List
            ? List<String>.from(product['allergens'])
            : const [],
      );
      _message('Etiqueta creada; lote envasado.');
      await _load();
    } catch (e) {
      _message('No se pudo envasar el lote: $e');
    }
  }

  Future<void> _showLotLabel(Map<String, dynamic> lot) async {
    final raw = lot['obrador_etiquetes'];
    final Map<String, dynamic>? label = raw is Map
        ? Map<String, dynamic>.from(raw)
        : raw is List && raw.isNotEmpty && raw.first is Map
        ? Map<String, dynamic>.from(raw.first as Map)
        : null;
    final qr = label?['codi_qr']?.toString();
    if (qr == null || qr.isEmpty) {
      _message('Este lote todavía no tiene etiqueta QR. Envásalo primero.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Etiqueta · ${lot['codi_lot'] ?? 'Lote'}'),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(data: qr, version: QrVersions.auto, size: 210),
              const SizedBox(height: 8),
              SelectableText(qr, textAlign: TextAlign.center),
              if (label?['data_caducitat'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Caducidad: ${label?['data_caducitat']}'),
                ),
              const SizedBox(height: 6),
              Text(
                'Alérgenos: ${_allergens(label?['allergens'])}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _newExpedition() async {
    final available = _lots.where((lot) => lot['estat'] == 'envasat').toList();
    if (available.isEmpty) {
      _message('No hay lotes envasados disponibles para expedir.');
      return;
    }
    String lotId = available.first['id'].toString();
    bool checkExit = false;
    bool checkClient = false;
    final client = TextEditingController();
    final order = TextEditingController();
    final notes = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            14,
            18,
            MediaQuery.of(ctx).viewInsets.bottom + 18,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nueva expedición',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: lotId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Lote envasado',
                    ),
                    items: available
                        .map(
                          (l) => DropdownMenuItem(
                            value: l['id'].toString(),
                            child: Text(
                              '${l['codi_lot'] ?? 'Lote'} · ${_nestedName(l, 'obrador_productes', 'nom', 'Producto')}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModal(() => lotId = v ?? lotId),
                  ),
                  TextFormField(
                    controller: client,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Indica el cliente'
                        : null,
                  ),
                  TextFormField(
                    controller: order,
                    decoration: const InputDecoration(
                      labelText: 'Número de pedido (opcional)',
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: checkExit,
                    title: const Text('Comprobación de salida realizada'),
                    onChanged: (v) => setModal(() => checkExit = v ?? false),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: checkClient,
                    title: const Text('Pedido y cliente comprobados'),
                    onChanged: (v) => setModal(() => checkClient = v ?? false),
                  ),
                  TextFormField(
                    controller: notes,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            if (!checkExit || !checkClient) {
                              _message(
                                'Completa las dos comprobaciones antes de expedir.',
                              );
                              return;
                            }
                            if (formKey.currentState!.validate())
                              Navigator.pop(ctx, true);
                          },
                          icon: const Icon(Icons.local_shipping_outlined),
                          label: const Text('Registrar salida'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (confirmed == true) {
      try {
        await _service.crearExpedicio(
          idLot: lotId,
          nomClient: client.text,
          comanda: order.text,
          checkSortida: checkExit,
          checkClient: checkClient,
          observacions: notes.text,
        );
        _message('Expedición registrada.');
        await _load();
      } catch (e) {
        _message('No se pudo registrar la expedición: $e');
      }
    }
    client.dispose();
    order.dispose();
    notes.dispose();
  }

  Future<void> _newIncident() async {
    final sensors = _sensors
        .where((sensor) => sensor['actiu'] != false)
        .toList();
    if (_lots.isEmpty && sensors.isEmpty) {
      _message('No hay lotes ni sensores para relacionar con la incidencia.');
      return;
    }
    String origin = _lots.isEmpty ? 'sensor' : 'lot';
    String lotId = _lots.isEmpty ? '' : _lots.first['id'].toString();
    String sensorId = sensors.isEmpty ? '' : sensors.first['id'].toString();
    String type = 'temperatura';
    final description = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('Nueva incidencia'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_lots.isNotEmpty && sensors.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: origin,
                      decoration: const InputDecoration(labelText: 'Origen'),
                      items: const [
                        DropdownMenuItem(value: 'lot', child: Text('Lote')),
                        DropdownMenuItem(
                          value: 'sensor',
                          child: Text('Sensor IoT'),
                        ),
                      ],
                      onChanged: (v) => setModal(() => origin = v ?? origin),
                    ),
                  if (origin == 'lot')
                    DropdownButtonFormField<String>(
                      value: lotId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Lote relacionado',
                      ),
                      items: _lots
                          .map(
                            (lot) => DropdownMenuItem(
                              value: lot['id'].toString(),
                              child: Text('${lot['codi_lot'] ?? 'Lote'}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModal(() => lotId = v ?? lotId),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: sensorId.isEmpty ? null : sensorId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sensor relacionado',
                      ),
                      items: sensors
                          .map(
                            (sensor) => DropdownMenuItem(
                              value: sensor['id'].toString(),
                              child: Text(
                                '${sensor['nom'] ?? sensor['ubicacio'] ?? 'Sensor'}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setModal(() => sensorId = v ?? sensorId),
                    ),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                        value: 'temperatura',
                        child: Text('Temperatura'),
                      ),
                      DropdownMenuItem(
                        value: 'qualitat',
                        child: Text('Calidad'),
                      ),
                      DropdownMenuItem(
                        value: 'contaminacio',
                        child: Text('Contaminación'),
                      ),
                      DropdownMenuItem(
                        value: 'etiquetatge',
                        child: Text('Etiquetado'),
                      ),
                      DropdownMenuItem(value: 'altres', child: Text('Otros')),
                    ],
                    onChanged: (v) => setModal(() => type = v ?? type),
                  ),
                  TextFormField(
                    controller: description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Describe la incidencia'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      try {
        await _service.crearIncidencia(
          idLot: origin == 'lot' ? lotId : null,
          idSensor: origin == 'sensor' ? sensorId : null,
          origen: origin,
          tipus: type,
          descripcio: description.text,
        );
        _message('Incidencia creada.');
        await _load();
      } catch (e) {
        _message('No se pudo crear la incidencia: $e');
      }
    }
    description.dispose();
  }

  Future<void> _markDelivered(Map<String, dynamic> shipment) async {
    var clientConfirmed = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('Confirmar entrega'),
          content: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: clientConfirmed,
            title: const Text('Cliente y pedido verificados en destino'),
            onChanged: (value) =>
                setModal(() => clientConfirmed = value ?? false),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: clientConfirmed
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.marcarExpedicioEntregada(
        shipment['id'].toString(),
        checkClient: clientConfirmed,
      );
      _message('Entrega confirmada.');
      await _load();
    } catch (e) {
      _message('No se pudo confirmar la entrega: $e');
    }
  }

  Future<void> _cancelShipment(Map<String, dynamic> shipment) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular expedición'),
        content: TextField(
          controller: reason,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Motivo de anulación'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (reason.text.trim().isEmpty) {
        _message('Indica el motivo de anulación.');
      } else {
        try {
          await _service.anularExpedicio(
            shipment['id'].toString(),
            reason.text,
          );
          _message('Expedición anulada.');
          await _load();
        } catch (e) {
          _message('No se pudo anular la expedición: $e');
        }
      }
    }
    reason.dispose();
  }

  String? _optionalInteger(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return int.tryParse(value.trim()) == null
        ? 'Introduce un número entero'
        : null;
  }

  String? _requiredInteger(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    return parsed == null || parsed <= 0
        ? 'Introduce un número de días válido'
        : null;
  }

  String? _optionalDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.').trim()) == null
        ? 'Introduce un número válido'
        : null;
  }

  String? _requiredPositive(String? value, String message) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.').trim());
    return parsed == null || parsed <= 0 ? message : null;
  }

  int? _intOrNull(String value) => int.tryParse(value.trim());
  double? _doubleOrNull(String value) =>
      double.tryParse(value.replaceAll(',', '.').trim());

  String _allergensInput(dynamic value) =>
      value is List ? value.join(', ') : '';

  List<Map<String, dynamic>> _suppliersForProduct(
    Map<String, dynamic> product,
  ) {
    final links = product['obrador_producte_proveidors'];
    if (links is! List || links.isEmpty) return _proveidors;
    final ids = links
        .whereType<Map>()
        .map((link) => '${link['id_proveidor']}')
        .toSet();
    return _proveidors
        .where((supplier) => ids.contains('${supplier['id']}'))
        .toList();
  }

  List<Map<String, dynamic>> _recepcionsForProduct(
    Map<String, dynamic> product,
    List<Map<String, dynamic>> receipts,
  ) {
    final links = product['obrador_producte_proveidors'];
    if (links is! List || links.isEmpty) return receipts;
    final ids = links
        .whereType<Map>()
        .map((link) => '${link['id_proveidor']}')
        .toSet();
    return receipts
        .where((receipt) => ids.contains('${receipt['id_proveidor']}'))
        .toList();
  }

  void _createForTab() {
    switch (_activeTab) {
      case 1:
        _newReception();
        break;
      case 2:
        _newProduct();
        break;
      case 3:
        _newLot();
        break;
      case 4:
        _newExpedition();
        break;
      case 5:
        _newIncident();
        break;
    }
  }

  String? _actionLabel() => switch (_activeTab) {
    1 => 'Nueva recepción',
    2 => 'Nuevo producto',
    3 => 'Nuevo lote',
    4 => 'Nueva expedición',
    5 => 'Nueva incidencia',
    _ => null,
  };

  int get _activeTab => _visibleTabIndices[_tabs.index];

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF36A852);
    const ink = Color(0xFF20252B);
    const allTabs = <Tab>[
      Tab(text: 'Dashboard'),
      Tab(text: 'Recepciones'),
      Tab(text: 'Productos'),
      Tab(text: 'Lotes'),
      Tab(text: 'Expediciones'),
      Tab(text: 'Incidencias'),
      Tab(text: 'Registros de turno'),
      Tab(text: 'Planes de higiene'),
      Tab(text: 'Exportación'),
      Tab(text: 'Escandallos'),
      Tab(text: 'KPIs mensuales'),
    ];
    final allPages = <Widget>[
      _dashboard(primary),
      _recepcionsList(),
      _productesList(),
      _lotsList(),
      _expedicionsList(),
      _incidenciesList(),
      const ObradorRegistresTornScreen(),
      const ObradorHigieneScreen(),
      const ObradorExportacioScreen(),
      const EscandallsScreen(),
      const ObradorKpisScreen(),
    ];
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: ink,
          elevation: 0,
          surfaceTintColor: Colors.white,
          toolbarHeight: 56,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: const BorderSide(color: Color(0xFFE7E9ED)),
          ),
        ),
        dividerColor: const Color(0xFFE8EAED),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Color(0xFFE1E4E8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Color(0xFFE1E4E8)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 22,
          title: const Text(
            'Obrador',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 19),
            ),
            const SizedBox(width: 12),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(43),
            child: Container(
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF0F1F3)),
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: primary,
                unselectedLabelColor: const Color(0xFF667085),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                indicatorColor: primary,
                indicatorWeight: 2,
                dividerColor: Colors.transparent,
                tabs: _visibleTabIndices
                    .map((index) => allTabs[index])
                    .toList(),
              ),
            ),
          ),
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _tabs,
          builder: (_, __) => _actionLabel() != null
              ? FloatingActionButton.extended(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  onPressed: _createForTab,
                  icon: const Icon(Icons.add),
                  label: Text(_actionLabel()!),
                )
              : const SizedBox.shrink(),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: primary))
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        size: 42,
                        color: Color(0xFF98A2B3),
                      ),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            : TabBarView(
                controller: _tabs,
                children: _visibleTabIndices
                    .map((index) => allPages[index])
                    .toList(),
              ),
      ),
    );
  }

  Widget _placeholderPage(String title, String description) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF20252B),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        description,
        style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E9ED)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF98A2B3)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aquesta secció encara no està connectada a les dades del projecte.',
                style: TextStyle(color: Color(0xFF667085)),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _dashboard(Color primary) {
    final today = DateTime.now();
    bool isToday(dynamic value) {
      final parsed = DateTime.tryParse('${value ?? ''}')?.toLocal();
      return parsed != null &&
          parsed.year == today.year &&
          parsed.month == today.month &&
          parsed.day == today.day;
    }

    final activeLots = _lots
        .where(
          (lot) =>
              isToday(lot['data_produccio']) &&
              ['produit', 'envasat'].contains(lot['estat']),
        )
        .length;
    final open = _incidencies
        .where((item) => ['oberta', 'en_curs'].contains(item['estat']))
        .length;
    // Una alarma es el estado actual de una cámara, no cada lectura histórica
    // fuera de rango. Conservar solo la lectura más reciente por ubicación hace
    // que el resumen muestre 1 en lugar de acumular, por ejemplo, 11 lecturas.
    final latestTemperatures = _latestTemperaturesByLocation(_temperatures);
    final temperatureAlerts = latestTemperatures
        .where(_temperatureAlert)
        .length;
    final todayShipments = _expedicions
        .where(
          (item) => isToday(item['data_sortida']) && item['estat'] != 'anulada',
        )
        .length;
    final dateText =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';
    final wide = MediaQuery.of(context).size.width >= 1000;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 14, vertical: 22),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resum del dia',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF20252B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Estat general de l’activitat del obrador',
                      style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
              Text(
                dateText,
                style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: wide ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: wide ? 2.05 : 1.55,
            children: [
              _stat(
                'Lotes producidos hoy',
                activeLots,
                Icons.inventory_2_outlined,
                primary,
              ),
              _stat(
                'Alertas de temperatura',
                temperatureAlerts,
                Icons.thermostat_outlined,
                const Color(0xFFE99A37),
              ),
              _stat(
                'Incidencias abiertas',
                open,
                Icons.warning_amber_outlined,
                const Color(0xFFE99A37),
              ),
              _stat(
                'Expediciones del día',
                todayShipments,
                Icons.local_shipping_outlined,
                primary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _incidentsPanel(open)),
                const SizedBox(width: 14),
                Expanded(flex: 4, child: _temperaturesPanel()),
              ],
            )
          else ...[
            _incidentsPanel(open),
            const SizedBox(height: 14),
            _temperaturesPanel(),
          ],
          const SizedBox(height: 14),
          _weeklyProductionPanel(),
          const SizedBox(height: 14),
          _recentDeliveriesPanel(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required Widget child,
    Widget? action,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE7E9ED)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF20252B),
                ),
              ),
            ),
            if (action != null) action,
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _incidentsPanel(int open) => _panel(
    title: 'Incidències actives',
    action: _smallPill(
      '$open obertes',
      open > 0 ? const Color(0xFFFFF0E5) : const Color(0xFFE8F6EC),
      open > 0 ? const Color(0xFFB75A16) : const Color(0xFF268443),
    ),
    child:
        _incidencies
            .where((i) => ['oberta', 'en_curs'].contains(i['estat']))
            .isEmpty
        ? const Text(
            'No hi ha incidències obertes.',
            style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
          )
        : Column(
            children: _incidencies
                .where((i) => ['oberta', 'en_curs'].contains(i['estat']))
                .take(4)
                .map(
                  (i) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE8EAED)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 19,
                          color: Color(0xFFE99A37),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i['tipus'] ?? 'Incidència'} · ${_incidentReference(i)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF20252B),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${i['descripcio'] ?? 'Sense descripció'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF667085),
                                ),
                              ),
                              const SizedBox(height: 5),
                              _smallPill(
                                'En revisió · Obrir',
                                const Color(0xFFE8F6EC),
                                const Color(0xFF268443),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _smallPill(
                          'Lot',
                          const Color(0xFFFFF0E5),
                          const Color(0xFFB75A16),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
  );

  Widget _temperaturesPanel() => _panel(
    title: 'Temperatures en temps real',
    child: _temperatures.isEmpty
        ? const Text(
            'Sense lectures de temperatura disponibles.',
            style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
          )
        : Column(
            children: _latestTemperaturesByLocation(_temperatures)
                .take(4)
                .map((t) {
              final alert = _temperatureAlert(t);
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE8EAED))),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.device_thermostat_outlined,
                      size: 20,
                      color: alert
                          ? const Color(0xFFE99A37)
                          : const Color(0xFF667085),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t['ubicacio'] ?? t['nom'] ?? 'Sensor'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF20252B),
                            ),
                          ),
                          Text(
                            _date(t['mesura_at']),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF98A2B3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      t['valor'] == null ? '—' : '${t['valor']} °C',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: alert
                            ? const Color(0xFFB75A16)
                            : const Color(0xFF20252B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
  );

  Widget _recentDeliveriesPanel() => _panel(
    title: 'Últimes expedicions',
    child: _expedicions.isEmpty
        ? const Text(
            'Encara no hi ha expedicions registrades.',
            style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
          )
        : Column(
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'EXPEDICIÓ',
                      style: TextStyle(fontSize: 9, color: Color(0xFF667085)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'LOT',
                      style: TextStyle(fontSize: 9, color: Color(0xFF667085)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'CLIENT',
                      style: TextStyle(fontSize: 9, color: Color(0xFF667085)),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'ESTAT',
                      style: TextStyle(fontSize: 9, color: Color(0xFF667085)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              ..._expedicions
                  .take(5)
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#${(e['id'] ?? '').toString().toString().split('-').first}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF344054),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _nestedName(e, 'obrador_lots', 'codi_lot', '—'),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF344054),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${e['id_client'] ?? '—'}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF344054),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _smallPill(
                                '${e['estat'] ?? 'Pendent'}',
                                const Color(0xFFE8F6EC),
                                const Color(0xFF268443),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
  );

  Widget _weeklyProductionPanel() {
    final today = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day - 6 + index),
    );
    final counts = days
        .map(
          (day) => _lots.where((lot) {
            final parsed = DateTime.tryParse(
              '${lot['data_produccio'] ?? ''}',
            )?.toLocal();
            return parsed != null &&
                parsed.year == day.year &&
                parsed.month == day.month &&
                parsed.day == day.day;
          }).length,
        )
        .toList();
    final maxCount = counts.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    final weekDays = const ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return _panel(
      title: 'Producción semanal',
      child: SizedBox(
        height: 104,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(days.length, (index) {
            final value = counts[index];
            final height = maxCount == 0 ? 4.0 : 54.0 * value / maxCount;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: const Color(0xFF36A852),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      weekDays[days[index].weekday - 1],
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _smallPill(String text, Color background, Color foreground) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _stat(String label, int value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E9ED)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: .35,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
                ),
                Icon(icon, size: 17, color: color),
              ],
            ),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: Color(0xFF20252B),
              ),
            ),
            Text(
              value == 0 ? 'Sense registres avui' : 'Dades actualitzades',
              style: TextStyle(fontSize: 9, color: color),
            ),
          ],
        ),
      );

  bool _temperatureAlert(Map<String, dynamic> temperature) {
    final value = double.tryParse('${temperature['valor'] ?? ''}');
    if (value == null) return false;
    switch ('${temperature['tipus'] ?? 'refrigeracio'}') {
      case 'congelacio':
        return value < -22 || value > -18;
      case 'conservacio':
        return value < 2 || value > 8;
      case 'zonaProduccio':
        return value < 18 || value > 25;
      default:
        return value < 0 || value > 4;
    }
  }

  List<Map<String, dynamic>> _latestTemperaturesByLocation(
    List<Map<String, dynamic>> readings,
  ) {
    final latest = <String, Map<String, dynamic>>{};
    for (final reading in readings) {
      final location = '${reading['ubicacio'] ?? reading['nom'] ?? ''}'.trim();
      final key = location.isEmpty ? '${reading['id']}' : location;
      final previous = latest[key];
      final measuredAt = DateTime.tryParse('${reading['mesura_at'] ?? ''}');
      final previousAt = DateTime.tryParse('${previous?['mesura_at'] ?? ''}');
      if (previous == null ||
          (measuredAt != null &&
              (previousAt == null || measuredAt.isAfter(previousAt)))) {
        latest[key] = reading;
      }
    }
    final result = latest.values.toList();
    result.sort((a, b) {
      final aDate = DateTime.tryParse('${a['mesura_at'] ?? ''}');
      final bDate = DateTime.tryParse('${b['mesura_at'] ?? ''}');
      return (bDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        aDate ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
    return result;
  }

  Widget _recepcionsList() => _listPage(
    _recepcions
        .map(
          (r) => _dataCard(
            title: _nestedName(r, 'obrador_proveidors', 'nom', 'Proveedor'),
            subtitle:
                '${_nestedName(r, 'obrador_productes', 'nom', 'Producto')} · ${r['quantitat'] ?? '—'} ${r['unitat'] ?? ''} · ${_date(r['data_recepcio'])}',
            trailing: r['temperatura_arribada'] == null
                ? null
                : '${r['temperatura_arribada']} °C',
            icon: Icons.move_to_inbox,
            detail:
                'Estado: ${r['estat'] ?? '—'}\nTipo: ${r['tipus'] ?? '—'}\nLote del proveedor: ${r['lot_proveidor'] ?? '—'}\nAlbarán: ${r['num_albara'] ?? '—'}\nCaducidad: ${r['caducitat'] ?? '—'}${r['observacions'] == null ? '' : '\n${r['observacions']}'}',
          ),
        )
        .toList(),
  );

  Widget _productesList() => _listPage(
    _productes
        .map(
          (p) => _dataCard(
            title: '${p['nom'] ?? 'Producto'}',
            subtitle:
                'Caducidad: ${p['caducitat_dies'] ?? '—'} días · Cocción: ${p['temp_coccio'] ?? '—'} °C',
            trailing: p['temp_conservacio'] == null
                ? null
                : '${p['temp_conservacio']} °C',
            icon: Icons.restaurant,
            detail: 'Alérgenos: ${_allergens(p['allergens'])}',
            trailingWidget: PopupMenuButton<String>(
              tooltip: 'Acciones del producto',
              onSelected: (action) {
                if (action == 'edit') _newProduct(existing: p);
                if (action == 'archive') _archiveProduct(p);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'archive', child: Text('Archivar')),
              ],
            ),
          ),
        )
        .toList(),
  );

  Widget _lotsList() => _listPage(
    _lots
        .map(
          (l) => _dataCard(
            title: '${l['codi_lot'] ?? 'Lote sin código'}',
            subtitle:
                '${_nestedName(l, 'obrador_productes', 'nom', 'Producto')} · ${_date(l['data_produccio'])}',
            trailing: '${l['estat'] ?? '—'}',
            icon: Icons.qr_code_2,
            detail:
                'Cantidad: ${l['quantitat_kg'] ?? '—'} kg · Temperatura final: ${l['temp_final_coccio'] ?? '—'} °C',
            trailingWidget: ['produit', 'envasat'].contains(l['estat'])
                ? PopupMenuButton<String>(
                    tooltip: 'Acciones de lote',
                    onSelected: (action) {
                      if (action == 'package') _packageLot(l);
                      if (action == 'label') _showLotLabel(l);
                    },
                    itemBuilder: (_) => [
                      if (l['estat'] == 'produit')
                        const PopupMenuItem(
                          value: 'package',
                          child: Text('Envasar y crear etiqueta'),
                        ),
                      if (l['estat'] == 'envasat')
                        const PopupMenuItem(
                          value: 'label',
                          child: Text('Ver etiqueta QR'),
                        ),
                    ],
                  )
                : null,
          ),
        )
        .toList(),
  );

  Widget _expedicionsList() => _listPage(
    _expedicions
        .map(
          (e) => _dataCard(
            title:
                'Lote ${_nestedName(e, 'obrador_lots', 'codi_lot', 'sin código')}',
            subtitle:
                '${e['id_client'] ?? 'Cliente sin nombre'} · ${_date(e['data_sortida'])}',
            trailing: '${e['estat'] ?? '—'}',
            icon: Icons.local_shipping,
            detail: 'Pedido: ${e['comanda_holded'] ?? '—'}',
            trailingWidget:
                e['estat'] == 'en trànsit' || e['estat'] == 'en_transit'
                ? PopupMenuButton<String>(
                    tooltip: 'Acciones de expedición',
                    onSelected: (action) {
                      if (action == 'delivered') _markDelivered(e);
                      if (action == 'cancel') _cancelShipment(e);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delivered',
                        child: Text('Confirmar entrega'),
                      ),
                      PopupMenuItem(
                        value: 'cancel',
                        child: Text('Anular con motivo'),
                      ),
                    ],
                  )
                : null,
          ),
        )
        .toList(),
  );

  Widget _incidenciesList() => _listPage(
    _incidencies
        .map(
          (i) => _dataCard(
            title: '${i['tipus'] ?? 'Incidencia'} · ${_incidentReference(i)}',
            subtitle:
                '${_date(i['data_incidencia'])} · ${i['estat'] ?? 'abierta'}',
            icon: Icons.warning_amber,
            detail: '${i['descripcio'] ?? ''}',
            trailingWidget:
                i['estat'] == 'oberta' ||
                    i['estat'] == 'en_curs' ||
                    i['estat'] == 'tancada' && i['verificada_at'] == null
                ? PopupMenuButton<String>(
                    tooltip: 'Acciones de incidencia',
                    onSelected: (action) {
                      if (action == 'review') _markIncidentInProgress(i);
                      if (action == 'close') _closeIncident(i);
                      if (action == 'verify') _verifyIncident(i);
                    },
                    itemBuilder: (_) => [
                      if (i['estat'] == 'oberta')
                        const PopupMenuItem(
                          value: 'review',
                          child: Text('Marcar en revisión'),
                        ),
                      if (i['estat'] == 'tancada' && i['verificada_at'] == null)
                        const PopupMenuItem(
                          value: 'verify',
                          child: Text('Verificar acción correctiva'),
                        ),
                      if (i['estat'] == 'oberta' || i['estat'] == 'en_curs')
                        const PopupMenuItem(
                          value: 'close',
                          child: Text('Cerrar con acción correctiva'),
                        ),
                    ],
                  )
                : null,
          ),
        )
        .toList(),
  );

  Widget _listPage(List<Widget> children) => RefreshIndicator(
    onRefresh: _load,
    child: children.isEmpty
        ? ListView(
            children: const [
              SizedBox(height: 100),
              Center(child: Text('No hay registros todavía')),
            ],
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            children: children,
          ),
  );

  Widget _dataCard({
    required String title,
    required String subtitle,
    required IconData icon,
    String? trailing,
    String? detail,
    Widget? trailingWidget,
  }) => Card(
    child: ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F6EC),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF268443)),
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF20252B),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Color(0xFF667085)),
        ),
      ),
      trailing:
          trailingWidget ??
          (trailing == null
              ? null
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    trailing,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344054),
                    ),
                  ),
                )),
      onTap: detail == null
          ? null
          : () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(title),
                content: SingleChildScrollView(child: Text(detail)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tancar'),
                  ),
                ],
              ),
            ),
    ),
  );

  String _nestedName(
    Map<String, dynamic> row,
    String relation,
    String key,
    String fallback,
  ) {
    final value = row[relation];
    if (value is Map && value[key] != null) return value[key].toString();
    if (value is List &&
        value.isNotEmpty &&
        value.first is Map &&
        value.first[key] != null)
      return value.first[key].toString();
    return fallback;
  }

  String _incidentReference(Map<String, dynamic> item) {
    switch ('${item['origen'] ?? 'lot'}') {
      case 'sensor':
        return _nestedName(item, 'obrador_sensors', 'nom', 'Sensor');
      case 'recepcio':
        return _nestedName(
          item,
          'obrador_recepcions',
          'lot_proveidor',
          'Recepción',
        );
      case 'torn':
      case 'registre':
        return 'Registro de higiene';
      default:
        return _nestedName(item, 'obrador_lots', 'codi_lot', 'Lote');
    }
  }

  String _date(dynamic value) {
    if (value == null) return 'Fecha desconocida';
    final parsed = DateTime.tryParse(value.toString())?.toLocal();
    if (parsed == null) return value.toString();
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _allergens(dynamic value) {
    if (value is List && value.isNotEmpty) return value.join(', ');
    return 'No especificados';
  }
}
