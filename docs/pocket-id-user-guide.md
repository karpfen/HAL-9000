# Logging in with Pocket ID

## What changed

You now have **one login** (a passkey — no password to remember) that works
across Home Assistant, Nextcloud, Mealie, and Paperless. It's called
**Pocket ID**. Your existing accounts and all your existing data in every app
are unchanged — this just adds a faster way to log into them. Your old
password still works everywhere too, as a backup.

## One-time setup per device

1. **Add one line to your device's hosts file**, pointing `hal9000.lan` at
   the server's IP address (ask the admin for the current IP if you don't
   have it):
   - **Windows**: edit `C:\Windows\System32\drivers\etc\hosts` as
     administrator, add a line like `192.168.1.50 hal9000.lan`.
   - **Mac/Linux**: `sudo nano /etc/hosts`, add the same line.
   - **Phone**: this is harder on stock Android/iOS without extra apps; ask
     the admin if you mainly need phone access — there may be a per-device
     workaround.
2. **Visit any service** (e.g. `https://hal9000.lan:18123` for Home
   Assistant) — your browser will warn the certificate isn't trusted. This is
   expected: it's a private certificate this server made for itself, not a
   sign anything is wrong. Click through ("Advanced" → "Proceed"). You only
   need to do this once per device (or once per app, depending on browser).
3. **Set up your passkey** the first time you're asked to log in via Pocket
   ID — your device will prompt for your fingerprint, face, PIN, or a
   security key, whichever you normally use to unlock your device.
4. **Add a second passkey from another device** (e.g. your phone as a backup
   to your laptop) so losing one device doesn't lock you out. In Pocket ID,
   this is under your account settings → Passkeys → Add.

## How login works, per app

- **Home Assistant** and **Mealie**: on the login screen, choose the SSO/
  "Login with OIDC" option. You'll be sent to Pocket ID, confirm with your
  passkey, and land straight back in, already logged into your existing
  account.
- **Nextcloud**: same — choose the SSO login option, confirm with your
  passkey. It's matched to your existing Nextcloud account automatically.
- **Paperless**: log in **normally with your existing password** the first
  time, then go to your profile settings and choose "connect social account"
  to link Pocket ID. After that one-time link, you can use Pocket ID to log
  in going forward. (This app doesn't support the fully automatic version the
  others do — this manual link step is expected, not a bug.)

## If you lose access to your passkey(s)

If you still have at least one enrolled passkey on another device, just use
that one, then remove the lost device and add a new one. If you've lost
*all* of them, ask the admin — they can generate you a one-time recovery link
from Pocket ID's admin panel without needing your old passkey at all.

## Good to know

- Your local password for each app (Nextcloud, Mealie, Paperless, Home
  Assistant) keeps working exactly as before — Pocket ID is an added option,
  not a replacement, at least until everyone's comfortable relying on it.
- Two separate sessions exist (Pocket ID's and each app's own), so very
  occasionally you might be asked to log in again to one but not the other —
  that's normal, not an error.
