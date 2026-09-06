#!/usr/bin/env python3
"""Local-only distribution pipeline with artifact-bound handoffs and immutable assets."""
import argparse
import datetime
import fcntl
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET
from release_record import fingerprint, write_record, verify_record

ROOT=Path(__file__).resolve().parents[1]
CONFIG=json.loads((ROOT/'Packaging/release-config.json').read_text())

def command(args, **kwargs):
    return subprocess.run([str(a) for a in args],check=True,**kwargs)

def output(args):
    return command(args,capture_output=True,text=True).stdout.strip()

def project_version():
    text=(ROOT/'project.yml').read_text()
    return re.search(r'MARKETING_VERSION: ([\d.]+)',text)[1],re.search(r'CURRENT_PROJECT_VERSION: (\d+)',text)[1]

def clean_source():
    if output(['git','status','--porcelain','--untracked-files=no']):
        raise RuntimeError('Commit reviewed source changes before release work')
    return output(['git','rev-parse','HEAD'])

class Release:
    def __init__(self):
        self.version,self.build=project_version()
        self.root=ROOT/'release-evidence'/f'{self.version}-{self.build}'
        self.root.mkdir(parents=True,exist_ok=True)
        self.app=self.root/CONFIG['appName']
        self.tag=f'v{self.version}'
        self.base=f"{CONFIG['artifactStem']}-{self.version}-{self.build}-arm64"
        self.assets=self.root/'assets'
        self.assets.mkdir(exist_ok=True)
        self.environment=dict(os.environ,APP_PATH=str(self.app),APP_NAME=CONFIG['appName'],
                              CODE_SIGN_IDENTITY=CONFIG['signingIdentity'],TEAM_ID=CONFIG['teamID'])
    def run(self,*args):
        return command(args,env=self.environment)
    def script(self,name,*args):
        self.run(ROOT/'scripts'/name,*args)
    def require(self,stage,artifact=None):
        return verify_record(self.root/(stage+'.json'),artifact or self.app)
    def record(self,stage,artifact=None,**evidence):
        return write_record(self.root/(stage+'.json'),artifact or self.app,evidence)
    def check_identity(self):
        info=plistlib.loads((self.app/'Contents/Info.plist').read_bytes())
        expected={'CFBundleIdentifier':CONFIG['bundleID'],'CFBundleVersion':self.build,
                  'CFBundleShortVersionString':self.version,'SUFeedURL':CONFIG['feedURL']}
        for key,value in expected.items():
            if info.get(key)!=value:raise RuntimeError('App identity mismatch: '+key)
    def archive(self):
        sha=clean_source()
        archive=self.root/'archive.xcarchive'
        if archive.exists() or self.app.exists():raise RuntimeError('Candidate already exists; use a new build for changed source')
        self.run('xcodebuild','archive','-project',ROOT/CONFIG['project'],'-scheme',CONFIG['scheme'],
                 '-configuration','Release','-destination','generic/platform=macOS','-archivePath',archive,
                 '-derivedDataPath',ROOT/'build/DistributionDerivedData','CODE_SIGNING_ALLOWED=NO')
        self.run('ditto',archive/'Products/Applications'/CONFIG['appName'],self.app)
        self.check_identity()
        self.record('archived',sourceSHA=sha,configurationSHA=fingerprint(ROOT/'Packaging/release-config.json'),
                    modelSHA=json.loads((ROOT/'runtime/provenance.json').read_text())['model']['sha256'],xcode=output(['xcodebuild','-version']))
    def sign(self):
        self.require('archived');self.check_identity()
        self.script('sign_stem_runtime.sh')
        self.script('sign_bundled_runtime_executables.sh')
        self.run(sys.executable,ROOT/'scripts/create_runtime_manifest.py',self.app/'Contents/Helpers/StemWorker.app',
                 self.app/'Contents/Resources/StemRuntimeMetadata/manifest.json')
        self.run('codesign','--force','--timestamp','--options','runtime','--sign',CONFIG['signingIdentity'],self.app)
        self.run('codesign','--verify','--deep','--strict',self.app)
        self.script('verify_stem_runtime_signatures.sh',self.app)
        self.script('verify_bundled_notices.sh',self.app)
        self.script('verify_bundled_legal_documents.sh',self.app)
        worker=self.app/'Contents/Helpers/StemWorker.app/Contents/MacOS/StemWorker'
        for test in ('test_worker.py','test_worker_control.py'):
            command([sys.executable,ROOT/'runtime'/test,worker],env=self.environment,timeout=300)
        self.record('signed',archiveRecord=fingerprint(self.root/'archived.json'))
    def dmg(self,provisional=False):
        self.require('signed' if provisional else 'app-stapled')
        path=(self.root/'provisional.dmg') if provisional else self.assets/(self.base+'.dmg')
        if path.exists():raise RuntimeError('Refusing to overwrite DMG')
        if not provisional:self.run('xcrun','stapler','validate',self.app)
        environment=dict(self.environment,STEM_DMG_APP_PATH=str(self.app),
                         STEM_DMG_BACKGROUND=str(ROOT/'Packaging/InstallerAssets/reference-installer-background.tiff'))
        command([ROOT/'build/PackagingVenv/bin/dmgbuild','-s',ROOT/'Packaging/dmg_settings.py',CONFIG['productName'],path],env=environment)
        self.run('codesign','--force','--timestamp','--sign',CONFIG['signingIdentity'],path)
        self.record('provisional-dmg' if provisional else 'final-dmg',path,appSHA=fingerprint(self.app))
    def install_proof(self):
        self.require('signed');self.require('provisional-dmg',self.root/'provisional.dmg')
        mount=self.root/'mount';mount.mkdir(exist_ok=True)
        installed=self.root/'Installed Applications'/CONFIG['appName']
        if installed.exists():raise RuntimeError('Install proof destination already exists')
        self.run('hdiutil','attach','-readonly','-nobrowse','-mountpoint',mount,self.root/'provisional.dmg')
        try:self.run('ditto',mount/CONFIG['appName'],installed)
        finally:self.run('hdiutil','detach',mount)
        self.run('codesign','--verify','--deep','--strict',installed)
        if fingerprint(installed)!=fingerprint(self.app):raise RuntimeError('Installed app differs from candidate')
        command([sys.executable,ROOT/'runtime/test_worker.py',installed/'Contents/Helpers/StemWorker.app/Contents/MacOS/StemWorker'],timeout=300)
        self.run('open','-n',installed)
        self.record('provisional-installed',scope='Mounted DMG, copied app to isolated installation directory, verified signature/bytes, offline inference and requested UI launch. Not Finder drag-and-drop or a second physical Mac.')
    def require_ci(self):
        archived=json.loads((self.root/'archived.json').read_text())
        ci=json.loads((self.root/'ci-proof.json').read_text())
        live=json.loads(output(['gh','api',f"repos/{CONFIG['repository']}/actions/runs/{ci['id']}"]))
        if live['head_sha']!=archived['evidence']['sourceSHA'] or live['conclusion']!='success' or live['name']!='Clean macOS build':
            raise RuntimeError('Successful exact-source CI proof required after local installation proof')
        return live
    def notarize(self,kind):
        self.require_ci()
        app_kind=kind=='app'
        if app_kind:
            self.require('provisional-installed');artifact=self.root/'notary-submission.zip'
            if not artifact.exists():self.run('ditto','-c','-k','--keepParent','--sequesterRsrc',self.app,artifact)
        else:
            artifact=self.assets/(self.base+'.dmg');self.require('final-dmg',artifact)
        submission=self.root/(kind+'-submission.json')
        if not submission.exists():
            result=json.loads(output(['xcrun','notarytool','submit',artifact,'--keychain-profile',CONFIG['notaryProfile'],'--output-format','json']))
            submission.write_text(json.dumps(dict(id=result['id'],artifactSHA=fingerprint(artifact),appSHA=fingerprint(self.app)),indent=2)+'\n')
        identity=json.loads(submission.read_text())
        if identity['artifactSHA']!=fingerprint(artifact) or identity['appSHA']!=fingerprint(self.app):raise RuntimeError('Submitted bytes changed')
        result=json.loads(output(['xcrun','notarytool','info',identity['id'],'--keychain-profile',CONFIG['notaryProfile'],'--output-format','json']))
        (self.root/(kind+'-notary-status.json')).write_text(json.dumps(result,indent=2)+'\n')
        if result['status']!='Accepted':
            print('Apple status:',result['status'],'Submission:',identity['id'],flush=True)
            return
        self.run('xcrun','notarytool','log',identity['id'],'--keychain-profile',CONFIG['notaryProfile'],self.root/(kind+'-notary-log.json'))
        self.record(kind+'-accepted',self.app if app_kind else artifact,submissionID=identity['id'],submissionSHA=identity['artifactSHA'])
    def staple(self,kind):
        artifact=self.app if kind=='app' else self.assets/(self.base+'.dmg')
        self.require(kind+'-accepted',artifact)
        self.run('xcrun','stapler','staple',artifact);self.run('xcrun','stapler','validate',artifact)
        self.run('codesign','--verify','--strict',artifact)
        if kind=='app':self.run('spctl','--assess','--type','execute','--verbose=2',artifact)
        self.record(kind+'-stapled',artifact,acceptedRecord=fingerprint(self.root/(kind+'-accepted.json')))
    def sparkle(self):
        self.require('app-stapled');self.require('dmg-stapled',self.assets/(self.base+'.dmg'))
        self.script('ensure_sparkle_keys.sh')
        binpath=Path(output([ROOT/'scripts/locate_sparkle_bin.sh']))
        archive=self.assets/(self.base+'.zip')
        if archive.exists():raise RuntimeError('Refusing to overwrite update archive')
        self.run('ditto','-c','-k','--keepParent','--sequesterRsrc',self.app,archive)
        staging=self.root/'appcast-staging';staging.mkdir()
        self.run('cp',archive,staging/archive.name)
        self.run(binpath/'generate_appcast',staging,'--account',CONFIG['sparkleAccount'],'--maximum-deltas','0',
                 '--download-url-prefix',f"https://github.com/{CONFIG['repository']}/releases/download/{self.tag}/")
        self.run('cp',staging/'appcast.xml',self.assets/'appcast.xml')
        # Explicitly sign the feed as required by SURequireSignedFeed, even when
        # the generator version also signs it automatically.
        self.run(binpath/'sign_update','--account',CONFIG['sparkleAccount'],self.assets/'appcast.xml')
        tree=ET.parse(self.assets/'appcast.xml');enclosures=tree.findall('.//enclosure')
        if len(enclosures)!=1 or enclosures[0].get('url')!=f"https://github.com/{CONFIG['repository']}/releases/download/{self.tag}/{archive.name}":
            raise RuntimeError('Unexpected update enclosure')
        if int(enclosures[0].get('length','0'))!=archive.stat().st_size:raise RuntimeError('Incorrect update length')
        for path in [archive,self.assets/'appcast.xml']:self.record(path.name,path)
        self.run(sys.executable,ROOT/'scripts/prepare_corresponding_sources.py',self.assets/'Corresponding-Sources.tar.gz')
        self.run(binpath/'sign_update','--account',CONFIG['sparkleAccount'],'--verify',self.assets/'appcast.xml')
        self.run(binpath/'sign_update','--account',CONFIG['sparkleAccount'],'--verify',archive,enclosures[0].get('{http://www.andymatuschak.org/xml-namespaces/sparkle}edSignature'))
        checksums=''.join(f'{fingerprint(p)}  {p.name}\n' for p in sorted(self.assets.iterdir()) if p.is_file())
        (self.assets/'SHA256SUMS.txt').write_text(checksums)
        self.record('assets',self.assets)
    def publish(self):
        self.require('assets',self.assets)
        archive_record=json.loads((self.root/'archived.json').read_text())
        sha=archive_record['evidence']['sourceSHA']
        if clean_source()!=sha:raise RuntimeError('Publication source changed')
        repo=CONFIG['repository']
        existing=subprocess.run(['gh','release','view',self.tag,'--repo',repo],capture_output=True)
        if existing.returncode==0:raise RuntimeError('Release exists; never overwrite published bytes')
        notes=self.root/'release-notes.md'
        notes.write_text(f'''Stem Separator {self.version}\n\nFree offline four-stem separation for Apple Silicon Macs running macOS 14 or later.\n\nDownload **{self.base}.dmg**, open it, and drag Stem Separator to Applications. Python and the model are included. Choose an audio file, click Separate Stems, and select your output folder.\n\nThe ZIP and appcast are used by the built-in updater. Third-party notices are available from Help.\n''')
        self.run('gh','release','create',self.tag,*sorted(self.assets.iterdir()),'--draft','--repo',repo,'--target',sha,'--title',f'Stem Separator {self.version}','--notes-file',notes)
        self.run('gh','release','edit',self.tag,'--repo',repo,'--draft=false','--latest')
        downloaded=self.root/'downloaded';downloaded.mkdir(exist_ok=True)
        for path in self.assets.iterdir():
            url=f'https://github.com/{repo}/releases/download/{self.tag}/{path.name}'
            self.run('curl','--fail','--location','--retry','5',url,'-o',downloaded/path.name)
            if fingerprint(path)!=fingerprint(downloaded/path.name):raise RuntimeError('Published asset bytes mismatch')
        self.record('published',self.assets,url=f'https://github.com/{repo}/releases/tag/{self.tag}')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('phase',choices=['archive','sign','provisional-dmg','install-proof','notarize-app','staple-app','final-dmg','notarize-dmg','staple-dmg','sparkle','publish'])
    args=parser.parse_args();os.chdir(ROOT);release=Release()
    with (release.root/'execution.lock').open('w') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        phase=args.phase
        if phase=='archive':release.archive()
        elif phase=='sign':release.sign()
        elif phase.endswith('-dmg') and phase in ('provisional-dmg','final-dmg'):release.dmg(phase=='provisional-dmg')
        elif phase=='install-proof':release.install_proof()
        elif phase.startswith('notarize-'):release.notarize(phase.split('-')[1])
        elif phase.startswith('staple-'):release.staple(phase.split('-')[1])
        elif phase=='sparkle':release.sparkle()
        elif phase=='publish':release.publish()

if __name__=='__main__':main()
