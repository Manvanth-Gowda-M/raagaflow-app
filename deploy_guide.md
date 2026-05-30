# Deploy Guide — Vercel & GitHub Releases Setup

This guide walks you through the quick steps to set up your public **GitHub Releases** link for your new high-fidelity Android APK, deploy the Web application to **Vercel**, and update your download links for a professional, premium user experience.

---

## Step 1: Upload APK to GitHub Releases

Since your high-fidelity Flutter APK is approximately **167 MB**, hosting it inside your Git repository exceeds Vercel's Hobby plan limit (100 MB). Hosting it on GitHub Releases is completely **free**, has a **2 GB limit**, and gives your users CDN-grade download speeds!

1. Create a public repository on GitHub (e.g., `raagaflow-app`).
2. Go to the **Releases** tab on the right sidebar and click **Create a new release** (or "Draft a new release").
3. Set your version tag (e.g., `v1.0.0`) and title (e.g., `Official Android Release v1.0.0`).
4. Drag and drop your compiled APK file from the build folder:
   `raagaflow/build/app/outputs/flutter-apk/app-release.apk`
5. Click **Publish release**.

---

## Step 2: Get your Direct APK Download Link

Once published, get the direct, raw download link for your APK:
1. Under your release, right-click the **app-release.apk** asset block.
2. Select **Copy Link Address**.
3. It will look like this:
   `https://github.com/<your-username>/<your-repo-name>/releases/latest/download/app-release.apk` (or containing your tag name, e.g. `/download/v1.0.0/app-release.apk`).

---

## Step 3: Update index.html with your Link

Open `raagaflow/web/index.html` and replace the placeholder `GITHUB_APK_URL` on line 231 with your actual direct download link:

```javascript
// Replace the placeholder with your actual direct APK link!
const GITHUB_APK_URL = "https://github.com/your-username/your-repo-name/releases/latest/download/app-release.apk";
```

*Note: Once you run `flutter build web --release`, this updated link will be compiled into the Web app automatically!*

---

## Step 4: Deploy to Vercel

### Method A: Git Integration (Recommended)
1. Push your local `raagaflow` codebase (including the custom `vercel.json` we created) to your GitHub repository.
2. Sign in to [Vercel](https://vercel.com) and click **Add New** -> **Project**.
3. Select your repository from the Git list.
4. Set the **Root Directory** to `raagaflow` (since your Flutter files are in that folder).
5. In the Build and Development Settings:
   - **Build Command**: `flutter/bin/flutter build web --release` (or leave it empty if you prefer deploying Method B).
   - **Output Directory**: `build/web`
6. Click **Deploy**!

### Method B: Deploying Pre-compiled Build (Vercel CLI)
If your Vercel pipeline does not have the Flutter SDK configured, you can build it locally and deploy the compiled folder instantly:
1. Open PowerShell in `raagaflow/` and compile the web files:
   ```powershell
   flutter build web --release
   ```
2. Make sure you have the Vercel CLI installed:
   ```powershell
   npm install -g vercel
   ```
3. Navigate into your compiled output folder:
   **Never run cd in terminal directly.** Simply run the `vercel` deploy command pointed at the output directory:
   ```powershell
   vercel --cwd build/web --prod
   ```
4. Follow the brief command line prompts. Vercel will deploy the pre-built folder directly with zero configuration, and your app will be live in 5 seconds!
