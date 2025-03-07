#!/usr/bin/env bash
set -e

APP="Byparr"

################################################################################
# STEP 1: System Updates and Basic Dependencies
################################################################################

echo "Updating system packages..."
apt-get update -qq
apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    python3 \
    python3-pip \
    chromium \
    chromium-driver \
    xvfb \
    gnupg

################################################################################
# STEP 2: Install uv
# (See https://docs.astral.sh/uv/getting-started/installation/ for details)
################################################################################

if ! command -v uv &>/dev/null; then
  echo "Installing uv..."
  # Pull the official uv install script from astral.sh:
  curl -fSsL https://astral.sh/uv/install.sh | bash
  echo "uv installed successfully."
else
  echo "uv is already installed."
fi

################################################################################
# STEP 3: Clone or Download Byparr Source (assuming GitHub)
# If you already have a local copy, adjust as needed.
################################################################################

if [ ! -d "/opt/${APP}" ]; then
  echo "Cloning Byparr repository..."
  git clone --depth=1 https://github.com/ThePhaseless/Byparr.git /opt/${APP}
else
  echo "Byparr directory already exists—pulling latest changes."
  cd /opt/${APP}
  git pull --rebase
fi

cd /opt/${APP}

################################################################################
# STEP 4: Sync Dependencies for Tests
################################################################################
echo "Syncing test dependencies..."
uv sync --group test

################################################################################
# STEP 5: Run Tests
################################################################################

echo "Running tests with retries..."
# -n auto uses parallel tests if you prefer, remove if not needed
uv run pytest --retries 3 -n auto || TEST_FAIL="true"

if [ "$TEST_FAIL" = "true" ]; then
  echo "Some tests failed after retries."
  echo "Consider troubleshooting on another host or using another method."
  # Exit or keep going depending on your needs:
  # exit 1
else
  echo "All tests have passed successfully."

  ##############################################################################
  # STEP 6: Optionally Update Container / Create Issue for New Release
  # (Only if you have a process to handle new releases or updates)
  ##############################################################################
  # Example idea:
  # echo "Checking if we can create a new release..."
  # <your logic here>

fi

################################################################################
# STEP 7: Final Sync and Start
################################################################################

echo "Performing final dependencies sync..."
uv sync

echo "The Byparr install script has completed successfully!"
echo "To start Byparr, run: ./cmd.sh (from /opt/${APP} or wherever Byparr is located)"