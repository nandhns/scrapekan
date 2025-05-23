# ScrapeKan - Waste Management App

A Flutter application for waste management and composting, featuring role-based access, real-time monitoring, and analytics.

## Features

- Role-based authentication (Citizens, Vendors, Farmers, Admins, Municipal Officers)
- Real-time waste collection tracking with Google Maps integration
- QR code-based waste logging system
- Analytics dashboard with waste statistics and CO2 savings
- Machine monitoring for composting equipment
- Fertilizer request and delivery management
- Points-based reward system

## Prerequisites

- Flutter SDK (2.5.0 or higher)
- Dart SDK (2.14.0 or higher)
- Android Studio / VS Code
- Firebase account
- Google Maps API key

## Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/scrapekan.git
cd scrapekan
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and add the `google-services.json` file to `android/app/`
   - Download and add the `GoogleService-Info.plist` file to `ios/Runner/`

4. Configure Google Maps:
   - Get a Google Maps API key from the Google Cloud Console
   - Add the API key to `android/local.properties`:
     ```
     MAPS_API_KEY=your_api_key_here
     ```
   - For iOS, add the API key to `ios/Runner/AppDelegate.swift`

5. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── models/          # Data models
├── screens/         # UI screens for different roles
│   ├── admin/      # Admin-specific screens
│   ├── farmer/     # Farmer-specific screens
│   └── municipal/  # Municipal officer screens
├── services/        # Business logic and API services
└── widgets/        # Reusable UI components
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for the backend services
- All contributors who help improve the app
