import 'package:hive/hive.dart';
import '../models/berean_evaluation_model.dart';
import '../../../config/app_config.dart';

class BereanRepository {
  Box<BereanEvaluationModel> get _box =>
      Hive.box<BereanEvaluationModel>(AppConfig.bereanBoxName);

  Future<List<BereanEvaluationModel>> getAll() async {
    final evaluations = _box.values.toList();
    evaluations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return evaluations;
  }

  Future<void> save(BereanEvaluationModel evaluation) async {
    await _box.put(evaluation.id, evaluation);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<BereanEvaluationModel?> getById(String id) async {
    return _box.get(id);
  }
}
