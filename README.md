# flutter_sqlite3_extension_cli

## Getting Started

If the CLI application is available on [pub](https://pub.dev), activate globally via:

```sh
dart pub global activate flutter_sqlite3_extension
```

Or locally via:

```sh
dart pub global activate --source=path <path to this package>
```

## Usage

1. Download SQLite custom extension .c file
2. Run the command pointed to the .c file

```bash
flutter_sqlite3_extension -s /path/to/sqlite3_extension.c -n name_of_extension
```

3. Update `example/lib.main.dart` with the new extension logic.
