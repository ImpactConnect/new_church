import 'package:cms/src/features/branches/models/branch_model.dart';

abstract class BranchRepository {
  Stream<List<BranchModel>> watchBranches();
  Stream<BranchModel?> watchBranch(String branchId);
  Future<BranchModel?> getBranch(String branchId);
  Future<void> saveBranch(BranchModel branch);
  Future<void> deleteBranch(String branchId);
  Future<void> createBranchWithPastor({
    required BranchModel branch,
    required String pastorName,
    required String pastorEmail,
    required String password,
  });
}

