# SEENS Flutter App

Student Entry and Exit Notification System - Flutter Version

## Overview

This is the Flutter version of the SEENS (Student Entry and Exit Notification System) that maintains the same database and functionality as the original PHP system while providing a modern, cross-platform mobile interface.

## Features

### Core Functionality
- **Student Management**: Add, view, and delete students with photos
- **QR Code Scanning**: Scan student QR codes for entry/exit logging
- **RFID Support**: NFC/RFID card scanning capabilities
- **QR Code Generation**: Generate QR codes for students
- **Real-time Logging**: Track student entry and exit times
- **Database Integration**: Maintains compatibility with existing PHP backend

### Technical Features
- **Cross-platform**: Works on iOS, Android, and Web
- **Modern UI**: Clean, responsive design with Material 3
- **State Management**: Provider pattern for efficient state handling
- **API Integration**: RESTful API communication with PHP backend
- **Offline Support**: Local caching and error handling
- **Security**: Token-based authentication and data validation

## Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   └── models.dart          # Student, LogEntry, Account models
├── services/                 # Business logic
│   └── api_service.dart     # HTTP client and API calls
├── providers/                # State management
│   └── student_provider.dart # Student data state
├── screens/                  # UI screens
│   ├── main_screen.dart     # Main navigation
│   ├── home_screen.dart     # Dashboard
│   ├── scanner_screen.dart  # QR/RFID scanner
│   ├── students_screen.dart # Student management
│   └── settings_screen.dart # App settings
├── widgets/                  # Reusable components
│   ├── student_card.dart    # Student list item
│   ├── student_info_card.dart # Student details
│   ├── add_student_dialog.dart # Add student form
│   ├── rfid_scanner.dart    # RFID scanning widget
│   └── qr_generator.dart    # QR code generation
└── utils/                    # Utility functions
```

### Database Compatibility

The Flutter app uses the same database structure as the PHP system:

- **Database**: `seait_seens`
- **Tables**:
  - `seens_student` - Student records
  - `seens_logs` - Entry/exit logs
  - `seens_account` - User accounts
  - `seens_adviser` - Adviser information
  - `seens_visitors` - Visitor records
  - `activity_logs` - System activity logs

### API Integration

The app communicates with the existing PHP backend via RESTful APIs:

- **Base URL**: `http://localhost/seens`
- **Authentication**: Token-based (token: "Seait123")
- **Endpoints**:
  - `GET /backend_scripts/get_users.php` - Get all students
  - `POST /backend_scripts/check_id.php` - Validate student ID
  - `POST /backend_scripts/add_user.php` - Add new student
  - `POST /backend_scripts/delete_user.php` - Delete student
  - `POST /backend_scripts/save_logs.php` - Save entry/exit logs

## Installation

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Existing SEENS PHP backend (MySQL/MariaDB)
- XAMPP or equivalent web server

### Setup Instructions

1. **Clone/Setup the Flutter Project**
   ```bash
   cd /Applications/XAMPP/xamppfiles/htdocs/seens_flutter
   flutter pub get
   ```

2. **Configure Backend Connection**
   - Ensure the PHP backend is running on `http://localhost/seens`
   - Verify database connection in `configuration.php`
   - Check that all backend scripts are accessible

3. **Run the App**
   ```bash
   flutter run
   ```

4. **Platform-specific Setup**
   
   **Android:**
   - Add camera and NFC permissions to `android/app/src/main/AndroidManifest.xml`
   - Minimum SDK: 21 (Android 5.0)
   
   **iOS:**
   - Add camera and NFC permissions to `ios/Runner/Info.plist`
   - Minimum iOS version: 11.0
   
   **Web:**
   - HTTPS required for camera access
   - NFC not supported on web

## Usage

### 1. Dashboard (Home Screen)
- View system statistics
- Quick access to scanner and student management
- Real-time connection status

### 2. QR Scanner
- **Scan Tab**: Scan student QR codes for entry/exit
- **RFID Tab**: Scan NFC/RFID cards (if device supports NFC)
- **Generate Tab**: Create QR codes for new students

### 3. Student Management
- View all registered students
- Add new students with photos
- Delete student records
- Search and filter functionality

### 4. Settings
- View system configuration
- Check connection status
- App information and version

## Configuration

### API Configuration
Edit `lib/services/api_service.dart` to change the base URL:
```dart
static const String baseUrl = 'http://localhost/seens';
```

### Database Configuration
The app uses the existing database configuration from the PHP system. No changes needed if the PHP backend is properly configured.

## Security Features

- Token-based API authentication
- Input validation and sanitization
- Error handling and logging
- Secure image handling (base64 encoding)
- Permission-based feature access

## Troubleshooting

### Common Issues

1. **Connection Issues**
   - Ensure XAMPP is running
   - Check database connection in PHP backend
   - Verify API endpoints are accessible

2. **Camera Issues**
   - Check camera permissions
   - Ensure proper platform setup
   - Test on physical device (emulator may have limitations)

3. **NFC Issues**
   - NFC requires physical device
   - Check device NFC capabilities
   - Ensure proper permissions

4. **Image Upload Issues**
   - Check file size limits
   - Verify PHP upload settings
   - Ensure proper base64 encoding

## Development

### Adding New Features
1. Create/update models in `lib/models/`
2. Add API methods in `lib/services/api_service.dart`
3. Update state management in `lib/providers/`
4. Create UI components in `lib/screens/` or `lib/widgets/`

### Testing
```bash
flutter test
```

### Building for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Dependencies

Key Flutter packages used:
- `provider` - State management
- `http` & `dio` - HTTP client
- `qr_code_scanner` - QR code scanning
- `qr_flutter` - QR code generation
- `nfc_manager` - NFC/RFID support
- `image_picker` - Camera access
- `google_fonts` - Typography
- `shared_preferences` - Local storage

## Support

For issues and support:
1. Check the PHP backend is working correctly
2. Verify database connection and permissions
3. Review Flutter console logs for errors
4. Ensure all required permissions are granted

## Future Enhancements

- Offline mode support
- Push notifications for entry/exit alerts
- Advanced reporting and analytics
- Multi-language support
- Biometric authentication
- Real-time sync with WebSocket
