#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: dave-yap
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://seafile.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
    sudo \
    mc \
    wget \
    expect
msg_ok "Installed Dependencies"

msg_info "Installing MariaDB"
$STD apt-get install -y mariadb-server
systemctl start mariadb
msg_ok "Installed MariaDB"

msg_info "Setup MariaDB for Seafile"
CCNET_DB="ccnet_db"
SEAFILE_DB="seafile_db"
SEAHUB_DB="seahub_db"
DB_USER="seafile"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
ADMIN_EMAIL="admin@localhost.local"
ADMIN_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
sudo -u mysql mysql -s -e "CREATE DATABASE $CCNET_DB CHARACTER SET utf8;"
sudo -u mysql mysql -s -e "CREATE DATABASE $SEAFILE_DB CHARACTER SET utf8;"
sudo -u mysql mysql -s -e "CREATE DATABASE $SEAHUB_DB CHARACTER SET utf8;"
sudo -u mysql mysql -s -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo -u mysql mysql -s -e "GRANT ALL PRIVILEGES ON $CCNET_DB.* TO '$DB_USER'@localhost;"
sudo -u mysql mysql -s -e "GRANT ALL PRIVILEGES ON $SEAFILE_DB.* TO '$DB_USER'@localhost;"
sudo -u mysql mysql -s -e "GRANT ALL PRIVILEGES ON $SEAHUB_DB.* TO '$DB_USER'@localhost;"
{
    echo "Application Credentials"
    echo "CCNET_DB: $CCNET_DB"
    echo "SEAFILE_DB: $SEAFILE_DB"
    echo "SEAHUB_DB: $SEAHUB_DB"
    echo "DB_USER: $DB_USER"
    echo "DB_PASS: $DB_PASS"
    echo "ADMIN_EMAIL: $ADMIN_EMAIL"
    echo "ADMIN_PASS: $ADMIN_PASS"
} >> ~/seafile.creds
msg_ok "MariaDB setup for Seafile"

msg_info "Installing Seafile Python Dependencies"
$STD apt-get install -y \
    python3 \
    python3-dev \
    python3-setuptools \
    python3-pip \
    libmariadb-dev \
    ldap-utils \
    libldap2-dev \
    libsasl2-dev \
    pkg-config
$STD pip3 install \
    django \
    future \
    mysqlclient \
    pymysql \
    pillow \
    pylibmc \
    captcha \
    markupsafe \
    jinja2 \
    sqlalchemy \
    psd-tools \
    django-pylibmc \
    django_simple_captcha \
    djangosaml2 \
    pysaml2 \
    pycryptodome \
    cffi \
    lxml \
    python-ldap
msg_ok "Installed Seafile Python Dependecies"

msg_info "Installing Seafile"
IP=$(ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
mkdir -p /opt/seafile
useradd seafile
mkdir -p /home/seafile
chown seafile: /home/seafile
chown seafile: /opt/seafile
su - seafile -c "wget -qc https://s3.eu-central-1.amazonaws.com/download.seadrive.org/seafile-server_11.0.13_x86-64.tar.gz"
su - seafile -c "tar -xzf seafile-server_11.0.13_x86-64.tar.gz -C /opt/seafile/"
$STD su - seafile -c "expect <<EOF
spawn bash /opt/seafile/seafile-server-11.0.13/setup-seafile-mysql.sh
expect {
    \"Press ENTER to continue\" {
        send \"\r\"
    }
}
expect {
    \"What is the name of the server\" {
        send \"Seafile\r\"
    }
}
expect {
    \"What is the ip or domain of the server\" {
        send \"$IP\r\"
    }
}
expect {
    \"Which port do you want to use for the seafile fileserver\" {
        send \"8082\r\"
    }
}
expect {
    \"1 or 2\" {
        send \"2\r\"
    }
}
expect {
    \"What is the host of mysql server\" {
        send \"localhost\r\"
    }
}
expect {
    \"What is the port of mysql server\" {
        send \"3306\r\"
    }
}
expect {
    \"Which mysql user to use for seafile\" {
        send \"seafile\r\"
    }
}
expect {
    \"What is the password for mysql user\" {
        send \"$DB_PASS\r\"
    }
}
expect {
    \"Enter the existing database name for ccnet\" {
        send \"$CCNET_DB\r\"
    }
}
expect {
    \"Enter the existing database name for seafile\" {
        send \"$SEAFILE_DB\r\"
    }
}
expect {
    \"Enter the existing database name for seahub\" {
        send \"$SEAHUB_DB\r\"
    }
}
expect {
    \"Press ENTER to continue, or Ctrl-C to abort\" {
        send \"\r\"
    }
}
expect eof
EOF"
msg_ok "Installed Seafile"

msg_info "Setting up Memcached"
$STD apt-get install -y \
    memcached \
    libmemcached-dev
$STD pip3 install \
    pylibmc \
    django-pylibmc
systemctl enable --now -q memcached
cat <<EOF >>/opt/seafile/conf/seahub_settings.py
CACHES = {
    'default': {
        'BACKEND': 'django_pylibmc.memcached.PyLibMCCache',
        'LOCATION': '127.0.0.1:11211',
    },
}
EOF
msg_ok "Memcached Started"

msg_info "Adjusting Conf files"
sed -i "0,/127.0.0.1/s/127.0.0.1/0.0.0.0/" /opt/seafile/conf/gunicorn.conf.py
msg_ok "Conf files adjusted"

msg_info "Setting up Seafile" 
$STD su - seafile -c "bash /opt/seafile/seafile-server-latest/seafile.sh start"
$STD su - seafile -c "expect <<EOF
spawn bash /opt/seafile/seafile-server-latest/seahub.sh start
expect {
    \"What is the email for the admin account\" {
        send \"$ADMIN_EMAIL\r\"
        }
    }
expect {
    \"What is the password for the admin account\" {
        send \"$ADMIN_PASS\r\"
        }
    }
expect {
    \"Enter the password again:\" {
        send \"$ADMIN_PASS\r\"
    }
}
expect eof
EOF"
$STD su - seafile -c "bash /opt/seafile/seafile-server-latest/seahub.sh stop"
$STD su - seafile -c "bash /opt/seafile/seafile-server-latest/seafile.sh stop"
msg_ok "Seafile setup"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/seafile.service
[Unit]
Description=Seafile File-hosting
After=network.target mysql.service memcached.service
Wants=mysql.service memcached.service

[Service]
Type=forking
User=seafile
Group=seafile
WorkingDirectory=/opt/seafile

ExecStart=/opt/seafile/seafile-server-latest/seafile.sh start
ExecStartPost=/opt/seafile/seafile-server-latest/seahub.sh start
ExecStop=/opt/seafile/seafile-server-latest/seahub.sh stop
ExecStop=/opt/seafile/seafile-server-latest/seafile.sh stop

Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now seafile.service
msg_ok "Created Services"

msg_info "Creating External Storage script"
cat <<'EOF' >~/external-storage.sh
#!/bin/bash
STORAGE_DIR="/path/to/your/external/storage"

# Move the seafile-data folder to external storage
mv /opt/seafile/seafile-data $STORAGE_DIR/seafile-data

# Create a symlink for access
ln -s $STORAGE_DIR/seafile-data /opt/seafile/seafile-data
EOF
msg_ok "Bash Script for External Storage created"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf seafile-server_11.0.13_x86-64.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"