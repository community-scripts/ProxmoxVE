#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://languagetool.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt install -y fasttext
msg_ok "Installed dependencies"

JAVA_VERSION="21" setup_java

msg_info "Setting up LanguageTool"
RELEASE=$(curl -fsSL https://languagetool.org/download/ | grep -oP 'LanguageTool-\K[0-9]+\.[0-9]+(\.[0-9]+)?(?=\.zip)' | sort -V | tail -n1)
download_file "https://languagetool.org/download/LanguageTool-stable.zip" /tmp/LanguageTool-stable.zip
unzip -q /tmp/LanguageTool-stable.zip -d /opt
mv /opt/LanguageTool-*/ /opt/LanguageTool/
download_file "https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.176.bin" /opt/lid.176.bin
rm -f /tmp/LanguageTool-stable.zip
msg_ok "Setup LanguageTool"

ngram_dir=""
lang_code=""
max_attempts=3
attempt=0

while [[ $attempt -lt $max_attempts ]]; do
  read -r -p "${TAB3}Enter language code (en, de, es, fr, nl) to download ngrams or press ENTER to skip: " lang_code

  if [[ -z "$lang_code" ]]; then
    break
  fi

  if [[ "$lang_code" =~ [[:space:]] ]]; then
    ((attempt++))
    remaining=$((max_attempts - attempt))
    if [[ $remaining -gt 0 ]]; then
      msg_error "Please enter only ONE language code. You have $remaining attempt(s) remaining."
    else
      msg_error "Maximum attempts reached. Continuing without ngrams."
      lang_code=""
    fi
    continue
  fi
  break
done

if [[ -n "$lang_code" ]]; then
  if [[ "$lang_code" =~ ^(en|de|es|fr|nl)$ ]]; then
    msg_info "Searching for $lang_code ngrams..."
    filename=$(curl -fsSL https://languagetool.org/download/ngram-data/ | grep -oP "ngrams-${lang_code}-[0-9]+\.zip" | sort -uV | tail -n1)

    if [[ -n "$filename" ]]; then
      msg_info "Downloading $filename"
      download_file "https://languagetool.org/download/ngram-data/${filename}" "/tmp/${filename}"

      mkdir -p /opt/ngrams
      msg_info "Extracting $lang_code ngrams to /opt/ngrams"
      unzip -q "/tmp/${filename}" -d /opt/ngrams
      rm "/tmp/${filename}"

      ngram_dir="/opt/ngrams"
      msg_ok "Installed $lang_code ngrams"
    else
      msg_info "No ngram file found for ${lang_code}"
    fi
  else
    msg_error "Invalid language code: $lang_code"
  fi
fi

cat <<EOF >/opt/LanguageTool/server.properties
fasttextModel=/opt/lid.176.bin
fasttextBinary=/usr/bin/fasttext
EOF
if [[ -n "$ngram_dir" ]]; then
  echo "languageModel=/opt/ngrams" >> /opt/LanguageTool/server.properties
fi
echo "${RELEASE}" >~/.languagetool
msg_ok "Setup LanguageTool"

msg_info "Creating Service"
cat <<'EOF' >/etc/systemd/system/language-tool.service
[Unit]
Description=LanguageTool Service
After=network.target

[Service]
WorkingDirectory=/opt/LanguageTool
ExecStart=java -cp languagetool-server.jar org.languagetool.server.HTTPServer --config server.properties --public --allow-origin "*"
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now language-tool
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
