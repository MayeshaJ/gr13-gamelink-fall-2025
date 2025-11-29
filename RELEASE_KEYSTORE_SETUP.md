# Release Keystore Setup Guide

This guide will help you set up a release keystore for signing your Android app and get the SHA-1 fingerprint for Firebase.

## Step 1: Create a Release Keystore

Run this command in the `android` directory. **Replace the values in brackets with your own:**

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted to enter:
- **Keystore password**: Choose a strong password (save this securely!)
- **Key password**: You can use the same password or a different one (save this securely!)
- **Your name/company**: Your name or company name
- **Organizational Unit**: (optional)
- **Organization**: (optional)
- **City/Locality**: Your city
- **State/Province**: Your state/province
- **Country code**: Two-letter country code (e.g., CA, US)

⚠️ **IMPORTANT**: 
- Keep your keystore file (`upload-keystore.jks`) and passwords safe
- If you lose the keystore or passwords, you won't be able to update your app on Google Play
- The keystore file is already in `.gitignore` (it won't be committed to git)

## Step 2: Create key.properties File

1. Copy the template:
   ```bash
   cd android
   cp key.properties.template key.properties
   ```

2. Edit `key.properties` and fill in your actual passwords:
   ```
   storePassword=YOUR_ACTUAL_KEYSTORE_PASSWORD
   keyPassword=YOUR_ACTUAL_KEY_PASSWORD
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

⚠️ **IMPORTANT**: The `key.properties` file is in `.gitignore` and won't be committed to git.

## Step 3: Get the SHA-1 Fingerprint from Release Keystore

After creating the keystore, run this command to get the SHA-1:

```bash
cd android
keytool -list -v -keystore upload-keystore.jks -alias upload
```

Enter your keystore password when prompted, then look for the SHA1 line in the output.

## Step 4: Add SHA-1 to Firebase

1. Copy the SHA-1 fingerprint (it looks like: `AA:BB:CC:DD:EE:...`)
2. Go to Firebase Console → Project Settings → Your apps
3. Find your Android app
4. Click "Add fingerprint"
5. Paste the SHA-1 and save

## Step 5: Configure build.gradle.kts (Already Done)

The build configuration has been updated to use the release keystore when building release versions of your app.

## Quick Commands Summary

**Create keystore:**
```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Get SHA-1:**
```bash
cd android
keytool -list -v -keystore upload-keystore.jks -alias upload
```

**Get SHA-1 (automated, no password prompt):**
```bash
cd android
keytool -list -v -keystore upload-keystore.jks -alias upload -storepass YOUR_KEYSTORE_PASSWORD
```

