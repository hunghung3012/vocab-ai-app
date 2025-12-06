# Vocab AI

## Description
Vocab AI is a mobile application built with Flutter that helps users learn and practice vocabulary. It leverages AI/ML capabilities for various features to enhance the learning experience.

## Features
- **Quiz Mode**: Interactive quizzes to test vocabulary knowledge.
- **Word Recognition**: (Potentially using ML Kit for text recognition from images or real-time camera feed).
- **Pronunciation Guide**: Text-to-speech functionality for correct word pronunciation.
- **Personalized Learning**: (Future feature: AI-powered recommendations for words to learn).
- **User Authentication**: Secure login and registration.
- **Progress Tracking**: Monitor learning progress and statistics.

## Installation

### Prerequisites
- Flutter SDK installed.
- Android Studio or VS Code with Flutter plugin.
- Firebase project set up with `google-services.json` (for Android) configured.

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/vocab_ai.git
   cd vocab_ai
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Usage
- Register or log in to your account.
- Explore different quiz modes to learn new words.
- Use the word recognition feature (if implemented) to learn words from images.
- Practice pronunciation with the built-in guide.
- Track your progress and improve your vocabulary!

## Technologies Used
- Flutter
- Dart
- Firebase (Authentication, Cloud Firestore, Storage)
- Google ML Kit (potentially for text recognition, etc.)
- Provider (for state management)
- `flutter_tts` (for text-to-speech)
- `google_sign_in` (for Google authentication)

## Contributing
Contributions are welcome! Please feel free to open issues or submit pull requests.

## License
This project is licensed under the MIT License. See the `LICENSE` file for more details.
