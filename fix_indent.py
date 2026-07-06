import os
import re

four_space_files = [
    'alpine-cinny.sh', 'apache-airflow.sh', 'asterisk.sh', 'authentik.sh',
    'baserow.sh', 'clickhouse.sh', 'cross-seed.sh', 'cyberchef.sh',
    'dotnetaspwebapi.sh', 'etherpad.sh', 'excalidash.sh', 'feishin.sh',
    'fhem.sh', 'flame.sh', 'fmd-server.sh', 'freepbx.sh', 'frigate.sh',
    'hev-socks5-server.sh', 'homer.sh', 'iventoy.sh', 'kiwix.sh',
    'koffan.sh', 'kometa.sh', 'lazylibrarian.sh', 'loki.sh',
    'lyrionmusicserver.sh', 'matterjs-server.sh', 'mattermost.sh',
    'meshcentral.sh', 'metabase.sh', 'mongodb.sh', 'netbird.sh',
    'nextcloudpi.sh', 'octoprint.sh', 'paperclip.sh', 'pihole.sh',
    'pinchflat.sh', 'plane.sh', 'podman.sh', 'postgresql.sh',
    'postiz.sh', 'rackula.sh', 'sabnzbd.sh', 'shlink.sh',
    'smokeping.sh', 'snapotter.sh', 'spliit.sh', 'splunk-enterprise.sh',
    'sqlserver2022.sh', 'sqlserver2025.sh', 'tolgee.sh', 'twenty.sh',
    'upgopher.sh', 'upsnap.sh', 'valkey.sh', 'warracker.sh', 'xyops.sh'
]

base_path = r'd:\Code\ProxmoxVE\ct'

HEREDOC_START = re.compile(r'<<["\'\`]?([A-Za-z0-9_]+)["\'\`]?\s*$')

def convert_line(line):
    stripped = line.lstrip(' ')
    leading = len(line) - len(stripped)
    if leading > 0 and leading % 4 == 0:
        new_leading = leading // 2
        return ' ' * new_leading + stripped
    return line

def convert_indentation(content):
    lines = content.split('\n')
    new_lines = []
    in_heredoc = False
    heredoc_delimiter = None

    for line in lines:
        if not in_heredoc:
            m = HEREDOC_START.search(line)
            if m:
                heredoc_delimiter = m.group(1)
                in_heredoc = True
                new_lines.append(convert_line(line))
                continue
            new_lines.append(convert_line(line))
        else:
            if line.rstrip() == heredoc_delimiter:
                in_heredoc = False
                heredoc_delimiter = None
            new_lines.append(line)

    return '\n'.join(new_lines)

converted = 0
for filename in four_space_files:
    filepath = os.path.join(base_path, filename)
    if not os.path.exists(filepath):
        print(f'SKIP (not found): {filename}')
        continue
    with open(filepath, 'r', encoding='utf-8', newline='') as f:
        content = f.read()
    new_content = convert_indentation(content)
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        f.write(new_content)
    print(f'Converted: {filename}')
    converted += 1

print(f'\nDone! Converted {converted} files.')
