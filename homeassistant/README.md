# Home Assistant — `my.home`

A tablet-optimized Home Assistant dashboard with a swipeable card layout, custom sidebar, and dark theme. Configuration is written entirely in YAML with [`lovelace_gen`](https://github.com/thomasloven/hass-lovelace_gen) templating and relies heavily on HACS frontend components and `card-mod` for styling.

Based on [matt8707/hass-config](https://github.com/matt8707/hass-config).

---

## Requirements

### Core

- **Home Assistant** — tested on recent stable releases
- **MariaDB** — used as the recorder database (configured via `secrets.yaml`)
- **MQTT broker** — used for person last-seen persistence (e.g. Mosquitto)

### HACS (must be installed first)

Install [HACS](https://hacs.xyz/) before anything else. All frontend resources listed below are fetched through it.

---

## HACS Frontend Components

The following custom cards and resources must be downloaded via HACS before the dashboard will render correctly. All are available in the HACS default store unless noted.

| Component | HACS Name | Used For |
|---|---|---|
| `button-card` | Button Card | Core card system — used for almost every interactive element |
| `lovelace-card-mod` | card-mod | All CSS-in-JS styling, theme overrides, selector-based styling |
| `lovelace-layout-card` | Layout Card | Grid-based dashboard layout with responsive breakpoints |
| `swipe-card` | Swipe Card | Horizontal swipeable card carousel on the main dashboard |
| `apexcharts-card` | ApexCharts Card | Temperature, humidity, and system metric charts |
| `lovelace-mushroom` | Mushroom | Light control popups (`mushroom-light-card`) |
| `lovelace-more-info-card` | More Info Card | More-info popup card used in hold-action modals |
| `lovelace-xiaomi-vacuum-map-card` | Xiaomi Vacuum Map Card | Vacuum cleaner live map (component is present but view is disabled) |
| `tabbed-card` | Tabbed Card | Tab navigation within card groups |
| `lovelace-hui-element` | HUI Element | Advanced card composition helper |
| `custom-icons` | Custom Icons | Custom icon set used across button cards |
| `kiosk-mode` | Kiosk Mode | Hides the HA header for a tablet-style full-screen display |

### HACS Integrations (Backend)

| Integration | Used For |
|---|---|
| `monitor_docker` | Docker container monitoring (watchtower, hass, mosquitto) |
| `browser_mod` | Browser-side popups, notifications, sequences |
| `HACS` | Custom component and resource management |

---

## Setup

### 1. Install HACS and integrations

Follow the [HACS installation guide](https://hacs.xyz/docs/setup/download/). After HACS is installed, download all frontend components and backend integrations listed above.

### 2. Configure secrets

Copy or create `config/secrets.yaml` with the following keys:

```yaml
recorder_db_url: mysql://USER:PASSWORD@HOST/ha_db?charset=utf8
duckdns_token: <your_duckdns_token>
duckdns_domain: <your_subdomain>.duckdns.org
```

### 3. Set the theme

After the configuration loads, go to your **Profile** page in Home Assistant and set your theme to **`tablet`**. The dashboard will display a large red warning banner until this is done.

### 4. Enable MQTT for person tracking

The presence tracking system publishes last-seen timestamps over MQTT. Make sure your MQTT broker is configured and the device tracker integration is publishing to the expected topics. If you see `NaNd` in the presence card, trigger a publish from your device manually.

### 5. Lovelace mode

The dashboard uses **YAML mode** with `lovelace_gen` for templating. After modifying any UI YAML file, use **Refresh** in the Lovelace editor or restart HA to pick up changes.

---

## Directory Structure

```
homeassistant/
└── config/
    ├── configuration.yaml        Main HA configuration entry point
    ├── secrets.yaml              Credentials and sensitive values (not committed)
    ├── themes.yaml               "tablet" dark theme definition with card-mod styles
    ├── template_sensors.yaml     Jinja2 template sensors (time, date, sidebar state)
    ├── ui-lovelace.yaml          Top-level Lovelace dashboard definition
    │
    ├── button_card_templates/    Reusable button-card template definitions
    │   └── ...
    │
    ├── packages/                 Modular HA configuration loaded via include_dir_named
    │   └── ...
    │
    ├── ui/                       Lovelace view and component YAML files
    │   ├── ...
    │   └── components/
    │       └── ...
    │
    ├── popup/                    Hold-action popup modal definitions
    │   └── ...
    │
    └── www/                      Static files served at /local/
        └── ...
```


## Notes

- All user-facing text is in **Polish**.
- The vacuum map view (`vacuum_component.yaml`) is present but **commented out** in `main_swipe_view.yaml`.
- The history view (`history_component.yaml`) is included in `main_swipe_view.yaml` but also **commented out**.
- `secrets.yaml` is excluded from version control.
- TOTP MFA is enforced; keep your authenticator app paired.
