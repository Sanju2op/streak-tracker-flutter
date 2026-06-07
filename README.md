# Streak Tracker

A premium, minimalistic Flutter application designed to help you build and maintain habits through powerful streak tracking. Achieve your goals, track your progress, and celebrate your consistency.

## 🌐 Try It Online

Experience Streak Tracker directly in your browser:

**[Visit Live Demo](https://streak-tracker-flutter.vercel.app/)**

## ✨ Key Features

- **Beautiful Counters**: Track multiple streaks with an intuitive, grid-based interface
- **Dynamic Themes**: Seamless Light and Dark mode support that adapts to your system preferences
- **Advanced Analytics**: Visualize your progress with interactive charts and detailed streak history
- **Smart Reminders**: Customizable notifications to keep you motivated and on track
- **Home Screen Widgets**: Stay motivated with at-a-glance progress widgets (Square Small, Square Big, Rounded)
- **Share Your Achievements**: Export beautifully designed streak cards to share with friends and family
- **Secure Local Storage**: All data is persisted locally and securely using SQLite

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0+)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- For web deployment: Node.js (optional)

### Installation & Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Sanju2op/streak-tracker-flutter.git
   cd streak-tracker-flutter
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   # For mobile
   flutter run
   
   # For web
   flutter run -d chrome
   ```

## 🛠 Technology Stack

| Component | Technology |
|-----------|-----------|
| **Framework** | Flutter |
| **State Management** | Riverpod |
| **Local Database** | SQLite (sqflite) |
| **Data Persistence** | shared_preferences |
| **Analytics** | fl_chart |
| **Notifications** | flutter_local_notifications |

## 🎨 Design Philosophy

The application features a modern, sophisticated design with:
- Elegant frosted glass effects using BackdropFilter
- Smooth, fluid animations (scale and fade transitions)
- Carefully curated color palettes for visual harmony
- Premium typography and spacing principles

## 📱 Home Screen Widgets

Stay motivated at a glance with multiple widget options:

- **Square Small** (2x2): Compact centered streak display
- **Square Big** (4x4): Comprehensive grid view for multiple streaks
- **Rounded** (Circular): Minimalistic circular widget display

## 📦 Project Structure

```
lib/
├── models/        # Data models (Counter, Goal, Reminder, etc.)
├── providers/     # State management with Riverpod
├── screens/       # UI screens and pages
├── sheets/        # Modal bottom sheets
├── widgets/       # Reusable UI components
├── db/            # Database abstraction layer
├── utils/         # Utility functions and helpers
└── constants/     # App configuration and themes
```

## 📄 License & Attribution

This project is developed with attention to professional standards and best practices.

Made with ❤️ by [Sanju2op](https://github.com/Sanju2op)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for any improvements or bug reports.
