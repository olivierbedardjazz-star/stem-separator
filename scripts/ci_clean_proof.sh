#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p build/CIProof/logs
[[ $(uname -m) == arm64 ]] || { print -u2 'Expected Apple Silicon runner'; exit 1; }
xcodebuild -version > build/CIProof/logs/toolchain.txt
sw_vers >> build/CIProof/logs/toolchain.txt
git rev-parse HEAD > build/CIProof/logs/source-sha.txt
scripts/bootstrap_build_tools.sh > build/CIProof/logs/build-tools.log 2>&1
scripts/build_stem_runtime.sh > build/CIProof/logs/runtime-build.log 2>&1
python=build/StemRuntime/portable-venv/bin/python
"$python" -m unittest discover -s Tests/Release > build/CIProof/logs/release-tests.log 2>&1
"$python" - <<'PY'
import subprocess,sys
from pathlib import Path
worker='build/StemRuntime/dist/StemWorker.app/Contents/MacOS/StemWorker'
for script in ['test_worker.py','test_worker_control.py']:
    with Path('build/CIProof/logs/'+script+'.log').open('w') as log:
        subprocess.run([sys.executable,'runtime/'+script,worker],stdout=log,stderr=subprocess.STDOUT,check=True,timeout=300)
PY
build/BuildTools/xcodegen/bin/xcodegen generate > build/CIProof/logs/project-generation.log 2>&1
git diff --exit-code -- TemplateApp.xcodeproj/project.pbxproj > build/CIProof/logs/project-drift.log
xcodebuild build -project TemplateApp.xcodeproj -scheme TemplateApp -configuration Release -destination 'platform=macOS,arch=arm64' -derivedDataPath build/CIProof/DerivedData CODE_SIGNING_ALLOWED=NO > build/CIProof/logs/release-build.log 2>&1
xcodebuild test -project TemplateApp.xcodeproj -scheme TemplateApp -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath build/CIProof/DerivedData -only-testing:StemSeparatorTests CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- ENABLE_HARDENED_RUNTIME=NO ENABLE_TESTABILITY=YES > build/CIProof/logs/native-tests.log 2>&1
scripts/verify_bundled_legal_documents.sh 'build/CIProof/DerivedData/Build/Products/Release/Stem Separator.app' > build/CIProof/logs/legal-proof.log
scripts/verify_bundled_notices.sh 'build/CIProof/DerivedData/Build/Products/Release/Stem Separator.app' >> build/CIProof/logs/legal-proof.log
cp build/StemRuntime/runtime-audit.json build/CIProof/logs/runtime-audit.json
