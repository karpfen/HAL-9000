# Pocket ID SSO: admin setup

Technical rollout steps for the person setting this up. For what end users
need to know, see [`pocket-id-user-guide.md`](./pocket-id-user-guide.md).

## Prerequisites

- Add one hosts-file entry on your own device first (see the user guide's
  "one-time setup per device" section) so `hal9000.lan` resolves to this
  server's IP.
- Create `secrets/pocket_id_encryption_key.txt` (32 random bytes, e.g.
  `openssl rand -base64 32`) and `secrets/pocket_id_static_api_key.txt`
  (a random string of at least 16 characters, e.g. `openssl rand -hex 32`)
  before first start — `pocket-id.yml` requires both, and Pocket ID refuses
  to start if the API key is shorter than 16 characters.

## Rollout order (do not skip steps or reorder)

1. **Back up everything first**: `sudo backup/backup.sh all`. Non-negotiable
   — this touches four apps with real user data.
2. Bring up the stack (`./start_hal_9000.sh`, or `./setup.sh` on a fresh
   machine) so Caddy and Pocket ID start.
3. Visit `https://hal9000.lan:8443/setup` once and create the first Pocket ID
   admin account (passkey). This is the one unavoidable manual step — there's
   no way to bootstrap a human-usable login from an env var.
4. In Pocket ID's Settings → OIDC Clients, create four clients using these
   verified redirect URIs:

   | App              | Redirect URI                                                        | Client type              |
   |-------------------|----------------------------------------------------------------------|---------------------------|
   | Home Assistant    | `https://hal9000.lan:18123/auth/oidc/callback`                       | Public (PKCE, no secret) |
   | Nextcloud         | `https://hal9000.lan:18080/apps/user_oidc/code`                      | Confidential              |
   | Mealie            | `https://hal9000.lan:19925/login`                                    | Confidential              |
   | Paperless-ngx     | `https://hal9000.lan:18000/accounts/oidc/pocket-id/login/callback/`  | Confidential              |

   Save each confidential client's secret into its own `secrets/*.txt` file
   (e.g. `secrets/mealie_oidc_client_secret.txt`), then put the client
   id/secret into `.env` as `MEALIE_OIDC_CLIENT_ID`, `MEALIE_OIDC_CLIENT_SECRET`,
   `PAPERLESS_OIDC_CLIENT_ID`, `PAPERLESS_OIDC_CLIENT_SECRET` (referenced
   directly by `mealie.yml`/`paperless.yml`).

5. Set up each app **one at a time**, testing with a single real existing
   account before moving to the next. Do this in order — must-haves first:

   **Paperless-ngx** (env vars already in `paperless.yml` once `.env` has the
   client id/secret — just restart the container): log in with the existing
   local password as normal, then go to profile settings → connect social
   account, and link Pocket ID. This app never auto-links by claim; that's
   by design, not a bug.

   **Nextcloud**: run
   `sudo utils/nextcloud-oidc-setup.sh "<client-id>" "<client-secret>"`
   once. Before trusting it for everyone: in Pocket ID, turn off "Enable
   Self-Account Editing" for real users so their username claim can't drift,
   then log in via Pocket ID with one real account and confirm it lands on
   the *existing* Nextcloud account (same files visible) rather than a new
   one.

   **Home Assistant**: add this to `~/home-assistant/config/configuration.yaml`
   (this file lives outside this repo, on the bind-mounted config volume) and
   restart Home Assistant:
   ```yaml
   http:
     use_x_forwarded_for: true
     trusted_proxies:
       - 127.0.0.1
       - ::1

   auth_oidc:
     client_id: "<home assistant client id from Pocket ID>"
     discovery_url: "https://hal9000.lan:8443/.well-known/openid-configuration"
     features:
       automatic_user_linking: true
       require_existing_user: true
   ```
   The `http:` block is required, not optional: Caddy terminates TLS and
   forwards plain HTTP to Home Assistant on `localhost:8123`, and Caddy runs
   with `network_mode: host` so that connection genuinely arrives from
   `127.0.0.1`. Without `trusted_proxies`/`use_x_forwarded_for`, HA won't
   trust the `X-Forwarded-Proto` header Caddy sends and will build an
   `http://` (not `https://`) OIDC callback URL, which won't match the
   redirect URI registered in Pocket ID and will break login. If
   `configuration.yaml` already has an `http:` block, merge these two keys
   into it rather than adding a second `http:` block.
   `require_existing_user: true` blocks new-account creation. Test with one
   existing HA user before rolling out further. `hass-oidc-auth` is installed
   automatically by `setup.sh` (pinned release, idempotent) into
   `custom_components/auth_oidc/` — if it's already running and you're adding
   this after the fact, re-run the relevant block from `setup.sh` manually or
   just re-run `setup.sh` itself.

   **Mealie** (nice-to-have, do last): env vars already in `mealie.yml` once
   `.env` has the client id/secret. Confirm the login lands on the existing
   account (matched by email) rather than erroring.

6. Local passwords remain enabled everywhere throughout and afterward — this
   never removes a fallback login, only adds an SSO option on top.

## Security note

Once Home Assistant's `automatic_user_linking` is on, anyone who
authenticates as a given person in Pocket ID is logged into that person's HA
account directly, bypassing any HA-native 2FA that account had — this is
inherent to how SSO works, not a misconfiguration.

## Known things to re-verify at rollout time, not just trust this doc

- Whether Pocket ID's ID token includes `email_verified: true` (Mealie
  refuses OIDC login without it).
- `hass-oidc-auth`'s current release/config surface (believed stable at
  v1.2.1 as of this writing).
