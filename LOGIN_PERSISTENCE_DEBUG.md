# Login Persistence Testing Guide

## Problem
User reports that login persistence is not working - after logging in, closing the app, and reopening it, the app shows the login screen again instead of going directly to the home screen.

## Working Version
The user mentioned it was working "2 days ago in an older version of the app."

## Current Implementation
We're using Firebase Auth with the standard `authStateChanges()` stream in the `AuthWrapper` widget.

## Potential Causes

### 1. App Data Being Cleared
- Check if the app data is being cleared when closing
- Android might be clearing app cache in low memory situations

### 2. Firebase Auth Token Refresh Issue
- Tokens expire after a certain period
- Check if `authStateChanges()` is properly detecting persisted sessions

### 3. Navigation Context Issue
- The `StreamBuilder` in `AuthWrapper` might not be properly detecting the initial auth state

## Testing Steps

1. **Test Basic Persistence:**
   - Log in to the app
   - DO NOT log out
   - Force close the app (swipe from recents)
   - Reopen the app
   - **Expected:** Should go directly to HomePage
   - **If this fails:** Firebase Auth persistence is not working

2. **Test After Delay:**
   - Log in to the app
   - Wait 5 minutes
   - Close and reopen
   - Check if still logged in

3. **Check Firebase Console:**
   - Users > [your user] > Check if "Last sign-in" time updates
   - This confirms the authentication is happening

4. **Test on Different Device:**
   - Try on another Android device or emulator
   - Helps isolate if it's device-specific

## Firebase Console Settings to Check
There are **NO** Firebase Console settings that affect client-side persistence. Persistence is handled entirely on the client side.

## Debugging Code to Add

Add this to `_AuthWrapperState` to see what's happening:

```dart
@override
void initState() {
  super.initState();
  print('=== AUTH DEBUG ===');
  print('Current user on init: ${FirebaseAuth.instance.currentUser?.email ?? 'null'}');
  FirebaseAuth.instance.authStateChanges().listen((user) {
    print('Auth state changed: ${user?.email ?? 'null'}');
  });
}
```

## Possible Solutions

### Solution 1: Ensure Proper Initialization
Make sure Firebase is fully initialized before checking auth state.

### Solution 2: Use `userChanges()` instead of `authStateChanges()`
The `userChanges()` stream also triggers on token refresh, which might help.

### Solution 3: Cache Navigation State
Store a flag in SharedPreferences to remember if user was logged in.

### Solution 4: Check App Data Persistence
Ensure Android isn't  clearing app data on close due to memory pressure.

## Most Likely Cause
Based on the symptoms, the most likely cause is that `FirebaseAuth.instance.currentUser` is returning `null` on app restart, even though the user should still be authenticated. This could be due to:

1. Token refresh failing
2. Auth state not being properly persisted
3. Some change in the code that's preventing the auth state from being read correctly

## Next Steps
1. Add debug logging to see what's happening
2. Test on a clean app install vs upgrade
3. Check if clearing app data vs normal close makes a difference
