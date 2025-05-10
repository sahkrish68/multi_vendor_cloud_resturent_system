# 🍽️ Multi-Vendor Cloud Restaurant System

A modern and scalable **Flutter-Firebase** based mobile application that connects **customers**, **traders (restaurant/cloud kitchen owners)**, and **admins** in a single platform to manage online food ordering across multiple vendors.

---

## 📱 App Features

### 👤 User Panel (Customers)
- Register/login with email & OTP verification
- Browse restaurants and cloud kitchens
- View food menu, add to cart
- Place orders and track real-time status
- Online payment (PayPal/eSewa) or Cash on Delivery
- View order history and status
- Health tracker and doctor consult (optional)

### 🍳 Trader Panel (Restaurant/Cloud Kitchen Owners)
- Login with secure authentication
- Add/manage menus and prices
- View incoming orders and update order status
- Manage inventory and staff (optional)
- View order history and reports

### 🛠️ Admin Panel
- Manage users and traders
- Approve or reject new trader applications
- Monitor system-wide orders and payments
- Maintain categories, banners, and app content

---

## 📂 Project Structure

```
/lib
│
├── models/               # Data models (User, Product, Order, etc.)
├── services/             # Auth, Database, Storage services
├── screens/              # UI screens (Login, Home, TraderDashboard, etc.)
├── widgets/              # Reusable widgets
├── utils/                # Utilities and constants
└── main.dart             # App entry point
```

---

## 🛠️ Tech Stack

| Tool                  | Purpose                                |
|-----------------------|-----------------------------------------|
| **Flutter**           | Frontend Framework                      |
| **Firebase Auth**     | User Authentication (Email/OTP)         |
| **Cloud Firestore**   | Realtime NoSQL Database                 |
| **Firebase Storage**  | Uploading and serving images            |
| **Firebase Functions**| (Optional) Background logic             |
| **PayPal / eSewa**    | Payment Integration                     |
| **SharedPreferences** | Persistent local storage                |

---

## 🚀 Getting Started

### ✅ Prerequisites

- Flutter SDK (Latest version)
- Android Studio or VS Code
- Firebase Project
- `google-services.json` for Android
- FlutterFire CLI (for Firebase integration)

### ⚙️ Installation Steps

```bash
git clone https://github.com/yourusername/multi_vendor_cloud_restaurant_system.git
cd multi_vendor_cloud_restaurant_system
flutter pub get
```

### 🔗 Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Add Android/iOS apps
4. Enable:
   - Email/Password Authentication
   - Firestore Database
   - Firebase Storage
5. Download and place `google-services.json` in `/android/app`

### ▶️ Run the App

```bash
flutter run
```

---

## 📸 Screenshots

> You can add screenshots of:
- 📱 Home Page
- 🍔 Restaurant Menu
- 🛒 Cart and Order Tracking
- 📊 Admin Dashboard
- 📦 Order Management

---

## 🔒 Firebase Firestore Rules (Example)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    match /traders/{traderId} {
      allow read: if true;
      allow write: if request.auth.uid == traderId;
    }

    match /orders/{orderId} {
      allow read, write: if request.auth != null;
    }

    match /restaurants/{restaurantId} {
      allow read: if true;
      allow write: if request.auth.uid == restaurantId;
    }
  }
}
```

---

## 🧪 Testing and QA

- ✅ Manual testing for:
  - Registration/Login
  - Menu display and cart updates
  - Order placement and status updates
  - Payment integration via PayPal or eSewa
- ✅ Admin approval process for new trader accounts
- Optional: Firebase Crashlytics and Analytics

---

## 📦 Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.0.0
  firebase_auth: ^4.0.0
  cloud_firestore: ^4.0.0
  firebase_storage: ^11.0.0
  provider: ^6.0.5
  shared_preferences: ^2.0.15
  intl: ^0.18.0
  fl_chart: ^0.45.1
  percent_indicator: ^4.2.3
```

---

## 👨‍💻 Developer Info

- **Project Title:** Multi-Vendor Cloud Restaurant System
- **Developer:** Krish Bikram Sah
- **University:** Leeds Beckett University
- **College:** The British College
- **Degree:** BSc (Hons) Computing - Final Year Project
- **Year:** 2025

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 💡 Future Enhancements

- Push notifications for order updates
- Multilingual and regional support
- Ratings and reviews for restaurants
- Dynamic coupons and discount system
- Real-time location tracking and delivery status