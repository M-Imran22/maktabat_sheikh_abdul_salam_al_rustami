# مکتبہ شیخ عبدالسلام الرستمی
# Maktabat Sheikh Abdul Salam Al-Rustami

A Flutter mobile application containing the complete collection of books (PDF) and audio lectures by Sheikh Abdul Salam Al-Rustami (رحمہ اللہ).

## Features

- **📚 Digital Library**: Complete collection of Sheikh's books in PDF format
- **🎧 Audio Lectures**: All audio lectures and speeches
- **👤 Biography**: Detailed information about Sheikh's life and contributions
- **🌙 Islamic Design**: Beautiful UI with Islamic patterns and Urdu/Arabic text support
- **📱 Mobile Optimized**: Responsive design for all screen sizes

## Installation

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Add your PDF books to `assets/pdfs/` directory
4. Add your audio files to `assets/audio/` directory
5. Run `flutter run` to start the app

## Dependencies

- `flutter_pdfview`: For PDF viewing functionality
- `audioplayers`: For audio playback
- `path_provider`: For file system access
- `http`: For network requests
- `shared_preferences`: For storing user preferences

## Project Structure

```
lib/
├── main.dart                 # Main app entry point
├── screens/
│   ├── books_screen.dart     # Books listing screen
│   ├── audio_screen.dart     # Audio lectures screen
│   └── biography_screen.dart # Sheikh's biography screen
└── assets/
    ├── images/              # App images and icons
    ├── fonts/               # Arabic/Urdu fonts
    ├── pdfs/                # PDF books
    └── audio/               # Audio lectures
```

**اللہ تعالیٰ ہم سب کو اس علم سے فائدہ اٹھانے کی توفیق عطا فرمائے۔ آمین**
