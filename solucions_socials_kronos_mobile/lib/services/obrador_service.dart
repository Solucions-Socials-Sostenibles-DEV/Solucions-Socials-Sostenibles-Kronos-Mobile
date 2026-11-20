import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso a las tablas existentes del módulo Obrador en Supabase.
/// No contiene claves privadas: utiliza la sesión autenticada de la app.
class ObradorService {
  ObradorService([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> dashboardRecepcions() => _list(
    'obrador_recepcions',
    'id, data_recepcio, estat, temperatura_arribada, lot_proveidor, obrador_proveidors(nom)',
  );

  Future<List<Map<String, dynamic>>> proveidors() async {
    final response = await _client
        .from('obrador_proveidors')
        .select('id, nom')
        .order('nom');
    return _maps(response);
  }

  Future<List<Map<String, dynamic>>> productes() async {
    try {
      final response = await _client
          .from('obrador_productes')
          .select(
            'id, nom, caducitat_dies, temp_coccio, temp_conservacio, allergens, fitxa_tecnica, actiu, obrador_producte_proveidors(id_proveidor, ingredient_nom)',
          )
          .eq('actiu', true)
          .order('nom');
      return _maps(response);
    } catch (_) {
      final response = await _client
          .from('obrador_productes')
          .select(
            'id, nom, caducitat_dies, temp_coccio, temp_conservacio, allergens, fitxa_tecnica, actiu',
          )
          .eq('actiu', true)
          .order('nom');
      return _maps(response);
    }
  }

  Future<List<Map<String, dynamic>>> recepcions() async {
    final rows = await _client
        .from('obrador_recepcions')
        .select(
          'id, id_proveidor, data_recepcio, id_producte, num_albara, quantitat, unitat, tipus, lot_proveidor, temperatura_arribada, estat, caducitat, congelat, observacions, operari, obrador_proveidors(nom), obrador_productes(nom)',
        )
        .order('data_recepcio', ascending: false)
        .limit(200);
    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> lots() async {
    final rows = await _client
        .from('obrador_lots')
        .select(
          'id, codi_lot, data_produccio, estat, quantitat_kg, temp_final_coccio, mostra_guardada, observacions, id_producte, id_recepcio, obrador_productes(nom), obrador_etiquetes(codi_qr, data_caducitat, allergens)',
        )
        .order('data_produccio', ascending: false)
        .limit(200);
    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> expedicions() async {
    final rows = await _client
        .from('obrador_expedicions')
        .select(
          'id, id_client, data_sortida, comanda_holded, estat, check_client, check_sortida, observacions, obrador_lots(codi_lot, estat, obrador_productes(nom))',
        )
        .order('data_sortida', ascending: false)
        .limit(200);
    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> incidencies() async {
    final rows = await _client
        .from('obrador_incidencies')
        .select(
          'id, tipus, descripcio, data_incidencia, estat, origen, notes_tancament, verificada_at, obrador_lots(codi_lot), obrador_sensors(nom, ubicacio), obrador_recepcions(lot_proveidor, obrador_proveidors(nom))',
        )
        .order('data_incidencia', ascending: false)
        .limit(200);
    return _maps(rows);
  }

  /// Lecturas más recientes primero. La pantalla de resumen conserva solamente
  /// la última lectura de cada ubicación para no convertir el histórico en
  /// alertas activas.
  Future<List<Map<String, dynamic>>> temperatures() async {
    final rows = await _client
        .from('obrador_temperatures')
        .select('id, ubicacio, valor, tipus, mesura_at')
        .order('mesura_at', ascending: false)
        .limit(500);
    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> sensors() =>
      _list('obrador_sensors', 'id, nom, ubicacio, tipus, actiu');

  Future<List<Map<String, dynamic>>> _list(String table, String columns) async {
    final response = await _client.from(table).select(columns).limit(100);
    return _maps(response);
  }

  List<Map<String, dynamic>> _maps(dynamic rows) =>
      (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<String> crearRecepcio({
    required String idProveidor,
    required String idProducte,
    String? lotProveidor,
    String? numeroAlbara,
    double? quantitat,
    required String unitat,
    required String tipus,
    double? temperatura,
    required String estat,
    DateTime? caducitat,
    required bool congelat,
    String? observacions,
  }) async {
    final user = _client.auth.currentUser;
    final profile = user == null
        ? <String, dynamic>{}
        : await _client
              .from('user_profiles')
              .select('name')
              .eq('id', user.id)
              .maybeSingle();
    final row = await _client
        .from('obrador_recepcions')
        .insert({
          'id_proveidor': idProveidor,
          'id_producte': idProducte,
          'lot_proveidor': _emptyToNull(lotProveidor),
          'num_albara': _emptyToNull(numeroAlbara),
          'quantitat': quantitat,
          'unitat': unitat,
          'tipus': tipus,
          'temperatura_arribada': temperatura,
          'estat': estat,
          'caducitat': caducitat?.toIso8601String().substring(0, 10),
          'congelat': congelat || tipus == 'congelat',
          'observacions': _emptyToNull(observacions),
          'operari': profile?['name'] ?? user?.email,
        })
        .select('id')
        .single();
    return row['id'].toString();
  }

  Future<void> crearIncidencia({
    String? idLot,
    String? idSensor,
    String? idRecepcio,
    String origen = 'lot',
    required String tipus,
    required String descripcio,
  }) async {
    await _client.from('obrador_incidencies').insert({
      'id_lot': idLot,
      'id_sensor': idSensor,
      'id_recepcio': idRecepcio,
      'origen': origen,
      'tipus': tipus,
      'descripcio': descripcio.trim(),
    });
  }

  Future<void> crearIncidenciaRecepcio({
    required String idRecepcio,
    required String tipus,
    required String descripcio,
  }) async {
    await _client.from('obrador_incidencies').insert({
      'id_recepcio': idRecepcio,
      'origen': 'recepcio',
      'tipus': tipus,
      'descripcio': descripcio.trim(),
      'estat': 'oberta',
    });
  }

  Future<void> tancarIncidencia(String id, {required String notes}) async {
    await _client
        .from('obrador_incidencies')
        .update({
          'estat': 'tancada',
          'tancada_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'notes_tancament': notes.trim(),
        })
        .eq('id', id);
  }

  Future<void> verificarIncidencia(String id) async {
    final isManagement = await _client.rpc('obrador_is_management_user');
    if (isManagement != true) {
      throw StateError(
        'Solo el personal de gestión puede verificar incidencias.',
      );
    }
    final userId = _client.auth.currentUser?.id;
    if (userId == null)
      throw StateError('No hay una sesión de usuario activa.');
    await _client
        .from('obrador_incidencies')
        .update({
          'verificada_per': userId,
          'verificada_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('estat', 'tancada')
        .isFilter('verificada_at', null)
        .select('id')
        .single();
  }

  Future<void> marcarIncidenciaEnCurs(String id) async {
    await _client
        .from('obrador_incidencies')
        .update({
          'estat': 'en_curs',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<String> crearProducte({
    required String nom,
    int? caducitatDies,
    double? tempCoccio,
    double? tempConservacio,
    required List<String> allergens,
    String? fitxaTecnica,
  }) async {
    final row = await _client
        .from('obrador_productes')
        .insert({
          'nom': nom.trim(),
          'caducitat_dies': caducitatDies,
          'temp_coccio': tempCoccio,
          'temp_conservacio': tempConservacio,
          'allergens': allergens,
          'fitxa_tecnica': _emptyToNull(fitxaTecnica),
          'actiu': true,
        })
        .select('id')
        .single();
    return row['id'].toString();
  }

  Future<void> actualitzarProducte({
    required String id,
    required String nom,
    int? caducitatDies,
    double? tempCoccio,
    double? tempConservacio,
    required List<String> allergens,
    String? fitxaTecnica,
  }) async {
    await _client
        .from('obrador_productes')
        .update({
          'nom': nom.trim(),
          'caducitat_dies': caducitatDies,
          'temp_coccio': tempCoccio,
          'temp_conservacio': tempConservacio,
          'allergens': allergens,
          'fitxa_tecnica': _emptyToNull(fitxaTecnica),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> arxivarProducte(String id) async {
    await _client
        .from('obrador_productes')
        .update({
          'actiu': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> setProducteProveidors(
    String idProducte,
    Map<String, String> proveidors,
  ) async {
    await _client
        .from('obrador_producte_proveidors')
        .delete()
        .eq('id_producte', idProducte);
    if (proveidors.isEmpty) return;
    await _client
        .from('obrador_producte_proveidors')
        .insert(
          proveidors.entries
              .map(
                (entry) => {
                  'id_producte': idProducte,
                  'id_proveidor': entry.key,
                  'ingredient_nom': entry.value.trim(),
                },
              )
              .toList(),
        );
  }

  Future<Map<String, dynamic>> crearLot({
    required String idProducte,
    required List<String> idsRecepcions,
    required double quantitatKg,
    double? temperaturaFinal,
    required bool mostraGuardada,
    required int caducitatDies,
    required List<String> allergens,
    String? observacions,
  }) async {
    if (idsRecepcions.isEmpty) {
      throw ArgumentError('El lote necesita al menos una recepción de origen.');
    }
    final result = await _client.rpc(
      'obrador_crear_lot_i_etiqueta',
      params: {
        'p_id_producte': idProducte,
        'p_id_recepcio': idsRecepcions.first,
        'p_id_operari': null,
        'p_quantitat_kg': quantitatKg,
        'p_temp_final_coccio': temperaturaFinal,
        'p_mostra_guardada': mostraGuardada,
        'p_observacions': _emptyToNull(observacions),
        'p_caducitat_dies': caducitatDies,
        'p_allergens': allergens,
        'p_id_recepcions': idsRecepcions,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> crearEtiqueta(
    String idLot, {
    required int caducitatDies,
    required List<String> allergens,
  }) async {
    final expiry = DateTime.now().add(Duration(days: caducitatDies));
    final qr = 'QR-$idLot-${DateTime.now().millisecondsSinceEpoch}';
    final label = await _client
        .from('obrador_etiquetes')
        .insert({
          'id_lot': idLot,
          'codi_qr': qr,
          'allergens': allergens,
          'data_caducitat': _dateOnly(expiry),
        })
        .select()
        .single();
    await _client
        .from('obrador_lots')
        .update({'estat': 'envasat'})
        .eq('id', idLot);
    return Map<String, dynamic>.from(label);
  }

  Future<void> crearExpedicio({
    required String idLot,
    required String nomClient,
    String? comanda,
    required bool checkSortida,
    required bool checkClient,
    String? observacions,
  }) async {
    await _client.rpc(
      'obrador_crear_expedicio_i_marcar_lot',
      params: {
        'p_id_lot': idLot,
        'p_id_client': nomClient.trim(),
        'p_comanda_holded': _emptyToNull(comanda),
        'p_check_sortida': checkSortida,
        'p_check_client': checkClient,
        'p_observacions': _emptyToNull(observacions),
      },
    );
  }

  Future<void> marcarExpedicioEntregada(
    String id, {
    required bool checkClient,
  }) async {
    await _client.rpc(
      'obrador_marcar_expedicio_entregada',
      params: {'p_id': id, 'p_check_client': checkClient},
    );
  }

  Future<void> anularExpedicio(String id, String motiu) async {
    await _client.rpc(
      'obrador_anular_expedicio',
      params: {'p_id': id, 'p_motiu': motiu.trim()},
    );
  }

  /// Tipos de registro configurados por el módulo web de higiene.
  Future<List<Map<String, dynamic>>> tipusRegistreHigiene() async {
    final rows = await _client
        .from('obrador_tipus_registre')
        .select(
          'codi, etiqueta, codis_pla, frequencia, unic_per_periode, es_checklist, actiu, maxim_per_periode',
        )
        .eq('actiu', true)
        .order('etiqueta');
    return _maps(rows);
  }

  /// Registros APPCC/higiene existentes en la misma tabla que usa la web.
  Future<List<Map<String, dynamic>>> registresHigiene() async {
    final rows = await _client
        .from('obrador_registres_torn')
        .select(
          'id, data, tipus_codi, items, observacions, incidencia_detectada, created_at, obrador_tipus_registre(etiqueta)',
        )
        .order('data', ascending: false)
        .order('created_at', ascending: false)
        .limit(100);
    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> registresTorn() async {
    final rows = await _client
        .from('obrador_registres_torn')
        .select(
          'id, data, moment, tipus_codi, items, observacions, incidencia_detectada, id_incidencia, created_at',
        )
        .order('data', ascending: false)
        .order('created_at', ascending: false)
        .limit(200);
    return _maps(rows);
  }

  /// Fichas de coste activas junto con sus ingredientes ordenados.
  Future<List<Map<String, dynamic>>> escandalls() async {
    final rows = await _client
        .from('obrador_escandalls')
        .select(
          'id, nom, linia, id_producte, rendiment, unitat_rendiment, pvp_unitari, observacions, actiu, created_at, updated_at, '
          'obrador_productes(nom), '
          'obrador_escandall_ingredients(id, nom, quantitat, unitat, cost_unitari, merma_percent, ordre)',
        )
        .eq('actiu', true)
        .order('nom');
    return _maps(rows);
  }

  Future<void> crearEscandall({
    required String nom,
    required String linia,
    String? idProducte,
    required double rendiment,
    required String unitatRendiment,
    required double pvpUnitari,
    String? observacions,
    required List<Map<String, dynamic>> ingredients,
  }) async {
    final created = await _client
        .from('obrador_escandalls')
        .insert({
          'nom': nom.trim(),
          'linia': linia,
          'id_producte': idProducte,
          'rendiment': rendiment,
          'unitat_rendiment': unitatRendiment,
          'pvp_unitari': pvpUnitari,
          'observacions': _emptyToNull(observacions),
        })
        .select('id')
        .single();
    final escandallId = created['id'];
    await _client.from('obrador_escandall_ingredients').insert([
      for (var index = 0; index < ingredients.length; index++)
        {
          'id_escandall': escandallId,
          'nom': ingredients[index]['nom'],
          'quantitat': ingredients[index]['quantitat'],
          'unitat': ingredients[index]['unitat'],
          'cost_unitari': ingredients[index]['costUnitari'],
          'merma_percent': ingredients[index]['merma'],
          'ordre': index,
        },
    ]);
  }

  Future<void> eliminarEscandall(String id) =>
      _client.from('obrador_escandalls').delete().eq('id', id);

  /// Datos de impacto social que no pueden deducirse de la trazabilidad.
  Future<Map<String, dynamic>?> kpiMensual(DateTime month) async {
    final row = await _client
        .from('obrador_kpis_mensuales')
        .select(
          'mes, personas_insercion, horas_formacion, contrataciones, observaciones, updated_at',
        )
        .eq('mes', _monthOnly(month))
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<void> guardarKpiMensual({
    required DateTime month,
    required int personasInsercion,
    required double horasFormacion,
    required int contrataciones,
    String? observaciones,
  }) => _client.from('obrador_kpis_mensuales').upsert({
    'mes': _monthOnly(month),
    'personas_insercion': personasInsercion,
    'horas_formacion': horasFormacion,
    'contrataciones': contrataciones,
    'observaciones': _emptyToNull(observaciones),
  }, onConflict: 'mes');

  Future<Map<String, dynamic>?> registreTornDelDia({
    required String data,
    required String moment,
  }) async {
    final row = await _client
        .from('obrador_registres_torn')
        .select(
          'id, data, moment, tipus_codi, items, observacions, incidencia_detectada, id_incidencia',
        )
        .eq('data', data)
        .eq('moment', moment)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<void> crearRegistreTorn({
    required String data,
    required String moment,
    required List<Map<String, dynamic>> items,
    String? observacions,
  }) async {
    await _client.from('obrador_registres_torn').insert({
      'data': data,
      'moment': moment,
      'tipus_codi': switch (moment) {
        'inici' => 'torn_inici',
        'produccio' => 'torn_produccio',
        _ => 'torn_tancament',
      },
      'periode_inici': data,
      'items': items,
      'incidencia_detectada': items.any((item) => item['ok'] == false),
      'registrat_per': _client.auth.currentUser?.id,
      'observacions': _emptyToNull(observacions),
    });
  }

  Future<Map<String, List<Map<String, dynamic>>>> exportacio({
    required DateTime desde,
    required DateTime fins,
  }) async {
    final start = _dateOnly(desde);
    Future<List<Map<String, dynamic>>> read(
      String table,
      String columns,
      String dateColumn, {
      bool dateOnly = false,
    }) async {
      final from = dateOnly
          ? start
          : DateTime(
              desde.year,
              desde.month,
              desde.day,
            ).toUtc().toIso8601String();
      final until = dateOnly
          ? _dateOnly(fins)
          : DateTime(
              fins.year,
              fins.month,
              fins.day + 1,
            ).toUtc().toIso8601String();
      var query = _client.from(table).select(columns).gte(dateColumn, from);
      query = dateOnly
          ? query.lte(dateColumn, until)
          : query.lt(dateColumn, until);
      final rows = await query.limit(20000);
      return _maps(rows);
    }

    final results = await Future.wait([
      read(
        'obrador_recepcions',
        'id, data_recepcio, lot_proveidor, temperatura_arribada, estat, caducitat, congelat, observacions, obrador_proveidors(nom), obrador_productes(nom)',
        'data_recepcio',
      ),
      read(
        'obrador_lots',
        'id, codi_lot, data_produccio, estat, quantitat_kg, temp_final_coccio, mostra_guardada, observacions, obrador_productes(nom)',
        'data_produccio',
      ),
      read(
        'obrador_expedicions',
        'id, id_client, data_sortida, comanda_holded, estat, check_client, observacions, obrador_lots(codi_lot)',
        'data_sortida',
      ),
      read(
        'obrador_incidencies',
        'id, tipus, descripcio, data_incidencia, estat, notes_tancament, obrador_lots(codi_lot)',
        'data_incidencia',
      ),
      read(
        'obrador_registres_torn',
        'id, data, moment, tipus_codi, items, observacions, incidencia_detectada, created_at',
        'data',
        dateOnly: true,
      ),
      read(
        'obrador_temperatures',
        'id, ubicacio, valor, tipus, mesura_at',
        'mesura_at',
      ),
    ]);
    return {
      'Recepciones': results[0],
      'Lotes': results[1],
      'Expediciones': results[2],
      'Incidencias': results[3],
      'Registros de turno': results[4],
      'Temperaturas': results[5],
    };
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _monthOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-01';

  Future<void> crearRegistreHigiene({
    required String tipusCodi,
    required DateTime data,
    required String observacions,
    required bool incidenciaDetectada,
    List<Map<String, dynamic>> items = const [],
    Map<String, dynamic>? detall,
  }) async {
    final date = _dateOnly(data);
    await _client.from('obrador_registres_torn').insert({
      'data': date,
      'tipus_codi': tipusCodi,
      'periode_inici': date,
      'registrat_per': _client.auth.currentUser?.id,
      'items': items,
      'detall': detall,
      'observacions': _emptyToNull(observacions),
      'incidencia_detectada':
          incidenciaDetectada || items.any((item) => item['ok'] == false),
      'origen_extern': false,
    });
  }

  String? _emptyToNull(String? value) {
    final v = value?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }
}
