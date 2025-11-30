📒 NoTiLo – Smart, Secure & Minimal Notes App
A beautifully designed Flutter + Firebase application for creating, managing, and exporting notes with optional password-protected utilities. Designed with simplicity, speed, and cloud-sync in mind.

✨ Features
📝 Notes Management
- Create, edit, and delete notes with rich text formatting
- Password-protected notes with custom passwords
- Auto-save using Firebase
- Real-time sync across devices
- Clean UI with Poppins font
- Shows timestamps for every update
- Export notes as PDF or TXT

🗂 Organized Home Page
- Displays all notes from Firestore
- Smooth scrolling list
- Search functionality for notes
- Floating action button (FAB) to add notes instantly
- Tap any note to view/edit

🛡️ Simple Utilities
- Quick-access links and utilities
- Encrypted storage for sensitive URLs
- Easy management and organization

🔐 Login Utilities (Secure Credentials Manager)
- Store Wi-Fi passwords, login credentials, and sensitive data
- AES encryption with user UID-based keys
- Password-protected access with re-authentication
- Auto-hide passwords after 30 seconds for security
- Encrypted storage in Cloud Firestore

👤 Authentication
- Firebase Email/Password login & registration
- Sign up, login, logout
- "Stay Logged In" feature (auto-login on app launch)
- Secure password reset via email
- Account deletion with data cleanup

☁️ Cloud Sync
- All notes saved to Cloud Firestore
- Reliable, real-time updates
- No manual saving required

🛠 Tech Stack
- **Frontend:** Flutter (Dart)
- **Backend:** Firebase Authentication & Cloud Firestore
- **Encryption:** XOR-based encryption with user UID keys
- **PDF/Export:** flutter_pdf, pdf, universal_html packages
- **Rich Text:** flutter_quill for advanced note editing
- **Platform support:** Android, iOS, macOS, Web, Windows

📦 Folder Structure
```
lib/
├─ main.dart                    # App entry point & auth wrapper
├─ home_page.dart              # Main dashboard with tabs
├─ note_page.dart              # Rich text note editor
├─ simple_utility_page.dart    # URL utilities
├─ login_utility_page.dart     # Encrypted credentials manager
├─ login_page.dart             # Login screen
├─ registration_page.dart      # Sign up screen
├─ encryption_helper.dart      # Encryption utilities
├─ firebase_options.dart       # Firebase config
└─ services/
   └─ auth_service.dart        # Firebase auth & "Stay Logged In"
```

🚀 How to Run
1️⃣ Clone the repo
git clone https://github.com/your-username/notilo.git
cd notilo

2️⃣ Install dependencies
flutter pub get

3️⃣ Configure Firebase
Add the Firebase config files (these are in .gitignore for security):
- `android/app/google-services.json` (Android)
- `ios/Runner/GoogleService-Info.plist` (iOS)
- `macos/Runner/GoogleService-Info.plist` (macOS)
- `web/firebase-config.js` (Web)

Then run Firebase initialization for your project.

4️⃣ Run the project
flutter run

📚 Usage Guide
➕ **Create a Note**
- Tap the + button on the Notes tab
- Enter title & use rich text editor for description
- Add optional password protection
- Automatically saved to Firestore

✏️ **Edit a Note**
- Tap any note in the list
- Make changes in real-time
- Changes auto-sync to Firebase
- For existing notes: auto-save on back

🔐 **Manage Login Utilities**
- Tap the Login Utilities tab
- Add Wi-Fi passwords, credentials, etc.
- Passwords are encrypted with your user ID
- Re-authenticate to view stored passwords
- Passwords auto-hide after 30 seconds for security

🛡️ **Manage Simple Utilities**
- Tap the Simple Utilities tab
- Add quick links and utility names
- Edit or delete as needed

📄 **Export Notes**
- Open any note
- Tap the export icon
- Choose format (PDF or TXT)
- File saves to device storage or downloads

🎨 **App Design**
- Clean, minimal white interface
- Dark gray accent color (#5C5C5C)
- Poppins font throughout
- Intuitive bottom navigation
- Smooth transitions and animations

🔒 **Security**
- Firebase Authentication (email/password)
- Encrypted credential storage
- Optional password-protected notes
- No hardcoded secrets in repo (Firebase config in .gitignore)
- User data isolated by UID

🤝 Contributing

Pull requests and feature suggestions are welcome!
Feel free to fork and improve.

📜 License

This project is available under the MIT License.

❤️ Support

If you like this project, don’t forget to ⭐ the repo!
