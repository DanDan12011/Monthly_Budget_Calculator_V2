# month-budg

This template should help get you started developing with Vue 3 in Vite.

## Recommended IDE Setup

[VSCode](https://code.visualstudio.com/) + [Volar](https://marketplace.visualstudio.com/items?itemName=Vue.volar) (and disable Vetur).

## Customize configuration

See [Vite Configuration Reference](https://vite.dev/config/).

## Project Setup

```sh
npm install
```

### Compile and Hot-Reload for Development

```sh
npm run dev
```

### Compile and Minify for Production

```sh
npm run build
```

## Database sync (optional, free)

To persist data across devices (web + mobile), use [Supabase](https://supabase.com) (free tier, PostgreSQL).

1. Create a project at [supabase.com](https://supabase.com).
2. In **SQL Editor**, run the contents of `supabase-schema.sql` to create tables and RLS.
3. In **Authentication → Providers**, enable **Anonymous** sign-in (so the app can sync without a login form).
4. In **Project Settings → API**, copy the project URL and the `anon` public key.
5. In the project root, copy `.env.example` to `.env` and set:
   - `VITE_SUPABASE_URL` = your project URL  
   - `VITE_SUPABASE_ANON_KEY` = your anon key  
6. Restart the dev server. The app will sign in anonymously and sync categories and expenses to Supabase. The header shows **Synced** when active.

**Sign in (email / password):** The app supports sign in and sign up with email and password. In the menu, use **Sign in** to open the auth modal. Create an account, then sign in to sync data across devices.

- In Supabase **Authentication → Providers**, ensure **Email** is enabled (email/password is on by default).
- After signing in, data syncs to your account and is the same on any device where you sign in.
