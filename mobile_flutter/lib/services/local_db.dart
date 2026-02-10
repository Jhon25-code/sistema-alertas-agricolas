import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static Database? _db;

  // ============================
  // ABRIR BASE DE DATOS
  // ============================
  static Future<Database> _openDB() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "siaas.db");

    _db = await openDatabase(
      path,
      version: 4,
      onCreate: (Database db, int version) async {
        await db.execute("""
          CREATE TABLE incidentes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            local_id INTEGER,
            tipo TEXT,
            descripcion TEXT,
            ubicacion TEXT,
            hora TEXT,
            prioridad TEXT,
            severidad TEXT,
            fotoPath TEXT,
            lat REAL,
            lng REAL,
            sincronizado INTEGER DEFAULT 0,
            timestamp TEXT,
            smart_score INTEGER DEFAULT 0,
            status TEXT DEFAULT 'pendiente'
          );
        """);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 4) {
          await _addColumnIfMissing(db, "incidentes", "local_id", "INTEGER");
          await _addColumnIfMissing(db, "incidentes", "lat", "REAL");
          await _addColumnIfMissing(db, "incidentes", "lng", "REAL");
          await _addColumnIfMissing(db, "incidentes", "timestamp", "TEXT");
          await _addColumnIfMissing(db, "incidentes", "smart_score", "INTEGER");
          await _addColumnIfMissing(db, "incidentes", "status", "TEXT");
          await _addColumnIfMissing(db, "incidentes", "severidad", "TEXT");
        }
      },
    );

    return _db!;
  }

  // ============================
  // AGREGAR COLUMNA SI FALTA
  // ============================
  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final res = await db.rawQuery("PRAGMA table_info($table);");
    final exists = res.any((c) => c['name'] == column);

    if (!exists) {
      await db.execute("ALTER TABLE $table ADD COLUMN $column $type");
    }
  }

  // ============================
  // INSERTAR INCIDENTE (OFFLINE)
  // ============================
  static Future<int> saveIncident(Map<String, dynamic> data) async {
    final db = await _openDB();

    final safeData = <String, dynamic>{
      "local_id": DateTime.now().millisecondsSinceEpoch,
      "tipo": (data["tipo"] ?? "").toString(),
      "descripcion": (data["descripcion"] ?? "").toString(),
      "ubicacion": (data["ubicacion"] ?? "offline").toString(),
      "hora": (data["hora"] ?? "").toString(),
      "prioridad": (data["prioridad"] ?? "medio").toString(),
      "severidad": (data["severidad"] ?? "leve").toString(),
      "fotoPath": (data["fotoPath"] ?? "").toString(),
      "lat": data["lat"],
      "lng": data["lng"],
      "sincronizado": 0,
      "timestamp": DateTime.now().toIso8601String(),
      "smart_score": data["smart_score"] ?? 0,
      "status": "pendiente", // ✅ correcto: solo offline
    };

    return await db.insert("incidentes", safeData);
  }

  // ============================
  // OBTENER INCIDENTES PENDIENTES
  // ============================
  static Future<List<Map<String, dynamic>>> getPendingIncidents() async {
    final db = await _openDB();
    return await db.query(
      "incidentes",
      where: "sincronizado = 0",
      orderBy: "timestamp DESC",
    );
  }

  // ============================
  // MARCAR COMO SINCRONIZADO (CORREGIDO)
  // ============================
  static Future<int> markAsSynced(
    int id, {
    String statusFromServer = 'NUEVA',
  }) async {
    final db = await _openDB();

    return await db.update(
      "incidentes",
      {
        "sincronizado": 1,
        "status": statusFromServer, // ✅ estado REAL del backend
      },
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // ============================
  // ACTUALIZAR ESTADO POR local_id
  // ============================
  static Future<int> updateIncidentStatusByLocalId(
    int localId,
    String newStatus,
  ) async {
    final db = await _openDB();

    return await db.update(
      "incidentes",
      {
        "status": newStatus,
      },
      where: "local_id = ?",
      whereArgs: [localId],
    );
  }

  // ============================
  // METODO COMPATIBLE (NO SE TOCA)
  // ============================
  static Future<int> updateIncidentStatus(
    int localId,
    String newStatus,
  ) async {
    return updateIncidentStatusByLocalId(localId, newStatus);
  }

  // ============================
  // LIMPIAR BASE (DEBUG)
  // ============================
  static Future<void> deleteAll() async {
    final db = await _openDB();
    await db.delete("incidentes");
  }
}
