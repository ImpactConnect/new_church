import 'package:cms/src/features/finance/models/group_income_model.dart';

abstract class GroupIncomeRepository {
  Stream<List<GroupIncomeRecordModel>> watchGroupIncomes(
    String branchId,
    String entityId,
  );

  Stream<List<GroupIncomeRecordModel>> watchAllBranchGroupIncomes(
    String branchId,
  );

  Future<void> recordGroupIncome(
    String branchId,
    GroupIncomeRecordModel record,
  );

  Future<void> deleteGroupIncome(
    String branchId,
    String recordId,
  );
}
