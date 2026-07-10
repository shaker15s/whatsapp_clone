# صلاحيات لازم تضيفها يدويًا

## Android — `android/app/src/main/AndroidManifest.xml`
ضيف السطور دي جوه `<manifest>` وقبل `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

كمان في `android/app/build.gradle`:
- `minSdkVersion` لازم يبقى **21** على الأقل (Agora محتاجه).

## iOS — `ios/Runner/Info.plist`
ضيف السطور دي جوه `<dict>`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>محتاجين الميكروفون عشان المكالمات والرسايل الصوتية</string>
<key>NSCameraUsageDescription</key>
<string>محتاجين الكاميرا عشان مكالمات الفيديو</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>محتاجين موقعك عشان تقدر تبعته في الشات</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>محتاجين نوصل لصورك عشان تبعتها في الشات</string>
```
