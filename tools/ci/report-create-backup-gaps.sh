#!/usr/bin/env bash
# Report CT scripts that should use create_backup during update_script.
# Usage: ./tools/ci/report-create-backup-gaps.sh [--summary]

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUMMARY="${1:-}"

python3 - "$ROOT" "$SUMMARY" <<'PY'
import os, re, sys

root, summary = sys.argv[1], sys.argv[2]
ct = os.path.join(root, 'ct')

def block(text):
    m = re.search(r'function update_script\(\).*?(?=^function |\Z)', text, re.S | re.M)
    return m.group() if m else ''

cats = {
    'has_backup': [],
    'config_mutation': [],
    'fetch_deploy': [],
    'package_only': [],
    'docker_only': [],
    'fetch_binary_only': [],
    'other': [],
}

for f in sorted(os.listdir(ct)):
    if not f.endswith('.sh'):
        continue
    text = open(os.path.join(ct, f)).read()
    b = block(text)
    if not b:
        continue
    if 'create_backup' in b:
        cats['has_backup'].append(f)
        continue
    if re.search(r'sed -i|\.env|settings\.(py|json)|config\.(json|yml|yaml)', b):
        cats['config_mutation'].append(f)
    elif re.search(r'fetch_and_deploy_gh_release', b) and re.search(r'rm -rf', b):
        if re.search(r'sed -i|\.env|settings\.|config\.', b):
            cats['fetch_deploy'].append(f)
        else:
            cats['fetch_binary_only'].append(f)
    elif re.search(r'fetch_and_deploy_gh_release', b):
        cats['fetch_deploy'].append(f)
    elif re.search(r'docker (pull|compose|image)', b):
        cats['docker_only'].append(f)
    elif re.search(r'\$STD apt|\$STD apk|pip install|npm install|yarn install|uv pip', b) and not re.search(r'rm -rf|sed -i', b):
        cats['package_only'].append(f)
    else:
        cats['other'].append(f)

total = sum(len(v) for v in cats.values())
need_high = len(cats['config_mutation'])
need_review = len(cats['fetch_deploy']) + len(cats['fetch_binary_only']) + len(cats['other'])

if summary == '--summary':
    print(f"update_script gesamt:     {total}")
    print(f"bereits create_backup:    {len(cats['has_backup'])}")
    print(f"PRIORITÄT (Config):       {need_high}")
    print(f"PRÜFEN (fetch/other):     {need_review}")
    print(f"meist OK (nur Pakete):    {len(cats['package_only']) + len(cats['docker_only'])}")
    print(f"→ realistisch migrieren:  ~{need_high + need_review} Skripte")
else:
    for label, files in [
        ('PRIORITÄT config_mutation', cats['config_mutation']),
        ('PRÜFEN fetch_deploy', cats['fetch_deploy']),
        ('PRÜFEN fetch_binary_only', cats['fetch_binary_only']),
        ('PRÜFEN other', cats['other']),
        ('OK package_only', cats['package_only']),
        ('OK docker_only', cats['docker_only']),
        ('DONE has_backup', cats['has_backup']),
    ]:
        print(f"\n## {label} ({len(files)})")
        for f in files:
            print(f)
PY
