#!/usr/bin/env bash
# OpenClaw First-Run Setup Wizard
# Runs automatically on first SSH login, writes config, starts service.

CONFIG_DIR="/root/.openclaw"
CONFIG_FILE="${CONFIG_DIR}/openclaw.json"
SENTINEL="${CONFIG_DIR}/.configured"
SERVICE="openclaw"
BACKTITLE="OpenClaw Setup Wizard"

# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────

die() {
  whiptail --backtitle "$BACKTITLE" --title "Error" --msgbox "$1" 10 60
  exit 1
}

check_deps() {
  for cmd in whiptail openclaw systemctl; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "ERROR: '$cmd' is not installed. Cannot run wizard." >&2
      exit 1
    fi
  done
}

# ──────────────────────────────────────────────
# Already configured?
# ──────────────────────────────────────────────

if [[ -f "$SENTINEL" ]]; then
  echo "OpenClaw is already configured. Run 'openclaw-wizard --reconfigure' to redo setup."
  exit 0
fi

if [[ "$1" == "--reconfigure" ]]; then
  rm -f "$SENTINEL"
fi

check_deps
mkdir -p "$CONFIG_DIR"

# ──────────────────────────────────────────────
# Welcome
# ──────────────────────────────────────────────

whiptail --backtitle "$BACKTITLE" \
  --title "Welcome to OpenClaw" \
  --msgbox "This wizard will configure your OpenClaw AI assistant.\n\nYou will be asked to:\n  • Choose an AI provider\n  • Enter your API key\n  • Connect a messaging platform\n\nPress OK to begin." 15 60

# ──────────────────────────────────────────────
# Step 1 — AI Provider
# ──────────────────────────────────────────────

AI_PROVIDER=$(whiptail --backtitle "$BACKTITLE" \
  --title "Step 1 of 4 — AI Provider" \
  --menu "Choose your AI provider:" 15 60 3 \
  "anthropic"  "Anthropic Claude (recommended)" \
  "openai"     "OpenAI (GPT-4o, o1, etc.)" \
  "codex"      "OpenAI Codex CLI (ChatGPT subscription)" \
  3>&1 1>&2 2>&3) || die "Setup cancelled."

# ──────────────────────────────────────────────
# Step 2 — API Key
# ──────────────────────────────────────────────

case "$AI_PROVIDER" in
  anthropic)
    KEY_LABEL="Anthropic API Key"
    KEY_HINT="Starts with sk-ant-  •  console.anthropic.com → API Keys"
    KEY_ENV="ANTHROPIC_API_KEY"
    ;;
  openai)
    KEY_LABEL="OpenAI API Key"
    KEY_HINT="Starts with sk-  •  platform.openai.com → API Keys"
    KEY_ENV="OPENAI_API_KEY"
    ;;
  codex)
    KEY_LABEL="OpenAI API Key (for Codex)"
    KEY_HINT="Starts with sk-  •  platform.openai.com → API Keys"
    KEY_ENV="OPENAI_API_KEY"
    ;;
esac

API_KEY=$(whiptail --backtitle "$BACKTITLE" \
  --title "Step 2 of 4 — API Key" \
  --passwordbox "${KEY_LABEL}\n\n${KEY_HINT}" 12 60 \
  3>&1 1>&2 2>&3) || die "Setup cancelled."

[[ -z "$API_KEY" ]] && die "API key cannot be empty."

# Basic format check
if [[ "$AI_PROVIDER" == "anthropic" && "$API_KEY" != sk-ant-* ]]; then
  whiptail --backtitle "$BACKTITLE" --title "Warning" \
    --yesno "That key doesn't look like an Anthropic key (expected sk-ant-...).\n\nContinue anyway?" 10 60 \
    || die "Setup cancelled."
fi

if [[ "$AI_PROVIDER" =~ ^(openai|codex)$ && "$API_KEY" != sk-* ]]; then
  whiptail --backtitle "$BACKTITLE" --title "Warning" \
    --yesno "That key doesn't look like an OpenAI key (expected sk-...).\n\nContinue anyway?" 10 60 \
    || die "Setup cancelled."
fi

# ──────────────────────────────────────────────
# Step 3 — Messaging Platform
# ──────────────────────────────────────────────

PLATFORM=$(whiptail --backtitle "$BACKTITLE" \
  --title "Step 3 of 4 — Messaging Platform" \
  --menu "Choose how you'll talk to your assistant:" 15 65 4 \
  "telegram"  "Telegram (easiest — create a bot via @BotFather)" \
  "discord"   "Discord (requires a Discord Application & Bot token)" \
  "whatsapp"  "WhatsApp (requires phone scan on first connect)" \
  "skip"      "Skip for now — configure manually later" \
  3>&1 1>&2 2>&3) || die "Setup cancelled."

BOT_TOKEN=""
PLATFORM_NOTE=""

case "$PLATFORM" in
  telegram)
    whiptail --backtitle "$BACKTITLE" --title "Telegram Setup" \
      --msgbox "To get a Telegram bot token:\n\n  1. Open Telegram and search for @BotFather\n  2. Send /newbot and follow the prompts\n  3. Copy the token it gives you\n\nPress OK when ready." 14 60

    BOT_TOKEN=$(whiptail --backtitle "$BACKTITLE" \
      --title "Telegram Bot Token" \
      --passwordbox "Paste your Telegram bot token below:\n\nFormat: 123456789:AABBccDDeeFFgg..." 11 65 \
      3>&1 1>&2 2>&3) || die "Setup cancelled."

    [[ -z "$BOT_TOKEN" ]] && die "Bot token cannot be empty."
    PLATFORM_NOTE="Pair your Telegram account by running:\n  openclaw pairing request telegram"
    ;;

  discord)
    whiptail --backtitle "$BACKTITLE" --title "Discord Setup" \
      --msgbox "To get a Discord bot token:\n\n  1. Go to discord.com/developers/applications\n  2. Create a new Application → Bot → Reset Token\n  3. Enable 'Message Content Intent' under Privileged Intents\n  4. Copy the token\n\nPress OK when ready." 16 65

    BOT_TOKEN=$(whiptail --backtitle "$BACKTITLE" \
      --title "Discord Bot Token" \
      --passwordbox "Paste your Discord bot token below:" 10 65 \
      3>&1 1>&2 2>&3) || die "Setup cancelled."

    [[ -z "$BOT_TOKEN" ]] && die "Bot token cannot be empty."
    PLATFORM_NOTE="Invite your bot to a server, then pair with:\n  openclaw pairing request discord"
    ;;

  whatsapp)
    whiptail --backtitle "$BACKTITLE" --title "WhatsApp Setup" \
      --msgbox "WhatsApp requires a phone scan to link.\n\nAfter the wizard finishes and the service starts,\na QR code will appear in the container logs.\n\nScan it with WhatsApp:\n  Settings → Linked Devices → Link a Device\n\nTo view logs:\n  journalctl -u openclaw -f\n\nPress OK to continue." 16 65

    PLATFORM_NOTE="Check logs for the WhatsApp QR code:\n  journalctl -u openclaw -f"
    ;;

  skip)
    whiptail --backtitle "$BACKTITLE" --title "Skipping Messaging" \
      --msgbox "No messaging platform configured.\n\nYou can add one later by editing:\n  ${CONFIG_FILE}\n\nOr by re-running:\n  openclaw-wizard --reconfigure" 12 60
    PLATFORM_NOTE="No messaging platform configured yet."
    ;;
esac

# ──────────────────────────────────────────────
# Step 4 — Review & Confirm
# ──────────────────────────────────────────────

SUMMARY="AI Provider : ${AI_PROVIDER}\nAPI Key     : ${API_KEY:0:8}••••••••••••\nPlatform    : ${PLATFORM}"

whiptail --backtitle "$BACKTITLE" \
  --title "Step 4 of 4 — Review" \
  --yesno "Ready to apply the following configuration?\n\n${SUMMARY}\n\nThis will:\n  • Write ${CONFIG_FILE}\n  • Set environment variables\n  • Enable and start the openclaw service" 18 65 \
  || die "Setup cancelled."

# ──────────────────────────────────────────────
# Write environment variables
# ──────────────────────────────────────────────

ENV_FILE="${CONFIG_DIR}/.env"
cat > "$ENV_FILE" <<EOF
# OpenClaw environment — sourced by systemd service
${KEY_ENV}=${API_KEY}
EOF

if [[ -n "$BOT_TOKEN" ]]; then
  case "$PLATFORM" in
    telegram) echo "TELEGRAM_BOT_TOKEN=${BOT_TOKEN}" >> "$ENV_FILE" ;;
    discord)  echo "DISCORD_BOT_TOKEN=${BOT_TOKEN}" >> "$ENV_FILE" ;;
  esac
fi

chmod 600 "$ENV_FILE"

# ──────────────────────────────────────────────
# Write openclaw.json config
# ──────────────────────────────────────────────

INTEGRATIONS="{}"

case "$PLATFORM" in
  telegram)
    INTEGRATIONS=$(cat <<EOFJSON
{
  "telegram": {
    "enabled": true,
    "botToken": "${BOT_TOKEN}"
  }
}
EOFJSON
    )
    ;;
  discord)
    INTEGRATIONS=$(cat <<EOFJSON
{
  "discord": {
    "enabled": true,
    "botToken": "${BOT_TOKEN}"
  }
}
EOFJSON
    )
    ;;
  whatsapp)
    INTEGRATIONS=$(cat <<EOFJSON
{
  "whatsapp": {
    "enabled": true
  }
}
EOFJSON
    )
    ;;
esac

cat > "$CONFIG_FILE" <<EOFJSON
{
  "provider": "${AI_PROVIDER}",
  "integrations": ${INTEGRATIONS},
  "gateway": {
    "bind": "lan",
    "port": 18789
  }
}
EOFJSON

chmod 600 "$CONFIG_FILE"

# ──────────────────────────────────────────────
# Patch systemd service to load the .env file
# ──────────────────────────────────────────────

SERVICE_FILE="/etc/systemd/system/${SERVICE}.service"

if grep -q "EnvironmentFile" "$SERVICE_FILE" 2>/dev/null; then
  # Already has EnvironmentFile line — update it
  sed -i "s|^EnvironmentFile=.*|EnvironmentFile=${ENV_FILE}|" "$SERVICE_FILE"
else
  # Insert after [Service]
  sed -i "/^\[Service\]/a EnvironmentFile=${ENV_FILE}" "$SERVICE_FILE"
fi

systemctl daemon-reload

# ──────────────────────────────────────────────
# Enable and start the service
# ──────────────────────────────────────────────

systemctl enable "$SERVICE" &>/dev/null
systemctl restart "$SERVICE"

sleep 2
STATUS=$(systemctl is-active "$SERVICE")

# ──────────────────────────────────────────────
# Mark as configured
# ──────────────────────────────────────────────

touch "$SENTINEL"

# ──────────────────────────────────────────────
# Done!
# ──────────────────────────────────────────────

IP=$(hostname -I | awk '{print $1}')

if [[ "$STATUS" == "active" ]]; then
  MSG="✔  OpenClaw is running!\n\nControl UI : http://${IP}:18789\nConfig     : ${CONFIG_FILE}\nLogs       : journalctl -u openclaw -f\n\n"
else
  MSG="⚠  OpenClaw service did not start cleanly.\nCheck logs with: journalctl -u openclaw -f\n\n"
fi

[[ -n "$PLATFORM_NOTE" ]] && MSG="${MSG}Next step:\n  ${PLATFORM_NOTE}\n\n"
MSG="${MSG}To re-run this wizard: openclaw-wizard --reconfigure"

whiptail --backtitle "$BACKTITLE" \
  --title "Setup Complete" \
  --msgbox "$MSG" 20 65
