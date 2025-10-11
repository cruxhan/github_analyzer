import 'package:github_analyzer/src/models/repository_metadata.dart';

abstract class IGithubApiProvider {
  Future<RepositoryMetadata> getRepositoryMetadata(String owner, String repo);
  void dispose();
}
