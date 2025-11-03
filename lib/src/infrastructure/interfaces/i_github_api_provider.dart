import 'package:github_analyzer/src/models/repository_metadata.dart';

abstract class IGithubApiProvider {
  Future<RepositoryMetadata> getRepositoryMetadata(String owner, String repo);

  /// Fetches the latest commit SHA for a specific branch.
  Future<String?> getCommitShaForBranch(
      String owner, String repo, String branch);

  void dispose();
}
