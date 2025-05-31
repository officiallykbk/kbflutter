import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bizorganizer/models/cargo_job.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'jobs.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE jobs (
            id TEXT PRIMARY KEY,
            shipperName TEXT,
            receiptUrl TEXT,
            pickupDate TEXT,
            estimatedDeliveryDate TEXT,
            actualDeliveryDate TEXT,
            pickupLocation TEXT,
            dropoffLocation TEXT,
            agreedPrice REAL,
            paymentStatus TEXT,
            deliveryStatus TEXT,
            notes TEXT,
            createdBy TEXT, 
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');
      },
    );
  }

  Future<void> batchInsertJobs(List<CargoJob> jobs) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('jobs'); // Clear existing jobs
      Batch batch = txn.batch();
      for (var job in jobs) {
        // Prepare a map that includes all fields needed for the local DB,
        // especially id, createdAt, updatedAt which might be excluded by default CargoJob.toJson()
        // if that method is tailored for Supabase inserts only.
        Map<String, dynamic> jobMap = {
          'id': job.id,
          'shipperName': job.shipperName,
          'receiptUrl': job.receiptUrl,
          'pickupDate': job.pickupDate?.toIso8601String(),
          'estimatedDeliveryDate': job.estimatedDeliveryDate?.toIso8601String(),
          'actualDeliveryDate': job.actualDeliveryDate?.toIso8601String(),
          'pickupLocation': job.pickupLocation,
          'dropoffLocation': job.dropoffLocation,
          'agreedPrice': job.agreedPrice,
          'paymentStatus': job.paymentStatus,
          'deliveryStatus': job.deliveryStatus,
          'notes': job.notes,
          'createdBy': job.createdBy, // Maps to 'userId' in prompt, but model uses 'createdBy'
          'createdAt': job.createdAt?.toIso8601String(),
          'updatedAt': job.updatedAt?.toIso8601String(),
        };
        // Filter out null values to avoid inserting NULLs explicitly if column constraints change
        jobMap.removeWhere((key, value) => value == null && key != 'id'); // id can be null for new objects but not for DB PK here
        
        // However, the table schema allows NULLs for most fields.
        // For simplicity and matching CargoJob.toJson() which might return nulls:
        // We'll use a modified toJson that includes id, createdAt, updatedAt for local storage.
        // Or, construct the map manually as above. The manual construction is more explicit here.

        batch.insert('jobs', jobMap);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<CargoJob>> getAllJobs() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('jobs', orderBy: 'createdAt DESC');

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      // The CargoJob.fromJson method should correctly handle these fields.
      // It expects 'shipper_name', 'payment_status', etc. from its Supabase origins.
      // We need to ensure our DB column names map to what fromJson expects,
      // or transform the map keys here.
      // The CargoJob.fromJson in the prompt handles snake_case keys.
      // Our table uses camelCase for columns (except id). This is a mismatch.
      // For consistency with CargoJob.fromJson, table columns should be snake_case.
      // Re-creating table with snake_case or transforming map keys here.
      // Given the prompt's SQL uses camelCase (except id), I will transform keys here.

      // Transformation map:
      Map<String, dynamic> transformedMap = {
        'id': maps[i]['id'],
        'shipper_name': maps[i]['shipperName'],
        'receipt_url': maps[i]['receiptUrl'],
        'pickup_date': maps[i]['pickupDate'],
        'estimated_delivery_date': maps[i]['estimatedDeliveryDate'],
        'actual_delivery_date': maps[i]['actualDeliveryDate'],
        'pickup_location': maps[i]['pickupLocation'],
        'dropoff_location': maps[i]['dropoffLocation'],
        'agreed_price': maps[i]['agreedPrice'],
        'payment_status': maps[i]['paymentStatus'],
        'delivery_status': maps[i]['deliveryStatus'],
        'notes': maps[i]['notes'],
        'created_by': maps[i]['createdBy'],
        'created_at': maps[i]['createdAt'],
        'updated_at': maps[i]['updatedAt'],
      };
      return CargoJob.fromJson(transformedMap);
    });
  }

  // Close the database (optional, as sqflite handles this, but good for explicit cleanup)
  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null; // Reset the static instance
  }
}
/*
Correction needed based on analysis during generation:
The `CargoJob.fromJson` method expects snake_case keys (e.g., 'shipper_name', 'pickup_date').
The SQL table was created with camelCase keys (e.g., 'shipperName', 'pickupDate').
This mismatch will cause `fromJson` to fail or misinterpret data.

Option 1: Change SQL table to use snake_case. (Preferred for consistency with fromJson)
Option 2: Transform map keys in `getAllJobs` before passing to `fromJson`. (Done in the code above)

The prompt's SQL used camelCase (except 'id' and 'agreedPrice REAL').
I've opted for Option 2 in the code above to match the prompt's SQL structure and then transform.
However, the most robust solution is to align the database schema with the JSON keys expected by `fromJson`.

Let's assume the prompt's SQL structure is fixed and the transformation in `getAllJobs` is the intended workaround.
The `effectiveDeliveryStatus` was correctly excluded from the schema as it's a computed field.
The `userId` from prompt was mapped to `createdBy` as per `CargoJob` model.

The `batchInsertJobs` method now manually constructs a map. This is good as `CargoJob.toJson()`
as provided in the model file excludes `id`, `createdAt`, `updatedAt`.
For local caching, these are essential.
*/
