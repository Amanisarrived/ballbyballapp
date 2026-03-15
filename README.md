# 🏏 BallByBall

A live cricket companion app built with Flutter — real-time scores, match discussions, team polls, and push notifications.

---

## Features

- 📊 **Live Scores** — ball-by-ball updates in real time
- 💬 **Dugout** — match discussion feed with reactions, comments and team voting
- 🔔 **Push Notifications** — match alerts via Firebase Cloud Messaging
- 🔐 **Google Sign In** — auth with Firebase
- 🛡️ **Admin Panel** — moderate comments, ban/timeout users, manage matchups

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Framework | Flutter |
| Backend | Firebase Firestore |
| Auth | Firebase Auth (Google) |
| Notifications | Firebase Cloud Messaging |
| State | Provider |
| Images | CachedNetworkImage |

---

## Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Firebase project with Firestore, Auth and FCM enabled
- `google-services.json` placed in `android/app/`

### Run
```bash
flutter pub get
flutter run
```

---

## Project Structure
```
lib/
├── providers/        # Auth, state management
├── screens/          # UI screens
│   ├── dugout/       # Discussion + voting
│   └── ...
├── services/         # Firestore service classes
└── main.dart
```

---

## Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Firestore**, **Authentication** (Google provider) and **Cloud Messaging**
3. Download `google-services.json` → place in `android/app/`
4. Set Firestore rules as needed

---

## License

Private project — all rights reserved.
