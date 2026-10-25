# NutriFit Sync (Lab 2)
flutter create . --platforms=android,ios,web   # run once inside this folder
flutter pub get
flutter run

Android: add <uses-permission android:name="android.permission.CAMERA"/> to AndroidManifest.xml.
iOS: add NSCameraUsageDescription and NSPhotoLibraryUsageDescription to Info.plist.
