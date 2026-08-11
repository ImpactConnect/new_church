import 'package:cms/src/features/branches/models/branch_model.dart';

abstract class BranchRepository {
  Stream<List<BranchModel>> watchBranches();
  Future<BranchModel?> getBranch(String branchId);
  Future<void> saveBranch(BranchModel branch);
}
