#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://magicmirror.builders/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "magicmirror" "MagicMirrorOrg/MagicMirror" "tarball"

msg_info "Configuring MagicMirror"
cd /opt/magicmirror
sed -i -E 's/("postinstall": )".*"/\1""/; s/("prepare": )".*"/\1""/' package.json
$STD npm run install-mm
cat <<EOF >/opt/magicmirror/config/config.js
let config = {
        address: "0.0.0.0",     
        port: 8080,
        basePath: "/",  
        ipWhitelist: [],        
        useHttps: false,              
        httpsPrivateKey: "",    
        httpsCertificate: "",   
        language: "en",
        locale: "en-US",
        logLevel: ["INFO", "LOG", "WARN", "ERROR"], 
        timeFormat: 24,
        units: "metric",
        serverOnly:  true,
        modules: [
                {
                        module: "alert",
                },
                {
                        module: "updatenotification",
                        position: "top_bar"
                },
                {
                        module: "clock",
                        position: "top_left"
                },
                {
                        module: "calendar",
                        header: "US Holidays",
                        position: "top_left",
                        config: {
                                calendars: [
                                        {
                                                symbol: "calendar-check",
                                                url: "webcal://www.calendarlabs.com/ical-calendar/ics/76/US_Holidays.ics"
                                        }
                                ]
                        }
                },
                {
                        module: "compliments",
                        position: "lower_third"
                },
                {
                        module: "weather",
                        position: "top_right",
                        config: {
                                weatherProvider: "openweathermap",
                                type: "current",
                                location: "New York",
                                locationID: "5128581", //ID from http://bulk.openweathermap.org/sample/city.list.json.gz; unzip the gz file and find your city
                                apiKey: "YOUR_OPENWEATHER_API_KEY"
                        }
                },
                {
                        module: "weather",
                        position: "top_right",
                        header: "Weather Forecast",
                        config: {
                                weatherProvider: "openweathermap",
                                type: "forecast",
                                location: "New York",
                                locationID: "5128581", //ID from http://bulk.openweathermap.org/sample/city.list.json.gz; unzip the gz file and find your city
                                apiKey: "YOUR_OPENWEATHER_API_KEY"
                        }
                },
                {
                        module: "newsfeed",
                        position: "bottom_bar",
                        config: {
                                feeds: [
                                        {
                                                title: "New York Times",
                                                url: "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml"
                                        }
                                ],
                                showSourceTitle: true,
                                showPublishDate: true,
                                broadcastNewsFeeds: true,
                                broadcastNewsUpdates: true
                        }
                },
        ]
};

/*************** DO NOT EDIT THE LINE BELOW ***************/
if (typeof module !== "undefined") {module.exports = config;}
EOF
msg_ok "Configured MagicMirror"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/magicmirror.service
[Unit]
Description=Magic Mirror
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
WorkingDirectory=/opt/magicmirror/
ExecStart=/usr/bin/npm run server

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now magicmirror
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
