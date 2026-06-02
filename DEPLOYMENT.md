# iPILA Deployment Guide

## What Gets Deployed Where

| Part | Platform | Notes |
|---|---|---|
| Admin Web Dashboard | Railway (via Docker) | Deployed from GitHub |
| Resident Mobile App | APK / Play Store | Built locally, distributed manually |

You can deploy early at any stage — Railway will always pull the latest code from GitHub.

---

## Part 1 — Deploy Admin Web to Railway

### Step 1: Push your project to GitHub

1. Go to https://github.com → New repository → name it `ipila`
2. Set it to **Private** (recommended for a government app)
3. In your terminal, inside the `ipila` folder:

```cmd
git init
git add .
git commit -m "initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/ipila.git
git push -u origin main
```

> If you already have a repo, just push your latest changes:
> ```cmd
> git add .
> git commit -m "update"
> git push
> ```

---

### Step 2: Create a Railway account

1. Go to https://railway.app
2. Sign up with your GitHub account (important — links them together)

---

### Step 3: Deploy on Railway

1. Railway Dashboard → **New Project**
2. Select **Deploy from GitHub repo**
3. Choose your `ipila` repository
4. Railway will auto-detect the `Dockerfile` and start building

> First build takes ~5-10 minutes (downloads Flutter SDK inside Docker)

---

### Step 4: Set the port

Railway needs to know which port to expose.

1. Go to your project → **Settings** → **Variables**
2. Add this variable:

```
PORT = 80
```

---

### Step 5: Get your public URL

1. Go to your project → **Settings** → **Networking**
2. Click **Generate Domain**
3. You'll get a URL like: `https://ipila-production.up.railway.app`

That's your live admin dashboard URL.

---

### Step 6: Auto-deploy on every push

Railway auto-deploys whenever you push to `main` by default. No extra setup needed.

Every time you run:
```cmd
git add .
git commit -m "your changes"
git push
```
Railway will automatically rebuild and redeploy.

---

## Part 2 — Build the Mobile APK

### Build a release APK

In your terminal inside the `ipila` folder:

```cmd
flutter build apk --release
```

The APK will be at:
```
ipila/build/app/outputs/flutter-apk/app-release.apk
```

Share this file directly to Android phones for testing (sideload).

---

### For Play Store (when ready)

```cmd
flutter build appbundle --release
```

Upload the `.aab` file to Google Play Console.

---

## Part 3 — Environment & Secrets

Your `firebase_options.dart` and `cloudinary_service.dart` contain API keys. Since the repo is **private**, this is acceptable for now.

For production, move sensitive values to Railway environment variables and load them at build time. But for a school/thesis project with a private repo, the current setup is fine.

---

## Checklist Before Deploying

- [ ] GitHub repo created and code pushed
- [ ] Railway account created (signed in with GitHub)
- [ ] New project created from GitHub repo
- [ ] PORT variable set to 80
- [ ] Domain generated
- [ ] First build successful (check build logs)
- [ ] Admin login works on the live URL
- [ ] Firebase rules allow authenticated access

---

## Troubleshooting

**Build fails on Railway:**
- Check build logs in Railway dashboard
- Most common issue: Flutter version mismatch — the Dockerfile uses `ghcr.io/cirruslabs/flutter:stable` which always pulls the latest stable Flutter

**White screen on the live URL:**
- Usually a routing issue — Flutter web needs the server to redirect all routes to `index.html`
- The current nginx config handles this automatically

**Firebase auth not working on live URL:**
- Go to Firebase Console → Authentication → Settings → Authorized domains
- Add your Railway domain: `ipila-production.up.railway.app`
