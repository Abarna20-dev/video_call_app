# 📹 Flutter WebRTC Video Calling App

A modern, real-time peer-to-peer multi-user video calling application built with **Flutter**, **WebRTC**, and **Socket.IO**.

---

## ✨ Features

- **Peer-to-Peer Calling**: High-quality, low-latency audio & video streaming powered by WebRTC.
- **Multi-Peer Room Mesh**: Join rooms by room name with automatic peer discovery and mesh connection handling.
- **Dynamic Video Grid**: Responsive grid layout that dynamically adapts as participants join and leave.
- **Local Video Preview**: Real-time floating camera preview with mirrored rendering.
- **Signaling via Socket.IO**: WebRTC offer, answer, and ICE candidate exchange via WebSockets.
- **Runtime Permissions**: Automated camera and microphone permission handling on mobile devices.

---

## 🛠️ Tech Stack & Dependencies

| Tool / Package | Purpose |
|---|---|
| **Flutter & Dart** | Cross-platform UI framework and language |
| **[`flutter_webrtc`](https://pub.dev/packages/flutter_webrtc)** | WebRTC plugin for Flutter (Audio, Video & Data channels) |
| **[`socket_io_client`](https://pub.dev/packages/socket_io_client)** | Real-time signaling client for connection negotiation |
| **[`permission_handler`](https://pub.dev/packages/permission_handler)** | Requesting runtime camera & microphone permissions |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `3.13.4` or higher)
- Android Studio / VS Code with Flutter extension
- An Android device (USB debugging enabled) or emulator
- A running Socket.IO signaling server (Node.js)

---

### 1. Configure Signaling Server URL

Open [`lib/main.dart`](lib/main.dart) and update `serverUrl` with your machine's local IP address or remote server domain:

```dart
// For physical Android device: your computer's local Wi-Fi IP (e.g. 192.168.1.X:3000)
// For Android Emulator: http://10.0.2.2:3000
const serverUrl = 'http://192.168.1.10:3000';
```

---

### 2. Install Dependencies

```bash
flutter pub get
```

---

### 3. Run the App

Connect your device and run:

```bash
flutter run
```

---

## 📦 Building for Production

### Android Release APK

To generate an optimized release APK:

```bash
flutter build apk --release
```

The APK will be generated at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

> **Tip**: To produce smaller APKs split per CPU architecture (`arm64-v8a`, `armeabi-v7a`), run:
> ```bash
> flutter build apk --split-per-abi
> ```

---

## 📡 Signaling Protocol

The app uses the following Socket.IO events for establishing WebRTC connections:

- `join` (`roomName`) – Notify server that user entered a room.
- `existing-peers` – Received list of socket IDs already in the room; caller creates offers for each.
- `signal` (`{ to, data }`) – Routes SDP offers, answers, and ICE candidates between peers.
- `peer-left` (`peerId`) – Cleans up video renderer and peer connection when a peer disconnects.

---

## 📱 Permissions

Required Android permissions configured in `android/app/src/main/AndroidManifest.xml`:
- `INTERNET`
- `CAMERA`
- `RECORD_AUDIO`
- `MODIFY_AUDIO_SETTINGS`
- `ACCESS_NETWORK_STATE`

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
