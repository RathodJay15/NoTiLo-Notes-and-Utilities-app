# NoTiLo App - Change Log

## Version 1.1.0 - Security & UX Enhancement (2025-11-27)

### 🔐 Encryption Feature
**Important Security Update**

All sensitive data is now encrypted before storing in Firebase:

#### What's Encrypted:
- ✅ **Notes**: Description field (title remains unencrypted for searching)
- ✅ **Login Utilities**: Username and Password fields (title remains unencrypted)
- ✅ **Simple Utilities**: No encryption needed (only stores titles and URLs)

#### Encryption Details:
- Uses XOR cipher with user's Firebase UID as the key
- Automatic encryption on save
- Automatic decryption on load
- Backward compatible: handles both encrypted and non-encrypted data gracefully

**Files Modified:**
- `lib/encryption_helper.dart` ✨ NEW FILE
- `lib/note_page.dart` - Added encryption for descriptions
- `lib/login_utility_page.dart` - Added encryption for username and password

### 💾 Smart Save Behavior
**Improved User Experience**

The app now intelligently decides when to prompt for save confirmation:

#### For NEW Items (Create Mode):
- **Prompt**: Shows "Save or Discard" dialog when exiting
- **User Choice**: User can choose to save or discard changes
- **Applies to**: New notes, new simple utilities, new login utilities

#### For EXISTING Items (Edit Mode):
- **Auto-save**: Automatically saves changes when exiting
- **No Prompt**: Seamless editing experience
- **Applies to**: Existing notes, existing simple utilities, existing login utilities

**Files Modified:**
- `lib/note_page.dart` - Smart save for notes
- `lib/login_utility_page.dart` - Smart save for login utilities
- `lib/simple_utility_page.dart` - Smart save for simple utilities

---

## Version 1.0.0 - Major Update (Previous)

## New Firebase Data Structure

### Updated Firestore Hierarchy

```
Firestore Database
│
└── 📁 users (Collection)
    │
    └── 📄 {userId} (Document - Firebase Auth UID)
        ├── username: "string"
        ├── email: "string"
        │
        ├── 📁 notes (Collection)
        │   └── 📄 {noteId} (Document)
        │       ├── title: String
        │       ├── description: String
        │       ├── secured: Boolean (NEW - password protection)
        │       └── updatedAt: Timestamp
        │
        ├── 📁 simpleUtilities (Collection - NEW)
        │   └── 📄 {utilityId} (Document)
        │       ├── title: String
        │       ├── url: String
        │       └── createdAt: Timestamp
        │
        └── 📁 loginUtilities (Collection - RENAMED from "utilities")
            └── 📄 {utilityId} (Document)
                ├── title: String (NEW)
                ├── url: String
                ├── usernameOrEmail: String
                ├── password: String
                └── createdAt: Timestamp
```

---

## Key Changes

### 1. **Notes Collection** (Enhanced)
**File:** `lib/note_page.dart`

#### New Features:
- ✅ **Password Protection**: Notes can be secured with user's login password
- ✅ Lock icon appears on secured notes in the list
- ✅ Password verification required to open secured notes
- ✅ Toggle protection with lock/unlock icon in app bar

#### Data Fields:
- `title`: String (editable)
- `description`: String (editable)
- `secured`: Boolean (password protected flag)
- `updatedAt`: Timestamp

#### Search:
- Searches by **title** field

---

### 2. **Simple Utilities Collection** (NEW)
**File:** `lib/simple_utility_page.dart`

#### Purpose:
Lightweight utility for storing quick links without login credentials.

#### Features:
- ✅ Title/Name field for easy identification
- ✅ URL field to store web links
- ✅ Direct "Open URL" button (no copy functionality)
- ✅ Clean, simple interface

#### Data Fields:
- `title`: String (searchable)
- `url`: String
- `createdAt`: Timestamp

#### Search:
- Searches by **title** field

---

### 3. **Login Utilities Collection** (RENAMED & Enhanced)
**File:** `lib/login_utility_page.dart`

#### Previous State:
- Was named `UtilityPage`
- Stored in "utilities" collection
- No title field

#### Changes:
- ✅ Renamed class to `LoginUtilityPage`
- ✅ Added **title/name** field for better organization
- ✅ Changed collection name to **"loginUtilities"**
- ✅ Password field remains protected (requires login password to view)
- ✅ Username/Email can be copied to clipboard
- ✅ "Open URL" functionality

#### Data Fields:
- `title`: String (NEW - searchable)
- `url`: String
- `usernameOrEmail`: String (copyable)
- `password`: String (hidden, requires verification)
- `createdAt`: Timestamp

#### Search:
- Searches by **title** field

---

## Home Page Updates

**File:** `lib/home_page.dart`

### Navigation Bar (3 Tabs):
1. **Notes** (First tab)
   - Icon: 📝 note
   - Shows all notes with lock icons for secured items
   
2. **Simple Utility** (Second tab)
   - Icon: 🔗 link
   - Shows simple URL utilities
   
3. **Login Utility** (Third tab)
   - Icon: 🔐 login
   - Shows login credentials utilities

### Search Functionality:
- ✅ **Separate search bar for each tab**
- ✅ Search persists only within active tab
- ✅ Search resets when switching tabs
- ✅ All searches use the **title/name** field

### Add Button:
- Context-aware: Shows appropriate dialog based on current tab
- Tab 0: "New Note"
- Tab 1: "New Simple Utility"
- Tab 2: "New Login Utility"

---

## Security Features

### 1. Password-Protected Notes
- Users can mark notes as "secured"
- Opening secured notes requires re-authentication with login password
- Lock icon (🔒) appears on card for visual indication

### 2. Login Utility Passwords
- Passwords remain hidden by default
- Viewing requires re-authentication with login password
- Auto-hide after 30 seconds for security
- Password field locked when editing existing utilities

---

## Account Deletion Updates
Updated to delete all three collections:
1. Delete all **notes**
2. Delete all **simpleUtilities**
3. Delete all **loginUtilities**
4. Delete user document
5. Delete Firebase Auth account

---

## File Structure

```
lib/
├── main.dart                   (unchanged)
├── login_page.dart            (unchanged)
├── registration_page.dart     (unchanged)
├── home_page.dart             ✨ COMPLETELY REWRITTEN
├── note_page.dart             ✨ ENHANCED (password protection)
├── simple_utility_page.dart   ✨ NEW FILE
└── login_utility_page.dart    ✨ RENAMED & ENHANCED (was utility_page.dart)
```

---

## Migration Notes

### For Existing Users:
If you have existing data in the old "utilities" collection, you may need to:
1. **Manually migrate** data from `utilities` to `loginUtilities`
2. **Add title field** to existing documents (can be auto-generated from URL)

### Migration Script (Optional):
```dart
// Run this once to migrate old utilities to loginUtilities
final userDoc = FirebaseFirestore.instance.collection("users").doc(userId);

// Get old utilities
final oldUtilities = await userDoc.collection("utilities").get();

// Copy to new collection with title
for (var doc in oldUtilities.docs) {
  await userDoc.collection("loginUtilities").add({
    'title': doc['url'].split('.')[0], // Extract domain as title
    'url': doc['url'],
    'usernameOrEmail': doc['usernameOrEmail'],
    'password': doc['password'],
    'createdAt': doc['createdAt'],
  });
}

// Optional: Delete old collection documents
for (var doc in oldUtilities.docs) {
  await doc.reference.delete();
}
```

---

## Testing Checklist

- [ ] Create new notes
- [ ] Toggle password protection on notes
- [ ] Open secured notes (verify password prompt)
- [ ] Search notes by title
- [ ] Create simple utilities
- [ ] Open URLs from simple utilities
- [ ] Search simple utilities by title
- [ ] Create login utilities with title
- [ ] View password in login utility (verify authentication)
- [ ] Copy username from login utility
- [ ] Search login utilities by title
- [ ] Switch between tabs (verify search resets)
- [ ] Delete items from each collection
- [ ] Delete account (verify all collections cleared)

---

## Summary of Benefits

1. **Better Organization**: Three distinct collections for different use cases
2. **Enhanced Search**: Searchable titles for all types
3. **Improved Security**: Password protection for sensitive notes
4. **Cleaner UX**: Separate tabs with context-aware actions
5. **Simpler Utilities**: Quick link storage without unnecessary fields
6. **Maintained Security**: Login utilities still require authentication for passwords

---

**Created:** 2025-11-27
**Author:** Antigravity AI Assistant
