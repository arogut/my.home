# CLAUDE.md — AI Assistant Guide for `my.home`

This file describes the repository structure, development workflows, and conventions an AI assistant should follow when working on this codebase.

---

## What This Repository Is

`my.home` is a self-hosted smart home stack running on a Raspberry Pi. It is not a traditional software project — there are **no tests to run, no build step, and no compiled artifacts**. The primary codebase is Home Assistant YAML configuration for a tablet-optimized dashboard with a dark theme, custom sidebar, and swipeable card layout. The entire UI is declared in YAML, templated with `lovelace_gen`, and rendered by Home Assistant at runtime.

The stack is managed via Docker Compose and deployed to the Pi via GitHub Actions (rsync + SSH).

---

## Repository Structure

```
my.home/
├── docker-compose.yml              All containerized services
├── .env.template                   Template for required env vars (copy to .env)
├── .gitignore
├── README.md
├── scripts/
│   └── restart-containers.sh       Restarts the homeassistant container on the Pi
├── .github/
│   └── workflows/
│       └── main-deployment-pipeline.yml  CI/CD: rsync to Pi + restart
├── homeassistant/
│   ├── README.md                   Setup guide and component list
│   └── config/                     Entire HA config — this is what gets deployed
│       ├── configuration.yaml      Main HA entry point
│       ├── ui-lovelace.yaml        Top-level Lovelace dashboard definition
│       ├── template_sensors.yaml   Jinja2 template sensors
│       ├── themes.yaml             "tablet" dark theme with card-mod overrides
│       ├── secrets.yaml            ← NOT committed (use secrets.yaml.template)
│       ├── button_card_templates/  Reusable button-card templates (base, light, media, etc.)
│       ├── packages/               Modular HA config loaded via include_dir_named
│       ├── ui/                     Lovelace view + component YAML files
│       │   └── components/         Individual dashboard panels (sidebar, system, etc.)
│       ├── popup/                  Hold-action modal definitions
│       └── www/                    Static files served at /local/ (JS, CSS, SVG, fonts)
├── mosquitto/config/               MQTT broker configuration
├── mariadb/                        MariaDB data (not committed)
├── nginx/                          Nginx reverse proxy config (not committed)
└── certbot/                        SSL cert storage (not committed)
```

---

## Services (Docker Compose)

| Service | Image | Purpose |
|---|---|---|
| `homeassistant` (hass) | `ghcr.io/home-assistant/home-assistant:stable` | Core smart home platform |
| `mariadb` | `linuxserver/mariadb` | Recorder database (`ha_db`) — 30-day history retention |
| `mosquitto` | `eclipse-mosquitto` | MQTT broker for person last-seen persistence |
| `watchtower` | `nickfedor/watchtower` | Auto-updates containers every 500s |
| `nginx` | `nginx:latest` | Reverse proxy (HTTP→HTTPS), reloads every 6h |
| `certbot` | `certbot/certbot:arm32v6-latest` | SSL cert renewal (ARM32v6 for Raspberry Pi) |

Home Assistant runs with `network_mode: host` and `privileged: true`. It depends on `mariadb` and `mosquitto` being healthy before starting.

---

## Environment Variables

Copy `.env.template` to `.env` before running locally. **Never commit `.env`.**

```
MYSQL_ROOT_PASSWORD=<root db password>
HA_MYSQL_PASSWORD=<ha db user password>
PUID=1000
PGID=1000
```

---

## Key Configuration Conventions

### YAML and Lovelace

- The dashboard runs in **YAML mode** (`resource_mode: yaml`). All UI changes must be made in YAML — the GUI editor is not used.
- **`lovelace_gen`** is used for YAML templating. It allows variables, macros, and includes across Lovelace files. After any YAML change, use Lovelace Refresh or restart HA.
- All HA packages are loaded via `!include_dir_named packages`. To add a new domain-level config, create a new `.yaml` file in `homeassistant/config/packages/`.

### Button Cards

Nearly every interactive element uses [`button-card`](https://github.com/custom-cards/button-card). Templates are defined in `button_card_templates/` and referenced by name. When creating or modifying cards:
- Reuse an existing template from `button_card_templates/` when possible (especially `base.yaml`, `light.yaml`, `sidebar.yaml`).
- Custom CSS goes inside `card_mod:` or `styles:` blocks within the button-card definition.
- Icon overrides live in `button_card_templates/icons.yaml`.

### Styling

- All CSS customization uses [`card-mod`](https://github.com/thomasloven/lovelace-card-mod) — either inline on a card or in `themes.yaml`.
- The active theme is `tablet` — defined in `homeassistant/config/themes.yaml`. Do not change the theme name; it is referenced by the sidebar warning banner logic.
- Responsive breakpoints are handled via CSS media queries inside card-mod styles (phone / portrait / desktop).

### Secrets

- Sensitive values go in `secrets.yaml` (not committed). Reference them with `!secret key_name`.
- The `secrets.yaml.template` documents the required keys: `recorder_db_url`, `duckdns_token`, `duckdns_domain`.

### Language

- **All user-facing text is in Polish.** Keep this consistent when adding labels, greeting messages, sidebar items, or notification text.

### Entity Naming

- Entities follow Polish naming (e.g., `fan.oczyszczacz`, `weather.forecast_dom`). Match the existing style when adding new entity references.

---

## Development Workflow

### Making Config Changes

1. Edit files in `homeassistant/config/`.
2. Commit and push to the appropriate branch.
3. Either trigger the GitHub Actions workflow manually (`workflow_dispatch`) or wait for the CI to detect `homeassistant/config/**` changes.
4. The pipeline rsyncs config to the Pi and runs `scripts/restart-containers.sh` via SSH to restart Home Assistant.

### Running Locally (Docker)

```bash
# Copy and fill in environment variables
cp .env.template .env

# Start all services
docker compose up -d

# Tail Home Assistant logs
docker compose logs -f homeassistant

# Restart only Home Assistant (after config changes)
docker compose restart homeassistant

# Stop everything
docker compose down
```

### Validating Changes

There is no automated test suite. Config validation happens implicitly when Home Assistant loads. Watch the logs after a restart:

```bash
docker compose logs -f homeassistant
```

Look for `ERROR` or `WARNING` lines. A successful load ends with `Home Assistant initialized`.

### Lovelace Refresh

After editing any UI YAML, either:
- Use the **Lovelace editor → three-dot menu → Refresh** in the browser, or
- Run `docker compose restart homeassistant`

---

## CI/CD Pipeline

File: `.github/workflows/main-deployment-pipeline.yml`

- **Trigger**: Manual (`workflow_dispatch`) — automatic push trigger is currently **disabled**.
- **Deployment target**: Raspberry Pi (accessed via SSH).
- **What it does**:
  1. Checks if any files under `homeassistant/config/**` changed.
  2. Sets up SSH key from `secrets.SSH_PRIVATE_KEY`.
  3. Rsyncs `./homeassistant/config` to `$REMOTE_PATH/homeassistant/` on the Pi (no permission/owner changes).
  4. SSHes into the Pi and runs `scripts/restart-containers.sh`.

**Required GitHub Secrets**: `SSH_PRIVATE_KEY`, `SSH_PORT`, `SSH_USER`, `SSH_HOST`, `REMOTE_PATH`.

To re-enable automatic deploys on push to master, uncomment the `push:` block in the workflow file.

---

## HACS Components Required

These must be installed via [HACS](https://hacs.xyz/) for the dashboard to render. Do not remove their resource entries from `configuration.yaml`.

| Component | Purpose |
|---|---|
| `button-card` | Core interactive element for almost every card |
| `card-mod` | CSS-in-JS styling and theme overrides |
| `lovelace-layout-card` | Responsive grid layout |
| `swipe-card` | Horizontal swipeable carousel on main dashboard |
| `apexcharts-card` | Charts (temperature, humidity, system metrics) |
| `lovelace-mushroom` | Light control popups |
| `lovelace-more-info-card` | Info popup cards |
| `lovelace-xiaomi-vacuum-map-card` | Vacuum map (present but view is disabled) |
| `tabbed-card` | Tab navigation within card groups |
| `lovelace-hui-element` | Advanced card composition |
| `custom-icons` | Custom icon set |
| `kiosk-mode` | Hides HA header for tablet full-screen |
| `monitor_docker` | Docker container monitoring (integration) |
| `browser_mod` | Browser-side popups and notification sequences (integration) |

---

## Things Currently Disabled / Commented Out

- **Vacuum view** (`vacuum_component.yaml`) — loaded but commented out in `main_swipe_view.yaml`.
- **History view** (`history_view.yaml`, `history_component.yaml`) — present but commented out.
- **Auto-push CI trigger** — the `push: branches: master` block in the pipeline is commented out; deploy is manual-only.

When re-enabling these, search for their references in `ui-lovelace.yaml` and `main_swipe_view.yaml` first.

---

## Security Notes

- **TOTP MFA is enforced** — every user account requires a paired TOTP authenticator. Do not disable this.
- `secrets.yaml` is in `.gitignore`. Never commit credentials.
- The nginx proxy trusts `127.0.0.1`, `::1`, and `172.16.0.0/12` as forwarded-for sources.
- External URL: `https://my-home-arogut.duckdns.org` (DuckDNS dynamic DNS).

---

## Files Never to Commit

The `.gitignore` excludes:
- `.env` (contains DB passwords)
- `homeassistant/config/secrets.yaml`
- `nginx/proxy.conf` (may contain server names / SSL paths)
- User images and font files
- `.vscode/` settings
- `.idea/` IDE files
