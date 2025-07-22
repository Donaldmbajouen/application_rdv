# Flutter Agent Configuration

## Commands
- **Build**: `flutter build apk` / `flutter build ios`
- **Run**: `flutter run` (debug), `flutter run --release` (release)
- **Test**: `flutter test` (all tests), `flutter test test/specific_test.dart` (single test)
- **Lint**: `flutter analyze`
- **Format**: `dart format .`
- **Dependencies**: `flutter pub get`, `flutter pub upgrade`

## Architecture
- **Main**: `lib/main.dart` - App entry point with MaterialApp
- **Models**: `lib/models/` - Data models for RDV, Client, Service
- **Database**: `lib/database/` - SQLite database helper and migrations  
- **Screens**: `lib/screens/` - UI screens (calendar, clients, settings, etc.)
- **Widgets**: `lib/widgets/` - Reusable UI components
- **Providers**: `lib/providers/` - Riverpod state management
- **Services**: `lib/services/` - Business logic (notifications, etc.)

## Code Style
- **Imports**: Flutter first, then external packages, then relative imports
- **Naming**: camelCase for variables/methods, PascalCase for classes
- **Widgets**: StatelessWidget preferred, const constructors when possible
- **Keys**: Use `super.key` for widget constructors
- **Formatting**: Use `dart format`, 2-space indentation
- **State**: Use Riverpod for state management, avoid setState when possible
