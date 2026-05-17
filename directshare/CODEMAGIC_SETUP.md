# Build DirectShare on Codemagic (No PC Power Needed!)

## What is Codemagic?
Codemagic builds your Flutter app in the cloud.
Your low-RAM PC just uploads code — Codemagic does the heavy building!

---

## Step 1 — Create GitHub Account
1. Go to https://github.com
2. Sign up free
3. Click "New Repository"
4. Name it: directshare
5. Click "Create Repository"

---

## Step 2 — Upload Your Code to GitHub
On your PC, open Command Prompt and run:

```
git init
git add .
git commit -m "DirectShare app"
git branch -M main
git remote add origin https://github.com/YOURNAME/directshare.git
git push -u origin main
```

Replace YOURNAME with your GitHub username.

---

## Step 3 — Sign Up on Codemagic
1. Go to https://codemagic.io
2. Click "Sign up with GitHub"
3. Authorize Codemagic to access your GitHub

---

## Step 4 — Add Your App
1. Click "Add application"
2. Select GitHub
3. Choose your "directshare" repository
4. Select "Flutter App (via codemagic.yaml)"
5. Click "Finish: Add application"

---

## Step 5 — Start Your First Build
1. Click "Start your first build"
2. Select workflow: "android-release"
3. Click "Start new build"
4. Wait 5-10 minutes
5. Download your APK!

---

## Free Tier Limits
- 500 build minutes free per month
- Enough for ~25 builds per month
- No credit card needed

---

## Download Your APK
After build completes:
1. Click on the build
2. Scroll to "Artifacts"
3. Download: app-debug.apk or app-release.apk
4. Install on your Android phone!

---

## Install APK on Android Phone
1. Copy APK to your phone
2. Go to Settings > Security
3. Enable "Unknown Sources" or "Install unknown apps"
4. Open the APK file
5. Tap Install
6. Enjoy DirectShare!
