#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p build/StemRuntime build/PublishedProof/logs build/PublishedProof/mount build/PublishedProof/Applications
[[ "$RELEASE_TAG" =~ '^v[0-9]+\.[0-9]+\.[0-9]+$' ]] || exit 1
python3 - <<'PY'
import hashlib,json,os,re,urllib.request
from pathlib import Path
root=Path('build/PublishedProof');tag=os.environ['RELEASE_TAG'];repo='olivierbedardjazz-star/stem-separator'
request=urllib.request.Request(f'https://api.github.com/repos/{repo}/releases/tags/{tag}',headers={'User-Agent':'StemSeparator-InstallProof'})
release=json.load(urllib.request.urlopen(request))
assert release['tag_name']==tag and not release['draft'] and not release['prerelease']
asset=next(a for a in release['assets'] if re.fullmatch(r'Stem-Separator-[0-9.]+-[0-9]+-arm64\.dmg',a['name']))
checks=next(a for a in release['assets'] if a['name']=='SHA256SUMS.txt')
expected=next(l.split()[0] for l in urllib.request.urlopen(checks['browser_download_url']).read().decode().splitlines() if l.split()[-1]==asset['name'])
path=root/'installer.dmg';urllib.request.urlretrieve(asset['browser_download_url'],path)
h=hashlib.sha256()
with path.open('rb') as stream:
    for data in iter(lambda:stream.read(1024*1024),b''):h.update(data)
assert h.hexdigest()==expected
(root/'logs/download.json').write_text(json.dumps({'tag':tag,'asset':asset['name'],'sha256':expected,'releaseURL':release['html_url']},indent=2)+'\n')
PY
xcrun stapler validate build/PublishedProof/installer.dmg > build/PublishedProof/logs/staple-dmg.log 2>&1
hdiutil attach -readonly -nobrowse -mountpoint "$PWD/build/PublishedProof/mount" build/PublishedProof/installer.dmg > build/PublishedProof/logs/mount.log
trap 'hdiutil detach "$PWD/build/PublishedProof/mount" -quiet || true' EXIT
ditto 'build/PublishedProof/mount/Stem Separator.app' 'build/PublishedProof/Applications/Stem Separator.app'
hdiutil detach "$PWD/build/PublishedProof/mount" >> build/PublishedProof/logs/mount.log
trap - EXIT
app='build/PublishedProof/Applications/Stem Separator.app'
codesign --verify --deep --strict "$app" > build/PublishedProof/logs/signature.log 2>&1
xcrun stapler validate "$app" > build/PublishedProof/logs/staple-app.log 2>&1
xattr -w com.apple.quarantine "0083;$(printf '%x' $(date +%s));StemSeparatorDownloadProof;" "$app"
spctl --assess --type execute --verbose=2 "$app" > build/PublishedProof/logs/gatekeeper.log 2>&1
python3 runtime/test_worker.py "$app/Contents/Helpers/StemWorker.app/Contents/MacOS/StemWorker" > build/PublishedProof/logs/offline-inference.log 2>&1
sw_vers > build/PublishedProof/logs/system.txt
