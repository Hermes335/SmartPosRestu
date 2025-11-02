# SmartServe POS - Setup & Configuration Guide

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Firebase Configuration](#firebase-configuration)
3. [AI API Integration](#ai-api-integration)
4. [Environment Setup](#environment-setup)
5. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

### Step 1: Install Dependencies

Open terminal in the project directory and run:

```powershell
flutter pub get
```

This will install all required packages including:
- Firebase SDK
- Charts library (fl_chart)
- HTTP client
- State management (provider)
- Internationalization (intl)

### Step 2: Run the Application

```powershell
flutter run
```

The app will launch with **mock data** - perfect for testing without Firebase!

---

## 🔥 Firebase Configuration

### Why Firebase?

Firebase provides:
- **Real-time Database**: Instant data synchronization across devices
- **Authentication**: Secure user login system
- **Cloud Storage**: Store images and files
- **Analytics**: Track app usage and user behavior

### Complete Setup Steps

#### 1. Create Firebase Project

1. Visit: https://console.firebase.google.com/
2. Click **"Add project"**
3. Project name: `smartserve-pos`
4. Disable Google Analytics (optional for now)
5. Click **"Create project"**

#### 2. Add Android App

1. In Firebase Console, click **Android icon** (🤖)
2. **Package name**: `com.example.smart_restupos`
   - To verify: Open `android/app/build.gradle.kts`
   - Look for `applicationId`
3. **App nickname**: SmartServe POS (optional)
4. Click **"Register app"**

#### 3. Download Configuration File

1. Download `google-services.json`
2. Place in: `android/app/google-services.json`
3. **Important**: This file contains your Firebase credentials

#### 4. Configure Android Build Files

**File: `android/build.gradle.kts`**

Add to buildscript dependencies:
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**File: `android/app/build.gradle.kts`**

Add at the top (with other plugins):
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")  // Add this line
}
```

#### 5. Add iOS App (Optional)

1. In Firebase Console, click **iOS icon** (🍎)
2. **Bundle ID**: `com.example.smartRestupos`
   - Find in: `ios/Runner.xcodeproj/project.pbxproj`
3. Download `GoogleService-Info.plist`
4. Open `ios/Runner.xcworkspace` in Xcode
5. Drag `GoogleService-Info.plist` into `Runner` folder
6. Check **"Copy items if needed"**

#### 6. Enable Firebase Services

##### Authentication:
1. Left sidebar → **Authentication**
2. Click **"Get started"**
3. **Sign-in method** tab
4. Enable **"Email/Password"**
5. Click **"Save"**

##### Realtime Database:
1. Left sidebar → **Realtime Database**
2. Click **"Create Database"**
3. Select location (closest to your users)
4. Start in **"Test mode"** (for development)
   - **Warning**: Test mode allows all read/write access
   - Change to production rules before launch
5. Click **"Enable"**

#### 7. Set Database Rules (Development)

Go to **Realtime Database** → **Rules** tab:

```json
{
  "rules": {
    "orders": {
      ".read": true,
      ".write": true
    },
    "tables": {
      ".read": true,
      ".write": true
    },
    "staff": {
      ".read": true,
      ".write": true
    },
    "menu": {
      ".read": true,
      ".write": true
    }
  }
}
```

**For Production**, use authenticated rules:

```json
{
  "rules": {
    "orders": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "tables": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "staff": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "menu": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

#### 8. Initialize Firebase in Code

**File: `lib/main.dart`**

Uncomment the Firebase initialization:

```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();  // Uncomment this line
  
  runApp(const SmartServePOS());
}
```

#### 9. Test Firebase Connection

Run the app:
```powershell
flutter run
```

Check the console for:
- ✅ "Firebase initialized successfully"
- ❌ Any Firebase errors (follow troubleshooting section)

---

## 🤖 AI API Integration

### Current Setup: Mock Data

The app currently uses **mock data** for AI forecasting. This allows you to:
- Test the UI without external dependencies
- Develop and design features
- Demo the application

### Integration Options

#### Option 1: Python + Flask API

**1. Create Python API Server**

```python
# forecast_api.py
from flask import Flask, request, jsonify
from datetime import datetime, timedelta
import random

app = Flask(__name__)

@app.route('/api/forecast', methods=['POST'])
def get_forecast():
    """Generate 7-day sales forecast"""
    data = request.json
    start_date = datetime.fromisoformat(data['startDate'].replace('Z', '+00:00'))
    
    forecasts = []
    for i in range(7):
        date = start_date + timedelta(days=i)
        forecasts.append({
            'date': date.isoformat(),
            'predictedRevenue': 1500 + (i * 200) + random.randint(-100, 100),
            'confidence': 0.85 - (i * 0.02),
            'insights': [
                f'Expected {15 + i} orders',
                'Peak hours: 12 PM - 2 PM, 6 PM - 8 PM'
            ]
        })
    
    return jsonify(forecasts)

@app.route('/api/insights', methods=['GET'])
def get_insights():
    """Generate AI insights"""
    insights = [
        '📈 Sales increased by 15% compared to last week',
        '🍕 Pizza is your top-selling item this month',
        '⏰ Peak hours are between 12 PM - 2 PM and 6 PM - 8 PM',
        '👥 Table 5 generates the highest revenue',
        '💡 Consider promoting beverages - lower sales than average'
    ]
    return jsonify({'insights': insights})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
```

**2. Install Dependencies**
```bash
pip install flask flask-cors
```

**3. Run the Server**
```bash
python forecast_api.py
```

**4. Update Flutter App**

In `lib/services/forecast_service.dart`:
```dart
static const String baseUrl = 'http://localhost:5000/api';  // For testing
// For production: 'https://your-deployed-api.com/api'
```

#### Option 2: Node.js + Express API

```javascript
// server.js
const express = require('express');
const app = express();
app.use(express.json());

app.post('/api/forecast', (req, res) => {
    const { startDate, endDate } = req.body;
    // Your forecasting logic here
    res.json(forecasts);
});

app.get('/api/insights', (req, res) => {
    const insights = [/* Your insights */];
    res.json({ insights });
});

app.listen(5000, () => console.log('Server running on port 5000'));
```

#### Option 3: Cloud Functions

Deploy serverless functions on:
- **Firebase Functions**
- **AWS Lambda**
- **Google Cloud Functions**
- **Azure Functions**

### Deployment Options

1. **Heroku** (Easy, Free tier available)
2. **Google Cloud Run** (Container-based)
3. **AWS EC2** (Full control)
4. **DigitalOcean** (Simple VPS)
5. **Vercel/Netlify** (For Node.js APIs)

### Machine Learning Models

Recommended models for sales forecasting:

1. **Facebook Prophet**
   - Easy to use
   - Good for seasonal data
   - Handles holidays

2. **LSTM (Long Short-Term Memory)**
   - Deep learning approach
   - Great for time series
   - Requires more data

3. **ARIMA**
   - Statistical method
   - Good for short-term forecasts
   - Less data required

4. **XGBoost**
   - Gradient boosting
   - High accuracy
   - Fast training

---

## 🛠️ Environment Setup

### 1. Flutter Environment

Check your Flutter installation:
```powershell
flutter doctor
```

Fix any issues reported (Android SDK, iOS tools, etc.)

### 2. IDE Setup (VS Code)

**Recommended Extensions:**
- Flutter
- Dart
- Firebase Explorer
- Error Lens
- Bracket Pair Colorizer

### 3. Android Studio

1. Download: https://developer.android.com/studio
2. Install Android SDK
3. Create AVD (Android Virtual Device) for testing

### 4. Physical Device Testing

**Android:**
1. Enable Developer Options on phone
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter devices`

**iOS:**
1. Open Xcode
2. Add Apple Developer account
3. Connect iPhone
4. Trust developer certificate

---

## 🐛 Troubleshooting

### Firebase Issues

**Error: "Firebase not initialized"**
```dart
// Ensure this is in main.dart before runApp()
await Firebase.initializeApp();
```

**Error: "google-services.json not found"**
- Check file location: `android/app/google-services.json`
- Verify file is not in subdirectory
- Run `flutter clean` and rebuild

**Error: "Plugin not found"**
```powershell
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### Build Issues

**Gradle Build Failed**
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

**iOS Build Failed**
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter run
```

### Runtime Issues

**Hot Reload Not Working**
- Press `R` in terminal for hot reload
- Press `Shift + R` for hot restart
- Stop and restart `flutter run`

**UI Not Updating**
- Check if widget is StatefulWidget
- Call `setState(() { })` for updates
- Verify data is actually changing

### Firebase Connection Issues

**Can't read/write data**
1. Check Firebase rules
2. Verify internet connection
3. Check Firebase console for errors
4. Enable debug logging:
```dart
FirebaseDatabase.instance.setLoggingEnabled(true);
```

---

## 🎯 Next Steps

After setup:

1. ✅ Test all screens with mock data
2. ✅ Connect to Firebase and test real-time sync
3. ✅ Customize colors and branding
4. ✅ Add your own menu items
5. ✅ Set up authentication
6. ✅ Deploy AI forecasting API
7. ✅ Test with real users
8. ✅ Deploy to production

---

## 📞 Need Help?

- Check Firebase documentation: https://firebase.google.com/docs
- Flutter documentation: https://flutter.dev/docs
- Stack Overflow: Tag questions with `flutter` and `firebase`
- GitHub Issues: Report bugs in the repository

---

**You're all set! Start building your restaurant management system! 🚀**
