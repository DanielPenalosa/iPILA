# Railway Deployment Guide - iPILA Flutter Web App

Complete step-by-step guide to deploy iPILA to Railway from scratch.

## Prerequisites

✅ GitHub account with iPILA repository
✅ Railway account (you'll create this)
✅ Valid payment method (for Railway Hobby plan - $5/month)
✅ Firebase project already set up
✅ Cloudinary account for image uploads

---

## Part 1: Create Railway Account & Add Payment

### Step 1: Sign Up for Railway

1. **Go to Railway**: https://railway.app/
2. **Click "Login"** in top-right corner
3. **Sign in with GitHub**:
   - Click "Login with GitHub"
   - Authorize Railway to access your GitHub account
   - Grant necessary permissions

### Step 2: Add Payment Method

1. **Click your profile icon** (top-right)
2. **Select "Account Settings"**
3. **Go to "Billing" tab**
4. **Click "Add Payment Method"**
5. **Enter your credit/debit card details**:
   - Card number
   - Expiration date
   - CVV
   - Billing address
6. **Save payment method**

### Step 3: Choose Hobby Plan

1. **Still in Billing tab**
2. **Select "Hobby Plan"** ($5/month)
3. **Confirm subscription**
4. You'll get:
   - $5/month flat fee
   - $5 usage credit included
   - Additional usage billed monthly

---

## Part 2: Create New Railway Project

### Step 4: Create Project

1. **Go to Railway Dashboard**: https://railway.app/dashboard
2. **Click "New Project"** button
3. **Select "Deploy from GitHub repo"**
4. **Authorize GitHub** if prompted
5. **Select your repository**:
   - Search for "iPILA" or "DanielPenalosa/iPILA"
   - Click on the repository

### Step 5: Configure Project Settings

1. **Project will be created** with your repo connected
2. **Click on the service** that was created
3. **Go to "Settings" tab**

---

## Part 3: Configure Build Settings

### Step 6: Set Root Directory

1. **In Settings tab**, scroll to **"Root Directory"**
2. **Click "Configure"**
3. **Enter**: `ipila`
4. **Save changes**

### Step 7: Configure Build Command (Optional)

Railway will auto-detect the Dockerfile, but you can customize:

1. **Scroll to "Build"** section
2. **Builder**: Should show "Dockerfile" (auto-detected)
3. Leave as default - Railway will use your Dockerfile

### Step 8: Set Start Command (Optional)

1. **Scroll to "Deploy"** section
2. **Start Command** should be auto-detected from Dockerfile
3. If needed, it should be: `nginx -g 'daemon off;'`

---

## Part 4: Environment Variables (If Needed)

Your app uses Firebase (no environment variables needed for frontend), but you can add any if required:

### Step 9: Add Environment Variables (Optional)

1. **Go to "Variables" tab**
2. **Click "Add Variable"**
3. **Add any required variables**:
   - Example: `FLUTTER_ENV=production`
4. **Save**

> **Note**: Since you're using Firebase and Cloudinary with client-side SDKs, no backend environment variables are needed!

---

## Part 5: Deploy Application

### Step 10: Trigger Deployment

1. **Go to "Deployments" tab**
2. **Click "Deploy"** button
3. **Or**: Make a git push to trigger auto-deployment

```bash
# Make a small change to trigger deployment
cd ipila
git add .
git commit -m "trigger railway deployment"
git push origin main
```

### Step 11: Monitor Build Process

1. **Watch the build logs** in Railway dashboard
2. **Build process**:
   - ✓ Cloning repository
   - ✓ Installing Flutter SDK
   - ✓ Running `flutter build web`
   - ✓ Building Docker image
   - ✓ Starting Nginx server
3. **Wait 5-10 minutes** for first build

### Step 12: Check Deployment Status

1. **Build should complete successfully**
2. **Status should show**: "Active" or "Success"
3. **Green checkmark** indicates successful deployment

---

## Part 6: Access Your Deployed App

### Step 13: Get Railway URL

1. **In your Railway service**, go to **"Settings"**
2. **Scroll to "Networking"** section
3. **Click "Generate Domain"**
4. **Copy the generated URL**: `your-app-name.up.railway.app`

### Step 14: Test Your Application

1. **Open the Railway URL** in browser
2. **Test key features**:
   - ✓ Login/Register
   - ✓ Submit report
   - ✓ View reports
   - ✓ Admin dashboard
   - ✓ Before/after photos

---

## Part 7: Custom Domain (Optional)

### Step 15: Add Custom Domain

1. **In Settings → Networking**
2. **Click "Custom Domain"**
3. **Enter your domain**: `ipila.yourdomain.com`
4. **Railway provides DNS records**:
   - Add CNAME record to your DNS provider
   - Point to Railway's provided target

### Step 16: Configure DNS

1. **Go to your domain provider** (GoDaddy, Namecheap, etc.)
2. **Add CNAME record**:
   - Name: `ipila` (or `www`)
   - Value: `your-app.up.railway.app`
   - TTL: Auto or 3600
3. **Save DNS settings**
4. **Wait 5-60 minutes** for DNS propagation

---

## Part 8: Enable Auto-Deployments

### Step 17: Configure GitHub Integration

1. **In Settings tab**
2. **Scroll to "Source"**
3. **Ensure "Production Branch"** is set to `main`
4. **Enable "Auto-deploy"** (should be on by default)

Now every `git push` to main branch will trigger automatic deployment! 🚀

---

## Part 9: Monitoring & Logs

### Step 18: View Application Logs

1. **Go to "Deployments" tab**
2. **Click on latest deployment**
3. **View logs**:
   - Build logs
   - Runtime logs
   - Error messages

### Step 19: Check Metrics

1. **Go to "Metrics" tab**
2. **Monitor**:
   - CPU usage
   - Memory usage
   - Network traffic
   - Request count

---

## Part 10: Troubleshooting

### Common Issues & Solutions

#### Issue 1: Build Fails
**Solution:**
- Check build logs for errors
- Ensure Dockerfile is correct
- Verify root directory is set to `ipila`

#### Issue 2: White Screen on Load
**Solution:**
- Check browser console for errors
- Verify Firebase configuration
- Check if base href is correct in `web/index.html`

#### Issue 3: Images Not Loading
**Solution:**
- Verify Cloudinary credentials
- Check network tab for failed requests
- Ensure CORS is enabled on Cloudinary

#### Issue 4: "Out of Memory" Error
**Solution:**
- Railway Hobby plan has 512MB memory
- Optimize Flutter build: `flutter build web --release`
- Check for memory leaks in code

---

## Cost Breakdown

### Railway Hobby Plan Pricing

- **Monthly Base**: $5/month
- **Includes**: $5 usage credit
- **Additional Usage**:
  - CPU: ~$0.000463/minute
  - Memory: ~$0.000231/GB/minute
  - Network: Free egress

**Typical Monthly Cost**: $5-10/month for small app

### Tips to Reduce Costs

1. **Optimize Docker image size**
2. **Use efficient caching**
3. **Monitor resource usage**
4. **Set up alerts** for high usage

---

## Updating Your App

### Deploy New Changes

```bash
# Make your code changes
git add .
git commit -m "your changes description"
git push origin main

# Railway will automatically:
# 1. Detect the push
# 2. Build new Docker image
# 3. Deploy update
# 4. Zero-downtime deployment
```

### Rollback to Previous Version

1. **Go to "Deployments" tab**
2. **Find previous successful deployment**
3. **Click "•••" menu**
4. **Select "Redeploy"**

---

## Health Checks

### Monitor App Health

Railway automatically monitors your app:
- ✓ HTTP health checks
- ✓ Auto-restart on crashes
- ✓ Email notifications on failures

### Set Up Custom Health Check (Optional)

1. **Settings → Health Check**
2. **Add custom endpoint**: `/health`
3. **Set interval and timeout**

---

## Backup & Disaster Recovery

### Your Data is Safe

- **Firebase**: All data stored in Firebase (separate from Railway)
- **Cloudinary**: All images stored in Cloudinary
- **Railway**: Only hosts the static web files
- **No data loss risk**: Redeploying just rebuilds the frontend

### Backup Strategy

1. **GitHub**: Source code backup
2. **Firebase**: Enable daily backups in Firebase Console
3. **Cloudinary**: Images are permanently stored

---

## Performance Optimization

### Recommended Settings

1. **Enable HTTP/2** (automatic with Railway)
2. **Compression** (handled by Nginx in your Dockerfile)
3. **Caching headers** (configured in nginx.conf)
4. **CDN** (Railway uses Cloudflare CDN automatically)

---

## Security Best Practices

### Secure Your Deployment

1. ✅ **HTTPS enabled** (automatic with Railway)
2. ✅ **Firebase Security Rules** configured
3. ✅ **Cloudinary access** secured
4. ✅ **No secrets in code** (all in Firebase)
5. ✅ **Regular updates** via git push

---

## Support & Help

### If You Need Help

1. **Railway Discord**: https://discord.gg/railway
2. **Railway Docs**: https://docs.railway.app
3. **Railway Status**: https://status.railway.app
4. **Support Email**: team@railway.app

---

## Summary Checklist

Before going live, ensure:

- [ ] Railway account created with payment
- [ ] Project deployed successfully
- [ ] Custom domain configured (optional)
- [ ] Firebase connected and working
- [ ] Cloudinary images uploading
- [ ] All features tested
- [ ] Auto-deployments enabled
- [ ] Monitoring set up
- [ ] Backup strategy in place

---

## Your Deployment URLs

After deployment, your app will be available at:

- **Railway URL**: `https://ipila-production.up.railway.app` (or similar)
- **Custom Domain**: `https://ipila.yourdomain.com` (if configured)

---

## Next Steps After Deployment

1. ✅ Test all features thoroughly
2. ✅ Share URL with team/users
3. ✅ Monitor performance and errors
4. ✅ Set up Google Analytics (optional)
5. ✅ Configure SEO metadata
6. ✅ Submit to search engines

---

## Congratulations! 🎉

Your iPILA app is now live on Railway!

**Questions?** Check the troubleshooting section or Railway's documentation.

**Happy Deploying!** 🚀
