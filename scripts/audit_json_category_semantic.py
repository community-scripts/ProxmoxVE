#!/usr/bin/env python3
import json
from pathlib import Path
import re
from collections import Counter

ROOT = Path(__file__).resolve().parents[1]
JSON_DIR = ROOT / 'frontend' / 'public' / 'json'
METADATA_FILE = JSON_DIR / 'metadata.json'
REPORT_JSON = JSON_DIR / 'semantic_audit_report.json'
REPORT_MD = JSON_DIR / 'semantic_audit_report.md'

STOPWORDS = set(["the","and","of","in","a","to","with","for","on","is","an","by","as","or","all","tools","solutions","manage","management","system","systems","service","services"])


def tokens(text):
    if not text:
        return []
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    toks = [t for t in text.split() if t and t not in STOPWORDS and len(t) > 1]
    return toks


def load_categories():
    md = json.loads(METADATA_FILE.read_text())
    cats = {}
    for c in md.get('categories', []):
        try:
            cid = int(c.get('id'))
        except Exception:
            continue
        name = c.get('name','')
        desc = c.get('description','')
        kt = set(tokens(name) + tokens(desc))
        # also add raw name token
        cats[cid] = {'id': cid, 'name': name, 'desc': desc, 'keywords': kt}
    return cats


def score_text_against_category(text_tokens, cat_keywords):
    if not text_tokens or not cat_keywords:
        return 0
    cnt = 0
    for t in text_tokens:
        if t in cat_keywords:
            cnt += 1
    # simple score: count
    return cnt


def analyze_file(p, cats):
    try:
        obj = json.loads(p.read_text())
    except Exception as e:
        return {'file': p.name, 'error': f'parse_error: {e}'}

    # if the JSON is not an object (e.g., array of versions), we cannot determine category
    if not isinstance(obj, dict):
        return {'file': p.name, 'found': [], 'questionable': True, 'reasons': ['no_category_field']}

    # gather text
    parts = []
    for k in ['name','description','slug','type','documentation','website']:
        v = obj.get(k)
        if isinstance(v, list):
            parts.extend([str(x) for x in v if x])
        elif v:
            parts.append(str(v))
    # include install script path and notes
    for k in ['script','install_methods','notes','tags']:
        v = obj.get(k)
        if not v:
            continue
        if isinstance(v, list):
            for item in v:
                parts.append(json.dumps(item) if isinstance(item, (dict,list)) else str(item))
        elif isinstance(v, dict):
            parts.append(json.dumps(v))
        else:
            parts.append(str(v))

    text = " ".join(parts)
    tks = tokens(text)
    if not tks:
        return {'file': p.name, 'found': [], 'notes': ['no_text_to_analyze']}

    scores = []
    for cid, c in cats.items():
        sc = score_text_against_category(tks, c['keywords'])
        if sc > 0:
            scores.append({'id': cid, 'name': c['name'], 'score': sc})
    scores = sorted(scores, key=lambda x: (-x['score'], x['name']))

    # determine current categories
    current = []
    raw = obj.get('categories') or obj.get('category')
    if isinstance(raw, list):
        current = raw
    elif raw is not None:
        current = [raw]

    # normalize to ints where possible
    normalized_current = []
    for v in current:
        try:
            normalized_current.append(int(v))
        except Exception:
            # maybe it's a name; try to match by name
            for cid,c in cats.items():
                if isinstance(v,str) and v.strip().lower() == c['name'].lower():
                    normalized_current.append(cid)
                    break

    # decide if questionable
    questionable = False
    reasons = []
    if not normalized_current:
        questionable = True
        reasons.append('no_category_assigned')
    else:
        # if none of current in top 3 suggestions and top suggestion has score>0
        top_ids = [s['id'] for s in scores[:3]]
        if scores and all(cid not in top_ids for cid in normalized_current):
            questionable = True
            reasons.append('assigned_not_in_top_suggestions')

    return {'file': p.name, 'current': normalized_current, 'suggestions': scores[:5], 'questionable': questionable, 'reasons': reasons}


def main():
    cats = load_categories()
    report = {'summary': {'total': 0, 'questionable': 0, 'errors': 0}, 'files': []}
    for p in sorted(JSON_DIR.glob('*.json')):
        if p.name == METADATA_FILE.name:
            continue
        report['summary']['total'] += 1
        res = analyze_file(p, cats)
        if 'error' in res:
            report['summary']['errors'] += 1
        if res.get('questionable'):
            report['summary']['questionable'] += 1
        report['files'].append(res)

    REPORT_JSON.write_text(json.dumps(report, indent=2))

    lines = []
    lines.append('# Semantic Audit Report: Category Suggestions')
    lines.append('')
    lines.append(f"- Total files scanned: {report['summary']['total']}")
    lines.append(f"- Files with parse errors: {report['summary']['errors']}")
    lines.append(f"- Files flagged as questionable: {report['summary']['questionable']}")
    lines.append('')
    lines.append('## Flagged files and suggestions')
    lines.append('')
    for f in report['files']:
        if f.get('questionable') or f.get('error'):
            lines.append(f"- **{f['file']}**")
            if f.get('error'):
                lines.append(f"  - Error: {f['error']}")
            if f.get('current'):
                lines.append(f"  - Current categories: {f['current']}")
            if f.get('suggestions'):
                for s in f['suggestions']:
                    lines.append(f"  - Suggestion: {s['id']} {s['name']} (score={s['score']})")
            if f.get('reasons'):
                for r in f['reasons']:
                    lines.append(f"  - Reason: {r}")
            lines.append('')

    REPORT_MD.write_text('\n'.join(lines))
    print('Semantic audit complete:')
    print(f"  Total: {report['summary']['total']}")
    print(f"  Questionable: {report['summary']['questionable']}")
    print(f"  Errors: {report['summary']['errors']}")
    print(f"Wrote: {REPORT_JSON} and {REPORT_MD}")


if __name__ == '__main__':
    main()
