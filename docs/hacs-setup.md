# HACS (Home Assistant Community Store)

`setup.sh` installs HACS's files automatically (into
`~/home-assistant/config/custom_components/hacs`), but activating it needs a
one-time manual step that can't be scripted: HACS links to your GitHub
account via a device-code flow, which requires a human clicking through a
browser.

## One-time activation

1. Run `setup.sh` (or, if Home Assistant is already running, just restart it
   after the HACS files are in place).
2. In Home Assistant: **Settings → Devices & Services → Add Integration**,
   search for **HACS**, and follow the prompts.
3. You'll be shown a code and a link to `github.com/login/device` — open
   that link, log into GitHub, and enter the code. This is what grants HACS
   its own GitHub API rate limit; it doesn't need write access to anything.
4. Once linked, HACS appears in the sidebar. From here on, HACS updates
   itself through its own UI — `setup.sh` won't touch it again once its
   `custom_components/hacs` folder exists.

## Installing the Dreame vacuum integration

The community Dreame integration ([Tasshack/dreame-vacuum](https://github.com/Tasshack/dreame-vacuum))
is in HACS's **default store** — no need to add it as a custom repository:

1. In HACS, search for **"Dreame Vacuum"** and install it.
2. Restart Home Assistant.
3. Add it as an integration (Settings → Devices & Services → Add
   Integration → Dreame Vacuum) and follow its own setup flow to connect
   your vacuum.
