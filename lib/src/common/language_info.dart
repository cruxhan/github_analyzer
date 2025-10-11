import 'package:path/path.dart' as path;

const Map<String, String> kLanguageExtensions = {
  // Programming Languages
  'dart': 'Dart',
  'py': 'Python',
  'js': 'JavaScript',
  'ts': 'TypeScript',
  'jsx': 'JavaScript',
  'tsx': 'TypeScript',
  'java': 'Java',
  'kt': 'Kotlin',
  'kts': 'Kotlin',
  'swift': 'Swift',
  'c': 'C',
  'cpp': 'C++',
  'cc': 'C++',
  'cxx': 'C++',
  'h': 'C',
  'hpp': 'C++',
  'cs': 'C#',
  'go': 'Go',
  'rs': 'Rust',
  'rb': 'Ruby',
  'php': 'PHP',
  'scala': 'Scala',
  'r': 'R',
  'lua': 'Lua',
  'pl': 'Perl',
  'sh': 'Shell',
  'bash': 'Shell',
  'zsh': 'Shell',
  'fish': 'Shell',
  'ps1': 'PowerShell',
  'bat': 'Batch',
  'cmd': 'Batch',

  // Web
  'html': 'HTML',
  'htm': 'HTML',
  'css': 'CSS',
  'scss': 'SCSS',
  'sass': 'Sass',
  'less': 'Less',
  'vue': 'Vue',
  'svelte': 'Svelte',

  // Data & Config
  'json': 'JSON',
  'yaml': 'YAML',
  'yml': 'YAML',
  'toml': 'TOML',
  'xml': 'XML',
  'ini': 'INI',
  'conf': 'Config',
  'config': 'Config',
  'env': 'Environment',

  // Documentation
  'md': 'Markdown',
  'markdown': 'Markdown',
  'rst': 'reStructuredText',
  'txt': 'Text',
  'tex': 'LaTeX',

  // Database
  'sql': 'SQL',
  'sqlite': 'SQLite',
  'psql': 'PostgreSQL',

  // Build & Package
  'gradle': 'Gradle',
  'maven': 'Maven',
  'cmake': 'CMake',
  'make': 'Makefile',

  // Others
  'asm': 'Assembly',
  's': 'Assembly',
  'vim': 'VimScript',
  'el': 'Emacs Lisp',
  'clj': 'Clojure',
  'ex': 'Elixir',
  'exs': 'Elixir',
  'erl': 'Erlang',
  'hrl': 'Erlang',
  'hs': 'Haskell',
  'ml': 'OCaml',
  'nim': 'Nim',
  'v': 'V',
  'zig': 'Zig',
};

const Map<String, String> kSyntaxHighlighting = {
  'Dart': 'dart',
  'Python': 'python',
  'JavaScript': 'javascript',
  'TypeScript': 'typescript',
  'Java': 'java',
  'Kotlin': 'kotlin',
  'Swift': 'swift',
  'C': 'c',
  'C++': 'cpp',
  'C#': 'csharp',
  'Go': 'go',
  'Rust': 'rust',
  'Ruby': 'ruby',
  'PHP': 'php',
  'Scala': 'scala',
  'R': 'r',
  'Lua': 'lua',
  'Perl': 'perl',
  'Shell': 'bash',
  'Bash': 'bash',
  'Zsh': 'zsh',
  'Fish': 'fish',
  'PowerShell': 'powershell',
  'Batch': 'batch',
  'HTML': 'html',
  'CSS': 'css',
  'SCSS': 'scss',
  'Sass': 'sass',
  'Less': 'less',
  'Vue': 'vue',
  'Svelte': 'svelte',
  'JSON': 'json',
  'YAML': 'yaml',
  'TOML': 'toml',
  'XML': 'xml',
  'Markdown': 'markdown',
  'SQL': 'sql',
  'Gradle': 'gradle',
  'CMake': 'cmake',
  'Makefile': 'makefile',
  'Dockerfile': 'dockerfile',
  'Assembly': 'asm',
  'VimScript': 'vim',
  'Clojure': 'clojure',
  'Elixir': 'elixir',
  'Erlang': 'erlang',
  'Haskell': 'haskell',
  'OCaml': 'ocaml',
  'Nim': 'nim',
  'Zig': 'zig',
};

String? detectLanguage(String filePath) {
  final fileName = path.basename(filePath);
  final fileNameLower = fileName.toLowerCase();

  if (fileNameLower == 'dockerfile' ||
      fileNameLower.startsWith('dockerfile.')) {
    return 'Dockerfile';
  }
  if (fileNameLower == 'makefile' || fileNameLower.startsWith('makefile.')) {
    return 'Makefile';
  }
  if (fileNameLower == 'gemfile') {
    return 'Ruby';
  }
  if (fileNameLower == 'rakefile') {
    return 'Ruby';
  }
  if (fileNameLower == '.bashrc' || fileNameLower == '.zshrc') {
    return 'Shell';
  }

  final extension = path.extension(filePath).toLowerCase();
  if (extension.isEmpty) {
    return null;
  }

  final ext = extension.substring(1);
  return kLanguageExtensions[ext];
}

String? getSyntaxHighlighting(String filePath) {
  final language = detectLanguage(filePath);
  if (language == null) return null;
  return kSyntaxHighlighting[language];
}
