# SmartServe POS - Restaurant Point of Sale System

![SmartServe POS](https://img.shields.io/badge/Flutter-v3.9.2-blue)
![Firebase](https://img.shields.io/badge/Firebase-Integrated-orange)
![AI](https://img.shields.io/badge/AI-Powered-green)

## 📱 Overview

SmartServe POS is a comprehensive Flutter mobile application for restaurant management with AI-driven sales forecasting and performance analysis. This modern point-of-sale system helps restaurant owners and managers efficiently manage orders, tables, staff, and gain insights into their business performance.

## ✨ Features

### 🏠 Sales Dashboard (Home)
- Real-time sales metrics and statistics
- Today's revenue and order count
- Active tables overview
- Top-selling items display
- Interactive sales charts
- Quick access to all modules

### 📦 Order Management
- Create, view, edit, and complete orders
- Filter orders by status (Pending, Preparing, Ready, Served, Completed, Cancelled)
- Assign orders to tables
- Real-time order tracking
- Order history and details

### 🪑 Table Management
- Visual table grid with status indicators
- Available/Occupied/Reserved/Cleaning states
- Assign orders to tables
- Quick table status updates
- Table capacity management

### 👥 Staff Management
- Staff roster with roles (Manager, Waiter, Chef, Cashier)
- Performance scores and metrics
- Total orders served tracking
- Staff details and profiles
- Role-based filtering

### 📊 Sales & Performance Analysis
- Historical sales data visualization
- AI-powered sales forecasting (7-day predictions)
- Revenue trends and comparisons
- AI-driven insights and recommendations
- Category-wise performance analysis
- Confidence scores for predictions

## 🏗️ Project Structure

```
lib/
├── models/               # Data models
│   ├── order_model.dart
│   ├── table_model.dart
│   ├── staff_model.dart
│   ├── menu_item_model.dart
│   └── sales_data_model.dart
│
├── services/            # Business logic and API services
│   ├── auth_service.dart
│   ├── order_service.dart
│   ├── table_service.dart
│   ├── staff_service.dart
│   └── forecast_service.dart
│
├── screens/             # UI screens
│   ├── dashboard_screen.dart
│   ├── order_management_screen.dart
│   ├── table_management_screen.dart
│   ├── staff_management_screen.dart
│   └── analytics_screen.dart
│
├── widgets/             # Reusable UI components
│   ├── stat_card.dart
│   ├── order_card.dart
│   ├── table_card.dart
│   └── staff_card.dart
│
├── utils/               # Utility functions and constants
│   ├── constants.dart
│   └── formatters.dart
│
└── main.dart            # App entry point and navigation
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.9.2 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase account
- Visual Studio Code (recommended)

### Installation

1. **Clone the repository**
   ```bash
   cd d:\Documents_D\Codes.Ams\flutter\FinalProj\smart_restupos
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 🔥 Firebase Setup

### Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `smartserve-pos`
4. Follow the setup wizard

### Step 2: Add Firebase to Your Flutter App

#### For Android:

1. In Firebase Console, click the Android icon
2. Register your app with package name: `com.smartserve.pos`
3. Download `google-services.json`
4. Place it in `android/app/` directory

5. Update `android/build.gradle.kts`:
   ```kotlin
   buildscript {
       dependencies {
           classpath("com.google.gms:google-services:4.4.0")
       }
   }
   ```

6. Update `android/app/build.gradle.kts`:
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }
   ```

#### For iOS:

1. In Firebase Console, click the iOS icon
2. Register your app with bundle ID: `com.smartserve.pos`
3. Download `GoogleService-Info.plist`
4. Add it to `ios/Runner/` in Xcode

### Step 3: Enable Firebase Services

#### Enable Authentication:
1. In Firebase Console, go to Authentication
2. Click "Get Started"
3. Enable "Email/Password" sign-in method

#### Enable Realtime Database:
1. Go to Realtime Database
2. Click "Create Database"
3. Choose location
4. Start in **test mode** (for development)

#### Database Rules (for development):
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

### Step 4: Initialize Firebase in Code

Update `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const SmartServePOS());
}
```

### Step 5: Test Firebase Connection

Run the app and check for any Firebase initialization errors:
```bash
flutter run
```

## 🤖 AI Forecasting API Setup

### Option 1: Using Mock Data (Current Setup)

The app currently uses mock data for AI forecasting. This is perfect for development and testing.

### Option 2: Integrate Real AI Service

To integrate a real AI forecasting service:

1. **Update the API endpoint** in `lib/services/forecast_service.dart`:
   ```dart
   static const String baseUrl = 'https://your-api-endpoint.com/api';
   ```

2. **Create API Endpoints** (example using Python/Flask):

   ```python
   from flask import Flask, request, jsonify
   from datetime import datetime, timedelta
   
   app = Flask(__name__)
   
   @app.route('/api/forecast', methods=['POST'])
   def get_forecast():
       data = request.json
       start_date = datetime.fromisoformat(data['startDate'])
       end_date = datetime.fromisoformat(data['endDate'])
       
       # Your ML model prediction here
       forecasts = predict_sales(start_date, end_date)
       
       return jsonify(forecasts)
   
   @app.route('/api/insights', methods=['GET'])
   def get_insights():
       # Generate AI insights
       insights = generate_insights()
       return jsonify({'insights': insights})
   ```

3. **Deploy Your API** (options):
   - Google Cloud Run
   - AWS Lambda
   - Heroku
   - Your own server

4. **Add Authentication** (recommended):
   ```dart
   final response = await http.post(
     Uri.parse('$baseUrl/forecast'),
     headers: {
       'Content-Type': 'application/json',
       'Authorization': 'Bearer YOUR_API_KEY',
     },
     body: jsonEncode(requestData),
   );
   ```

### Sample ML Model Integration

You can use models like:
- **Prophet** (Facebook) - Time series forecasting
- **LSTM** - Deep learning for sequence prediction
- **ARIMA** - Statistical forecasting
- **XGBoost** - Gradient boosting for predictions

## 🎨 Customization

### Change Theme Colors

Edit `lib/utils/constants.dart`:

```dart
static const Color primaryOrange = Color(0xFFFF6B35);  // Your color
static const Color darkBackground = Color(0xFF1A1A1A);  // Your color
```

### Add New Features

1. Create new model in `lib/models/`
2. Create service in `lib/services/`
3. Create screen in `lib/screens/`
4. Add route in `lib/main.dart`

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.8.1        # Firebase core
  firebase_auth: ^5.3.3        # Authentication
  firebase_database: ^11.3.3   # Realtime database
  provider: ^6.1.2             # State management
  http: ^1.2.2                 # HTTP requests
  fl_chart: ^0.69.2            # Charts and graphs
  intl: ^0.19.0                # Internationalization
```

## 🧪 Testing

Run tests:
```bash
flutter test
```

## 📱 Build for Production

### Android:
```bash
flutter build apk --release
```

### iOS:
```bash
flutter build ios --release
```

## 🔒 Security Best Practices

1. **Never commit sensitive data** (API keys, passwords)
2. **Use environment variables** for configuration
3. **Implement proper Firebase security rules**
4. **Enable authentication** before production
5. **Use HTTPS** for all API calls
6. **Validate user input** on both client and server

## 📈 Future Enhancements

- [ ] Push notifications for new orders
- [ ] QR code menu integration
- [ ] Customer feedback system
- [ ] Multi-language support
- [ ] Offline mode with data sync
- [ ] Payment gateway integration
- [ ] Inventory management
- [ ] Reporting and export features
- [ ] Advanced ML models for better predictions
- [ ] Real-time chat between staff

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Author

Created with ❤️ for modern restaurant management

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Email: support@smartserve.com (placeholder)

---

**Happy Coding! 🚀**

