# Deploying to Netlify with Supabase

## 1. Supabase stays running automatically

**Supabase Cloud** (what you use with `supabase.co`) is always running. You don’t start or stop it. Your project stays up as long as the project is active in your Supabase account. No extra steps needed for “keeping it running.”

---

## 2. Storing env keys in Netlify

Your app uses two **Vite** env vars (they must start with `VITE_` to be available in the browser):

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

**In Netlify:**

1. Open your site → **Site configuration** (or **Site settings**) → **Environment variables**.
2. Click **Add a variable** or **Add environment variables**.
3. Add:
   - **Key:** `VITE_SUPABASE_URL`  
     **Value:** `https://xxxxx.supabase.co` (your project URL from Supabase → Project Settings → API)
   - **Key:** `VITE_SUPABASE_ANON_KEY`  
     **Value:** your anon/public key from the same API page
4. Save. Optionally set **Scopes** to “All” or only “Production” (and “Deploy previews” if you want previews to use Supabase).
5. Trigger a new deploy (e.g. **Deploys** → **Trigger deploy** → **Deploy site**) so the new variables are used.

Never commit `.env` or real keys to git (your `.env` is already in `.gitignore`). Use Netlify’s env vars for production.

---

## 3. Email verification redirect (fix “Safari page not found” / localhost)

The “page not found” happens because the link in the verification email points to **localhost**. Supabase builds that link from:

- **Site URL**
- **Redirect URLs**

Configure both for your live site.

**In Supabase:**

1. Go to [Supabase Dashboard](https://app.supabase.com) → your project.
2. Open **Authentication** → **URL Configuration**.
3. Set:
   - **Site URL**  
     Your production URL, e.g. `https://your-site-name.netlify.app` (or your custom domain).
   - **Redirect URLs**  
     Add:
     - `https://your-site-name.netlify.app/**`
     - `https://your-site-name.netlify.app`
     - Keep `http://localhost:5173/**` (and similar) if you still develop locally.
4. Save.

**After this:**

- **New** sign-up emails will use the **Site URL** and redirect to your **live** Netlify site, so you’ll no longer get “Safari page not found” and land on the real app.
- Old emails that were already sent still contain localhost links; those won’t change. Users can request a new verification email or sign in again after you’ve gone live.

---

## 4. Optional: `netlify.toml`

A `netlify.toml` in the repo can make build and publish settings explicit. For a standard Vite SPA you can use:

```toml
[build]
  command = "npm run build"
  publish = "dist"
```

If you don’t add this, Netlify usually detects Vite and uses the same anyway.

---

## Checklist

- [ ] Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in Netlify environment variables.
- [ ] In Supabase: set **Site URL** to your Netlify URL (e.g. `https://your-site.netlify.app`).
- [ ] In Supabase: add your Netlify URL to **Redirect URLs** (e.g. `https://your-site.netlify.app/**`).
- [ ] Trigger a new deploy on Netlify after changing env vars.
- [ ] Test sign-up on the **live** site and confirm the verification email redirects to the live URL.
