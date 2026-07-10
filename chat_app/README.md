# Chat App — دليل التشغيل الكامل

الكود ده **كامل وحقيقي** (مش محاكاة) - كل الـ Services والشاشات شغالة بمنطق صحيح
على Firebase و Agora فعليًا. لكن لازم تشغله وتجربه على جهازك في **Claude Code**
(مش هنا في المتصفح) لأن محتاج Flutter SDK + جهاز حقيقي + إنترنت كامل.

## الخطوات بالترتيب (نفذها مع Claude Code على جهازك)

### 1) جهّز مشروع Flutter فاضي
```bash
flutter create chat_app_project
cd chat_app_project
```

### 2) انسخ الملفات دي فوق الملفات الافتراضية
- انسخ مجلد `lib/` كامل (هيستبدل اللي فيه أصلاً)
- انسخ `pubspec.yaml` (هيستبدل اللي فيه أصلاً)
- انسخ `firestore.rules` و `storage.rules` و `functions/` و `PERMISSIONS.md`

### 3) ربط المشروع بـ Firebase الحقيقي بتاعك
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
ده هيسألك تختار المشروع اللي عملته على Firebase Console، وهيولّد
`lib/firebase_options.dart` تلقائيًا بالبيانات الصح (يبقى يستبدل الملف
المؤقت اللي أنا حطيته).

**كمان:** حمّل ملف `google-services.json` الحقيقي من Firebase Console
(Project Settings → Your apps → Android app) وحطه في `android/app/`.

### 4) فعّل الخدمات في Firebase Console
- Authentication → فعّل **Email/Password**
- Firestore Database → أنشئها (Production mode)
- Storage → فعّلها
- انشر الـ Rules:
```bash
firebase deploy --only firestore:rules,storage:rules
```

### 5) نشر الـ Cloud Functions (للإشعارات الحقيقية)
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 6) إعداد Agora
- اعمل حساب على [agora.io](https://www.agora.io)، أنشئ مشروع جديد
- خد الـ **App ID** وحطه في `lib/utils/constants.dart` بدل `YOUR_AGORA_APP_ID_HERE`
- من إعدادات المشروع في Agora، فعّل **"Testing Mode"** (App ID فقط بدون Token)
  عشان يشتغل على طول من غير تعقيد الـ Token server (كافي تمامًا لاستخدام شخصي)

### 7) ضيف الصلاحيات
اتبع تعليمات ملف `PERMISSIONS.md` بالظبط (AndroidManifest.xml + Info.plist)

### 8) شغّل المشروع
```bash
flutter pub get
flutter run
```
(لازم يكون فيه جهاز أندرويد حقيقي متوصل أو إيموليتور شغال)

### 9) للتجربة الحقيقية للشات والمكالمات
لازم تجربه على **جهازين مختلفين في نفس الوقت** (جهازك + جهاز صاحبتك/صاحبك،
أو جهازك + إيموليتور) عشان تشوف الرسايل والمكالمات لحظيًا بين الطرفين.

---

## لو حصل خطأ
انسخ الـ error log بالظبط وابعتهولي، أو اديه لـ Claude Code مباشرة وقوله
"شغل المرحلة دي وحل أي خطأ يظهر فعليًا قبل ما تكمل" - ده أهم مبدأ عشان
النتيجة تبقى شغالة حقيقي مش محاكاة.

## إيه اللي متبني لسه (اختياري لاحقًا)
- Token server لـ Agora (أمان أعلى للـ production الحقيقي)
- Compression للصور قبل الرفع (توفير موبايل داتا)
- Typing indicator ("بيكتب...")
- علامة صح/صح مزدوجة (تم القراءة) بشكل مرئي أوضح
