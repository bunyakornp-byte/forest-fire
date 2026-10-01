# Forest Fire Detection: ESP-NOW + Node-RED HTTP POST + Dashboard + Telegram

This package has three complete Arduino sketches and the Node-RED flow. MQTT/Mosquitto is not used.

## Files
- `master.ino`: ESP32 DevKit V1 / 38-pin Master. Receives ESP-NOW packets and POSTs each node to Node-RED `/firedata`.
- `slave1.ino`: ESP32-C3 SuperMini, sends `node1` sensor data.
- `slave2.ino`: ESP32-C3 SuperMini, sends `node2` sensor data.
- `flows.json`: Node-RED flow with separate Dashboard values for node1/node2 and Telegram alerts on transition into alert state.
- `docker-compose.yml`: starts Node-RED.
- `.env.example`: template for local environment variables. Copy to `.env`.
- `test-payloads.ps1`: sends test messages to a local Node-RED instance.

## 1. Configure the three sketches
Open each `.ino` and edit:

```cpp
const char* WIFI_SSID = "Iphone 17 pro";
const char* WIFI_PASSWORD = "12345678";
```

Use the exact same hotspot name/password on Master and both Slaves. On iPhone, enable Personal Hotspot and Allow Others to Join; use a compatible 2.4 GHz connection if available.

In `master.ino`, replace:

```cpp
const char* NODE_RED_URL = "http://localhost:1880/firedata";
const char* API_KEY = "b1070c05d2e64facabf9bdd956593f04942c4453f6d64f37af8a7eab10546de3";
```

with your real reachable URL and a long random API key. The URL must end in `/firedata`. The API key must match `NODE_RED_API_KEY` in `.env`.

The two Slaves are configured with Master MAC `7C:4F:AD:76:D0:C0` per the project request. **Confirm this is the Master board's actual Wi-Fi STA MAC** using the Master Serial Monitor. If it differs, replace `MASTER_MAC` in both Slave sketches with the actual MAC. ESP-NOW only works when Master and Slaves are on the same Wi-Fi channel; all three sketches connect to the same hotspot for this reason.

## 2. TLS note
The starter Master sketch uses `WiFiClientSecure::setInsecure()` so a placeholder HTTPS endpoint can be tested without inserting a CA certificate. This disables server certificate verification and is **not suitable for production**. Before deploying over the public internet, replace it with `client.setCACert(ROOT_CA_CERT)` and add the correct trusted CA certificate. Prefer HTTPS; plain HTTP should only be used on a trusted local network.

## Docker Compose build-context fix

This project uses the official `nodered/node-red:latest` image directly and does not build a local image. The Compose file intentionally has no `build:` or `context: ../nodered` entry, so it will not look for `C:\\Users\\VICTUS\\Downloads\\nodered`.

If you previously used an older `docker-compose.yml`, replace it with the included file, then run these commands from this project folder:

```powershell
docker compose config
docker compose up -d
docker compose ps
```

The named `node_red_data` volume stores Node-RED data persistently. Do not run `docker compose down -v` unless you intend to delete that data.

## 3. Start Node-RED on Windows with Docker
1. Install Docker Desktop and start it.
2. Copy `.env.example` to `.env` in this folder.
3. Edit `.env` and set `NODE_RED_API_KEY`, `TELEGRAM_BOT_TOKEN`, and `TELEGRAM_CHAT_ID`. Keep `.env` private and do not commit it to GitHub.
4. Open PowerShell in this folder and run:

```powershell
docker compose up -d
docker ps
docker compose logs -f node-red
```

5. Open `http://localhost:1880`.
6. In Node-RED, install `@flowfuse/node-red-dashboard` using **Menu → Manage palette → Install**.
7. Import `flows.json` using **Menu → Import**, then click **Deploy**.
8. Open the Dashboard. The flow's base path/page path may produce `/dashboard/home`; check the Dashboard sidebar's link if needed.

The Node-RED endpoint for local testing is `http://YOUR-PC-LAN-IP:1880/firedata`. For remote access, configure a secure HTTPS reverse proxy/tunnel. Do not expose port 1880 directly to the public internet because it also exposes the Node-RED editor unless separately secured.

## 4. Telegram
Create a bot with Telegram's `@BotFather`, obtain its token, and set `TELEGRAM_BOT_TOKEN` in `.env`. Set `TELEGRAM_CHAT_ID` to the destination chat ID. Start a conversation with the bot (or add it to the target group) so it can send messages. Restart Node-RED after changing `.env`:

```powershell
docker compose up -d --force-recreate
```

The flow sends an alert when a node transitions from normal to alert; it avoids sending the same alert every 5 seconds. After the node returns to normal, a later alert can trigger another message.

## 5. Test the Node-RED flow
With Node-RED running and the flow deployed, edit `$ApiKey` in `test-payloads.ps1` to match `.env`, then run:

```powershell
.\test-payloads.ps1
```

The script sends a normal sample for `node1` and an alert sample for `node2` to localhost. For testing from another device, use the PC's reachable IP/URL instead.

## 6. Thresholds and limitations
The demo thresholds are temperature >= 50 °C, humidity <= 20%, or MQ-2 ADC >= 600. These values are examples and must be calibrated against the actual sensor, installation, and environment. A threshold alert is not proof that a forest fire exists. MQ-2 needs warm-up and its analog output must remain within the ESP32-C3's permitted input voltage.

The flow marks a node offline when a subsequent message arrives after its last update is older than 15 seconds. If both nodes stop sending, the current flow does not refresh the dashboard by itself until another message arrives; add a periodic Inject/timer flow if you need offline status to refresh continuously.
