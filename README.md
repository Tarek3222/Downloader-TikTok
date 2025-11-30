# 📱 TikTok Downloader

A modern Flutter application that allows you to download TikTok videos easily and efficiently. Built with a clean, intuitive interface and support for both Arabic and English languages.

![TikTok Downloader](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Version](https://img.shields.io/badge/version-1.0.0-blue?style=for-the-badge)

## ✨ Features

- 📥 **Download TikTok Videos** - Simply paste the TikTok link and download
- 🎨 **Multiple Themes** - Choose from TikTok Pink, Ocean Blue, and Emerald color themes
- 🌓 **Dark/Light Mode** - System, light, and dark mode support
- 🌍 **Multi-language Support** - Available in Arabic and English
- 📁 **Download History** - View and manage all your downloaded videos
- 🎯 **Clean UI** - Modern and user-friendly interface
- 💾 **Organized Storage** - Easy access to downloads folder
- 🔄 **Shake to Refresh** - Shake your device to refresh the download list

## 📸 Screenshots

<div align="center">
  <img src="https://github.com/Tarek3222/Downloader-TikTok/blob/main/assets/app_images/WhatsApp%20Image%202025-08-25%20at%2017.55.00_d249f4b3.jpg" width="250" alt="Main Screen"/>
  <img src="https://github.com/Tarek3222/Downloader-TikTok/blob/main/assets/app_images/WhatsApp%20Image%202025-08-25%20at%2017.55.00_56ddf9bf.jpg" width="250" alt="Settings"/>
  <img src="https://github.com/Tarek3222/Downloader-TikTok/blob/main/assets/app_images/WhatsApp%20Image%202025-08-25%20at%2017.54.59_bfc0a87f.jpg" width="250" alt="Downloads"/>
</div>

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android SDK for Android development
- Xcode for iOS development (Mac only)

### Installation

1. Clone the repository
```bash
git clone https://github.com/Tarek3222/Downloader-TikTok.git
cd Downloader-TikTok
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## 📦 Dependencies

This project uses the following main packages:

- `http` - For API requests
- `path_provider` - For accessing device storage
- `permission_handler` - For handling storage permissions
- `share_plus` - For sharing downloaded videos
- `url_launcher` - For opening URLs
- `flutter_localizations` - For multi-language support

## 🎨 Themes

The app includes three beautiful color themes:

1. **TikTok Pink** - Classic TikTok inspired theme with vibrant pink accents
2. **Ocean Blue** - Calm and professional blue theme
3. **Emerald** - Fresh and modern green theme

## 🌍 Localization

Currently supported languages:
- 🇸🇦 Arabic (العربية)
- 🇬🇧 English

## 🛠️ Built With

- **Flutter** - UI framework
- **Dart** - Programming language
- **Material Design** - Design system

## 📱 How to Use

1. Open the TikTok app and copy the video link
2. Open TikTok Downloader
3. Paste the link in the input field
4. Tap the "Download" button
5. Wait for the download to complete
6. Access your video from the downloads list or downloads folder

## 🔐 Permissions

The app requires the following permissions:

- **Storage Permission** - To save downloaded videos
- **Internet Permission** - To fetch video data from TikTok

## 📝 Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # App screens
│   ├── home_screen.dart
│   ├── settings_screen.dart
│   └── downloads_screen.dart
├── widgets/                  # Reusable widgets
├── models/                   # Data models
├── services/                 # API and download services
├── utils/                    # Helper functions
└── l10n/                     # Localization files
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Developer

**Tarek Ahmed**

- GitHub: [@Tarek3222](https://github.com/Tarek3222)

## 🙏 Acknowledgments

- Thanks to all contributors who have helped with this project
- Inspired by the need for a simple, efficient TikTok video downloader
- Built with ❤️ using Flutter

## ⚠️ Disclaimer

This app is for educational purposes only. Please respect content creators' rights and TikTok's terms of service. Always ensure you have permission to download and use content.

## 📧 Contact

If you have any questions or suggestions, feel free to reach out:

- Create an issue on GitHub
- Contact via GitHub profile

---

<div align="center">
  Made with ❤️ by Tarek Ahmed
  
  ⭐ Star this repository if you found it helpful!
</div>
