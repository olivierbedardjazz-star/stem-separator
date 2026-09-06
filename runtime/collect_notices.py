"""Collect complete installed-distribution license texts, metadata, and artifact inventory."""
from importlib import metadata
from pathlib import Path
import hashlib, json, shutil, sys
root=Path(__file__).resolve().parents[1]
out=root/'docs/LEGAL/RuntimeLicenses'
out.mkdir(parents=True,exist_ok=True)
items=[]
for dist in sorted(metadata.distributions(),key=lambda d:d.metadata['Name'].lower()):
    name=dist.metadata['Name']; version=dist.version
    files=[]
    for file in dist.files or []:
        if any(t in file.name.lower() for t in ('license','licence','copying','notice','copyright')):
            source=Path(dist.locate_file(file))
            if source.is_file():
                target=out/name/str(file).replace('../','').replace('/','__')
                target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
                files.append(str(target.relative_to(root/'docs/LEGAL')))
    items.append(dict(name=name,version=version,license=dist.metadata.get('License-Expression') or dist.metadata.get('License','Not declared'),licenseFiles=files))
shutil.copy2(root/'build/StemRuntime/portable/python/lib/python3.11/LICENSE.txt',out/'Python-LICENSE.txt')
(root/'runtime/dependency-inventory.json').write_text(json.dumps(items,indent=2))
lines=['# Stem Separator Third-Party Notices','', 'Bundled software and model attribution.','',
'Python 3.11 is distributed under the PSF license and included third-party notices. PyInstaller uses GPL-2.0 with its bootloader exception. Full collected license texts are bundled in RuntimeLicenses.', '',
'Demucs 4.0.1 code is MIT licensed. Model htdemucs checkpoint 955717e8-8726e21a.th comes from https://dl.fbaipublicfiles.com/demucs/hybrid_transformer/955717e8-8726e21a.th . SHA-256: 8726e21a993978c7ba086d3872e7608d7d5bfca646ca4aca459ffda844faa8b4.', '',
'HTDemucs checkpoint 955717e8 is distributed under the historical MIT declaration at https://huggingface.co/adefossez/HTDemucs/blob/bf35a81b663819a8255c8fefee17f9d812b786b5/README.md . Copyright (c) Meta Platforms, Inc. and affiliates. The complete MIT notice is included as HTDemucs-MIT.txt.', '',
'Corresponding sources and library modification information are provided in RUNTIME_SOURCE_AND_RELINKING.md and the source archive alongside each release.', '',
'Build dependencies are included in this inventory as well as runtime dependencies. Packaging does not imply that every listed package is executed. Native libraries may have additional notices in the complete texts. See RUNTIME_SOURCE_AND_RELINKING.md for source availability and library modification information.', '']
for i in items:
    lines.append(i['name']+' '+i['version']+' — '+i['license'].split('\n')[0][:160])
lines+=['','Sparkle: pinned revision 79bc9e872948e47877e76f194cb0c8e0412b0b90, MIT. See included Sparkle-LICENSE.txt.','', 'To inspect full notices, use Show Package Contents on Stem Separator.app, then Contents/Resources/RuntimeLicenses.']
(root/'docs/LEGAL/THIRD_PARTY_NOTICES.md').write_text('\n'.join(lines)+'\n')
