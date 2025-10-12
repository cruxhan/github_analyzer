## 0.0.3

* [Fix] Addressed issues from v0.0.2 and introduced new features.

## 0.0.2

* **Major Refactoring for Usability and Maintainability.**

* **Added Top-Level `analyze` Function**: Drastically simplified the API. Users can now analyze repositories with a single function call, without needing to manually set up dependencies.
* **Implemented Dependency Injection**: Refactored the `GithubAnalyzer` class to accept dependencies via its constructor, improving modularity and testability.
* **Integrated Standard Logging Package**: Replaced the custom logger with the standard Dart `logging` package for more robust and flexible logging.
* **Improved Error Handling**: Enhanced `AnalyzerException` to include the original exception and stack trace, providing more context for debugging.

## 0.0.1

* Initial release of the package.
* Provides core functionality for analyzing remote and local repositories.