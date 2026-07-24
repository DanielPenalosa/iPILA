# Railway Deployment Guide - iPILA Flutter Web App

## Prerequisites
- GitHub account with iPILA repository
- New email address for fresh Railway trial
- Your Firebase configuration ready
- Cloudinary account details

---

## Step 1: Delete Old Railway Project (if applicable)

1. **Login to old Railway account**: https://railway.app/login
2. **Go to your project** (iPILA)
3. Click **Settings** tab (bottom left)
4. Scroll to **Danger Zone**
5. Click **Delete Project**
6. Type project name to confirm
7. **Logout** from Railway

---

## Step 2: Create New Railway Account

### Option A: New Email + GitHub
1. **Create new email** (e.g., Gmail, Outlook)
2. **Create new GitHub account** OR disconnect Railway from old GitHub
3. Go to https://railway.app
4. Click **"Start a New Project"** or **"Login"**
5. Choose **"Login with GitHub"**
6. Authorize Railway
7. ✅ You now have **$5 free trial credit**

### Option B: Different Login Method
1. Use **Google** or **Email** instead of GitHub
2. Railway may allow different login = new trial

---

## Step 3: Prepare Your Repository

### Push Latest Code (if not already done):
```bash
cd iPILA/ipila
git add .
git commit -m "Prepare for Railway deployment"
git push origin main
```

### Verify Required Files Exist:
- ✅ `Dockerfile` (root of ipila folder)
- ✅ `railway.toml` (configuration)
- ✅ `.dockerignore` (optional but recommended)

---

## Step 4: Create New Railway Project

1. **Login to new Railway account**: https://railway.app/login

2. **Click "New Project"**

3. **Choose "Deploy from GitHub repo"**
   - If first time: **"Configure GitHub App"**
   - Select **your GitHub account**
   - Choose **"Only select repositories"**
   - Select **"iPILA"** repository
   - Click **"Install & Authorize"**

4. **Select the iPILA repository**
   - Railway will show your repos
   - Click on **"iPILA"** or **"DanielPenalosa/iPILA"**

5. **Configure deployment**:
   - Railway will detect the repo
   - Click **"Deploy Now"** or **"Add variables"** first (recommended)

---

## Step 5: Configure Environment Variables

**IMPORTANT**: Add these BEFORE first deployment to avoid errors.

1. In your Railway project, click **"Variables"** tab
2. Click **"+ New Variable"**
3. Add each variable:

### Required Variables:

```bash
# Railway Configuration
PORT=8080

# Firebase Configuration (get from firebase_options.dart)
FIREBASE_API_KEY=your_api_key_here
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
FIREBASE_MEASUREMENT_ID=G-XXXXXXXXXX

# Cloudinary (if using for image uploads)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

**How to get Firebase values:**
- Open `lib/firebase_options.dart`
- Copy values from `FirebaseOptions` web configuration

---

## Step 6: Verify Configuration Files

### Check `Dockerfile`:
```dockerfile
# Use official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Clean and get dependencies
RUN flutter clean
RUN flutter pub get

# Build web app with release optimizations
RUN flutter build web --release --web-renderer html

# Use nginx to serve
FROM nginx:alpine
COPY --from=0 /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

### Check `railway.toml`:
```toml
[build]
builder = "DOCKERFILE"
dockerfilePath = "Dockerfile"

[deploy]
startCommand = "nginx -g 'daemon off;'"
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

### Check `nginx.conf`:
```nginx
server {
    listen 8080;
    server_name _;
    
    root /usr/share/nginx/html;
    index index.html;
    
    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript;
    
    location / {
        try_files $uri $uri/ /index.html;
        
        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Flutter web specific
    location ~* \.(?:json|html)$ {
        expires -1;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
    }
}
```

---

## Step 7: Deploy!

1. **Click "Deploy"** button in Railway
2. **Watch the build logs**:
   - Click on **"Deployments"** tab
   - Click on the **latest deployment**
   - View real-time logs

3. **Wait for build** (5-10 minutes first time):
   ```
   ✓ Building Docker image...
   ✓ Running flutter pub get...
   ✓ Building web release...
   ✓ Starting nginx...
   ✓ Deployment successful!
   ```

4. **Get your URL**:
   - Click **"Settings"** tab
   - Under **"Domains"**
   - You'll see: `your-app-name.up.railway.app`
   - Click **"Generate Domain"** if not auto-generated

---

## Step 8: Verify Deployment

1. **Open your Railway URL** in browser
2. **Check these work**:
   - ✅ Login page loads
   - ✅ Can create account (Firebase connected)
   - ✅ Images load (Cloudinary working)
   - ✅ Maps show properly
   - ✅ No console errors

3. **If issues**, check:
   - Railway **Logs** tab for errors
   - Browser **Console** (F12) for frontend errors
   - Environment variables are set correctly

---

## Step 9: Custom Domain (Optional)

1. **In Railway Settings** → **Domains**
2. Click **"Custom Domain"**
3. Add your domain: `ipila.yourmunicipality.gov.ph`
4. **Update DNS** at your domain provider:
   - Type: `CNAME`
   - Name: `ipila` (or `www`)
   - Value: `your-app.up.railway.app`
   - TTL: `3600`

5. Wait for DNS propagation (5-60 minutes)

---

## Step 10: Monitor & Maintain

### Check Usage:
- Railway dashboard shows:
  - **CPU usage**
  - **Memory usage**
  - **Network traffic**
  - **Build minutes used**

### $5 Trial Credit Includes:
- ~500 build minutes
- Plenty for development/testing
- Monitor in **"Usage"** tab

### When Trial Expires:
- Add payment method
- **Hobby Plan**: $5/month
- Pay only for what you use after

---

## Troubleshooting Common Issues

### Issue 1: Build Fails
**Error**: `Flutter build failed`
```bash
# Solution: Check Dockerfile
# Make sure flutter clean runs first
# Verify pubspec.yaml has all dependencies
```

### Issue 2: White Screen
**Error**: Blank page loads
```bash
# Solution: Check nginx.conf
# Verify web build completed
# Check browser console for errors
# Ensure Firebase config is correct
```

### Issue 3: 502 Bad Gateway
**Error**: Nginx not starting
```bash
# Solution: Check PORT environment variable
# Verify nginx.conf listens on correct port (8080)
# Check Railway logs for nginx errors
```

### Issue 4: Firebase Connection Failed
**Error**: Can't login/register
```bash
# Solution: Verify environment variables
# Check firebase_options.dart matches config
# Ensure Firebase project is active
# Check Firebase console for errors
```

### Issue 5: Images Not Loading
**Error**: Photos don't upload/display
```bash
# Solution: Check Cloudinary credentials
# Verify CORS settings in Cloudinary
# Check browser network tab for 403 errors
```

---

## Deployment Checklist

Before deploying, verify:

- [ ] Latest code pushed to GitHub
- [ ] `Dockerfile` exists and is correct
- [ ] `railway.toml` configured
- [ ] `nginx.conf` present
- [ ] Firebase project active
- [ ] Cloudinary account setup
- [ ] All environment variables ready
- [ ] New Railway account created
- [ ] Repository connected to Railway
- [ ] Environment variables added in Railway

After deployment:

- [ ] App loads successfully
- [ ] Login works
- [ ] Registration works
- [ ] Images upload
- [ ] Maps display
- [ ] Admin panel accessible
- [ ] No console errors
- [ ] Mobile responsive works
- [ ] Before/after photos show

---

## Quick Deploy Commands

If you need to redeploy after changes:

```bash
# 1. Make your changes locally
# 2. Commit and push
git add .
git commit -m "Your changes"
git push origin main

# 3. Railway auto-deploys!
# Or manually trigger in Railway dashboard
```

---

## Cost Breakdown

### Free Trial ($5 credit):
- **Lasts**: ~1 month light usage
- **Includes**: 
  - 500 build minutes
  - Unlimited bandwidth
  - Automatic SSL
  - Custom domains

### After Trial:
- **Hobby Plan**: $5/month base
- **Plus usage**:
  - ~$0.000006/MB RAM per hour
  - ~$10/TB bandwidth
- **Typical cost**: $5-10/month for small municipal app

---

## Support & Resources

- **Railway Docs**: https://docs.railway.app
- **Railway Discord**: https://discord.gg/railway
- **Flutter Web Docs**: https://docs.flutter.dev/platform-integration/web
- **Firebase Hosting Alternative**: Free option if Railway costs too much

---

## Notes

- Railway trial is **per account**, not per email
- Using new GitHub account may give new trial
- Keep your environment variables safe
- Railway may ask for payment method even during trial
- Monitor usage to avoid surprise charges
- Consider Firebase Hosting if Railway becomes expensive

---

Good luck with your deployment! 🚀
