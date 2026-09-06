#!/usr/bin/env python3
"""Read-only release gate report. Never creates or repairs evidence."""
import argparse
import json
from pathlib import Path
from release_record import verify_record

RECORDS = ('archived','signed','provisional-dmg','provisional-installed','local-ui-proof','ci-proof',
           'app-accepted','app-stapled','dmg-accepted','dmg-stapled','assets','published')

def inspect(root, complete=False):
    issues=[]
    records={}
    for name in RECORDS:
        try: records[name]=json.loads((root/(name+'.json')).read_text())
        except (OSError,ValueError): issues.append('Missing or unreadable '+name)
    # Earlier signatures and staple stages deliberately transform the same path.
    # Verify final fingerprints, retain the earlier records as stage history.
    for name in ('app-stapled','dmg-stapled','assets','published'):
        if name in records:
            try: verify_record(root/(name+'.json'), records[name]['artifact'])
            except (OSError,ValueError,KeyError): issues.append('Changed artifact '+name)
    if 'local-ui-proof' in records and records['local-ui-proof'].get('signedInstalledWorkflow')!='passed': issues.append('Signed installed UI did not pass')
    if 'ci-proof' in records:
        ci=records['ci-proof']
        if ci.get('conclusion')!='success': issues.append('CI did not succeed')
        if ci.get('sourceSHA')!=records.get('archived',{}).get('evidence',{}).get('sourceSHA'): issues.append('CI source mismatch')
    for name in ('app','dmg'):
        try:
            if json.loads((root/(name+'-notary-status.json')).read_text()).get('status')!='Accepted': issues.append(name+' not accepted')
        except (OSError,ValueError): issues.append('Missing '+name+' Apple status')
    if complete:
        for name in ('published-install-proof','two-version-update'):
            try:
                evidence=json.loads((root/(name+'.json')).read_text())
                if evidence.get('result')!='pass': issues.append(name+' did not pass')
            except (OSError,ValueError): issues.append('Missing '+name)
    return issues

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('release_directory',type=Path)
    parser.add_argument('--complete',action='store_true')
    args=parser.parse_args()
    problems=inspect(args.release_directory,args.complete)
    print('\n'.join(problems) if problems else 'PASS: recorded release gates and final artifact fingerprints')
    raise SystemExit(bool(problems))
