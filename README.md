# offline_ai_expense_tracker

A new Flutter project.

## Development

### Linux Setup (For Development Speed)
This project includes pre-built `llama.cpp` libraries for Linux in `assets/libs/` to enable fast development and debugging on desktop without needing an emulator.
- **Run:** `flutter run -d linux`
- **Note:** The app will automatically copy the model and libraries to a temporary directory.

### Mobile Setup (Android/iOS)
The `llama_cpp_dart` package handles the native libraries automatically.
- **Run:** `flutter run` (on a connected device or emulator)
- **Note:** Ensure your device has enough RAM (at least 4GB recommended) to load the model.

## Project Structure
- `lib/core`: Constants and utilities
- `lib/models`: Hive models (Transaction)
- `lib/services`: AI and Database services
- `lib/ui`: Screens and widgets
- `assets/models`: Contains the Qwen 2.5 0.5B GGUF model
# first_1-2eroy
