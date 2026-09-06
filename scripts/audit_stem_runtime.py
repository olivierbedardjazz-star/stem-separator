#!/usr/bin/env python3
"""Audit every helper Mach-O and resolve its dyld paths without loading code."""
import json
from pathlib import Path
import re
import subprocess
import sys

MAGIC = {bytes.fromhex(x) for x in ('cffaedfe','feedfacf','cefaedfe','feedface','cafebabe','bebafeca','cafebabf','bfbafeca')}

def version(value):
    numbers = tuple(map(int, value.split('.')))
    return (numbers + (0, 0, 0))[:3]

def system(path):
    return path.startswith(('/usr/lib/', '/System/Library/'))

def run(*args):
    return subprocess.check_output(args, text=True)

def audit(app):
    app = Path(app).resolve()
    failures = []
    binaries = {}
    executables = []
    for path in app.rglob('*'):
        if path.is_symlink():
            if not path.exists() or not path.resolve().is_relative_to(app):
                failures.append('Broken or escaping symlink: ' + str(path.relative_to(app)))
            continue
        if not path.is_file():
            continue
        with path.open('rb') as stream:
            if stream.read(4) not in MAGIC:
                continue
        architectures = run('lipo', '-archs', str(path)).strip().split()
        if 'arm64' not in architectures:
            failures.append('Missing arm64: ' + str(path.relative_to(app)))
            continue
        load = run('otool', '-arch', 'arm64', '-l', str(path))
        deps = re.findall(r'cmd LC_(?:LOAD_DYLIB|LOAD_WEAK_DYLIB|REEXPORT_DYLIB|LOAD_UPWARD_DYLIB)\s+cmdsize \d+\s+name (.*?) \(offset', load)
        rpaths = re.findall(r'cmd LC_RPATH\s+cmdsize \d+\s+path (.*?) \(offset', load)
        minimum = re.findall(r'\bminos ([\d.]+)', load) + re.findall(r'cmd LC_VERSION_MIN_MACOSX\s+cmdsize \d+\s+version ([\d.]+)', load)
        if not minimum or any(version(x) > version('14.0') for x in minimum):
            failures.append('Unsupported or unknown minimum OS: ' + str(path.relative_to(app)))
        executable = 'EXECUTE' in run('otool', '-arch', 'arm64', '-hv', str(path))
        if executable:
            executables.append(path)
        binaries[path] = dict(path=str(path.relative_to(app)), architectures=architectures,
                              minimumOS=minimum, dependencies=deps, rpaths=rpaths, executable=executable)
    if not binaries or not executables:
        failures.append('Missing native payload or executable')
    for path, item in binaries.items():
        resolved = []
        for dep in item['dependencies']:
            if system(dep):
                continue
            candidates = []
            for exe in executables:
                def expand(value, owner):
                    return value.replace('@loader_path', str(owner.parent)).replace('@executable_path', str(exe.parent))
                if dep.startswith('@rpath/'):
                    for owner in (path, exe):
                        for rp in binaries[owner]['rpaths']:
                            candidates.append(Path(expand(rp, owner)) / dep[len('@rpath/'):])
                else:
                    candidates.append(Path(expand(dep, path)))
            found = [p.resolve() for p in candidates if p.is_absolute() and p.is_file() and p.resolve().is_relative_to(app)]
            if not found or not any(p in binaries for p in found):
                failures.append(item['path'] + ': unresolved or external load ' + dep)
            else:
                resolved.append(str(found[0].relative_to(app)))
        item['resolvedDependencies'] = resolved
    return dict(schemaVersion=2, machOCount=len(binaries), failures=failures, binaries=list(binaries.values()))

if __name__ == '__main__':
    report = audit(sys.argv[1])
    print(json.dumps(report, indent=2))
    sys.exit(bool(report['failures']))
