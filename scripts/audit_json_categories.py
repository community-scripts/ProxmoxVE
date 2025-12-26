#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON_DIR = ROOT / 'frontend' / 'public' / 'json'
METADATA_FILE = JSON_DIR / 'metadata.json'
REPORT_MD = JSON_DIR / 'audit_category_report.md'
REPORT_JSON = JSON_DIR / 'audit_category_report.json'


def load_metadata():
    with METADATA_FILE.open() as f:
        md = json.load(f)
    cats = {}
    for c in md.get('categories', []):
        try:
            cid = int(c.get('id'))
        except Exception:
            continue
        cats[cid] = c

    # Also create name->id map (lowercased)
    name_map = {c.get('name','').lower(): int(c.get('id')) for c in md.get('categories', []) if 'name' in c and 'id' in c}
    return cats, name_map


def normalize_value(v):
    if v is None:
        return None
    if isinstance(v, (int, float)):
        return int(v)
    if isinstance(v, str):
        s = v.strip()
        if s.isdigit():
            return int(s)
        return s.lower()
    return v


def check_file(p, cats_by_id, name_map):
    try:
        j = json.loads(p.read_text())
    except Exception as e:
        return {'file': str(p.name), 'error': f'json_parse_error: {e}'}

    found = []
    notes = []

    # look for common keys
    keys_to_check = ['category_id', 'category', 'categories']
    for key in keys_to_check:
        if key in j:
            val = j[key]
            if isinstance(val, list):
                for item in val:
                    nv = normalize_value(item)
                    found.append((key, nv))
            else:
                nv = normalize_value(val)
                found.append((key, nv))

    # also check top-level keys that might indicate category
    if not found:
        for alt in ['tags', 'type']:
            if alt in j:
                val = j[alt]
                if isinstance(val, list):
                    for item in val:
                        found.append((alt, normalize_value(item)))
                else:
                    found.append((alt, normalize_value(val)))

    if not found:
        notes.append('no_category_field')
        return {'file': str(p.name), 'found': [], 'notes': notes}

    mapped = []
    for key, val in found:
        if isinstance(val, int):
            if val in cats_by_id:
                mapped.append({'key': key, 'value': val, 'mapped_to': cats_by_id[val]['name']})
            else:
                mapped.append({'key': key, 'value': val, 'mapped_to': None})
                notes.append(f'unknown_category_id:{val}')
        elif isinstance(val, str):
            # try name map
            if val in name_map:
                cid = name_map[val]
                mapped.append({'key': key, 'value': val, 'mapped_to': cats_by_id[cid]['name']})
            else:
                mapped.append({'key': key, 'value': val, 'mapped_to': None})
                notes.append(f'unknown_category_name:{val}')
        else:
            mapped.append({'key': key, 'value': val, 'mapped_to': None})
            notes.append(f'unhandled_value_type:{type(val)}')

    return {'file': str(p.name), 'found': mapped, 'notes': notes}


def main():
    cats_by_id, name_map = load_metadata()
    report = {'summary': {'total_files': 0, 'errors': 0, 'questionable': 0}, 'files': []}

    for p in sorted(JSON_DIR.glob('*.json')):
        if p.name == METADATA_FILE.name:
            continue
        report['summary']['total_files'] += 1
        res = check_file(p, cats_by_id, name_map)
        if 'error' in res:
            report['summary']['errors'] += 1
            report['files'].append(res)
            continue
        # determine if questionable: any mapped_to is None or notes
        questionable = False
        for f in res.get('found', []):
            if f.get('mapped_to') is None:
                questionable = True
        if res.get('notes'):
            questionable = True
        if questionable:
            report['summary']['questionable'] += 1
        report['files'].append(res)

    # write JSON report
    REPORT_JSON.write_text(json.dumps(report, indent=2))

    # write MD summary
    lines = []
    lines.append('# Audit Report: JSON Categories')
    lines.append('')
    lines.append(f"- Total files scanned: {report['summary']['total_files']}")
    lines.append(f"- Files with parse errors: {report['summary']['errors']}")
    lines.append(f"- Files with questionable/missing categories: {report['summary']['questionable']}")
    lines.append('')
    lines.append('## Problematic files')
    lines.append('')
    for f in report['files']:
        if f.get('notes') or any(x.get('mapped_to') is None for x in f.get('found', [])):
            lines.append(f"- **{f['file']}**")
            if 'error' in f:
                lines.append(f"  - Error: {f['error']}")
            if f.get('found'):
                for found in f['found']:
                    lines.append(f"  - Field `{found['key']}` => `{found['value']}` mapped_to: `{found.get('mapped_to')}`")
            if f.get('notes'):
                for n in f['notes']:
                    lines.append(f"  - Note: {n}")
            lines.append('')

    REPORT_MD.write_text('\n'.join(lines))
    print('Audit complete:')
    print(f"  Total: {report['summary']['total_files']}")
    print(f"  Questionable: {report['summary']['questionable']}")
    print(f"  Errors: {report['summary']['errors']}")
    print(f"Wrote: {REPORT_JSON} and {REPORT_MD}")


if __name__ == '__main__':
    main()
