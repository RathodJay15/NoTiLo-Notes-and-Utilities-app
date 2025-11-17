📒 NoTiLo – Smart, Secure & Minimal Notes App
A beautifully designed Flutter + Firebase application for creating, managing, and exporting notes with optional password-protected utilities. Designed with simplicity, speed, and cloud-sync in mind.

✨ Features
📝 Notes Management
- Create, edit, and delete notes
- Auto-save using Firebase
- Real-time sync across devices
- Clean UI with Poppins font
- Description field expands fully with top-aligned text
- Shows timestamps for every update

🗂 Organized Home Page
- Displays all notes from Firestore
- Smooth scrolling list
- Floating action button (FAB) to add notes instantly
- Tap any note to view/edit

🔐 Utility Page (Secure Info Storage)
- Store private data such as:
- Wi-Fi passwords
- Utility numbers
- Personal reminders
- Sensitive credentials

Includes:
-Edit & update features
-Firebase Auth protected access

📄 Export Notes as PDF
- Convert notes into professional-quality PDFs
- Works perfectly on:
  - 📱 Android
  - 🌐 Web
  - 🖥 Windows
- Saves directly to storage (Android) or triggers download (Web)

👤 Authentication
- Firebase Email/Password login
- Sign up, login, logout
- Stay Logged In feature (auto-login on app launch)

☁️ Cloud Sync
- All notes saved to Cloud Firestore
- Reliable, real-time updates
- No manual saving required

🛠 Tech Stack
- Flutter (Dart)
- Firebase Authentication
- Cloud Firestore
- PDF Generation (flutter_pdf / pdf package)
- Platform support: Android, Web, Windows

📦 Folder Structure (Simplified)
/lib
 ├─ home_page.dart
 ├─ note_page.dart
 ├─ utility_page.dart
 ├─ auth/
 ├─ widgets/
 ├─ services/
 └─ main.dart

🚀 How to Run
1️⃣ Clone the repo
git clone https://github.com/your-username/notilo.git
cd notilo

2️⃣ Install dependencies
flutter pub get

3️⃣ Configure Firebase
Add the Firebase config files:
- google-services.json → /android/app
- firebase-options (for web) → /web/index.html
- firebase_app_id_file.json → /ios (if using iOS)

4️⃣ Run the project
flutter run

📚 Usage Guide
➕ Create a Note
- Tap the + button
- Enter title & description
- Automatically saved to Firestore

✏️ Edit a Note
- Tap any note in the list
- Make changes
- Changes auto-sync to Firebase

🔐 Use Utility Page
- Add private info
- Update anytime
- Protected behind Firebase Auth

📄 Export PDF
- Open any note
- Tap the PDF icon
- Save/download the generated file

🎨 App Design
- Minimal white interface
- Black text with clean Poppins font
- Gray buttons (#5C5C5C)
- Focus on clarity + simplicity

🤝 Contributing

Pull requests and feature suggestions are welcome!
Feel free to fork and improve.

📜 License

This project is available under the MIT License.

❤️ Support

If you like this project, don’t forget to ⭐ the repo!
