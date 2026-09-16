"""Compile production logic with one explicit, test-only workspace-root seam."""
import pathlib,subprocess,hashlib,json
root=pathlib.Path(__file__).resolve().parents[2];out=root/'build/Performance';out.mkdir(exist_ok=True)
src=root/'TemplateApp/Separation/Infrastructure/JobWorkspace.swift'
s=src.read_text();old='static var root: URL { FileManager.default.temporaryDirectory.appendingPathComponent("StemSeparatorJobs", isDirectory: true) }'
new='static var root: URL { URL(fileURLWithPath: ProcessInfo.processInfo.environment["STEM_PROBE_TEMP"]!).appendingPathComponent("StemSeparatorJobs", isDirectory: true) }'
assert s.count(old)==1
s=s.replace(old,new)
journal='static var journalRoot: URL { FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("com.oliviergrenierbedard.stemseparator/CleanupRecovery", isDirectory: true) }'
assert s.count(journal)==1
s=s.replace(journal, 'static var journalRoot: URL { URL(fileURLWithPath: ProcessInfo.processInfo.environment["STEM_PROBE_TEMP"]!).appendingPathComponent("CleanupRecovery", isDirectory: true) }')
copy=out/'JobWorkspace.isolated.swift';copy.write_text(s)
files=[root/'TemplateApp/Separation/Domain/SeparationJob.swift']+[p if p!=src else copy for p in sorted((root/'TemplateApp/Separation/Infrastructure').glob('*.swift'))]+[root/'TemplateApp/Separation/Application/SeparationSession.swift',root/'Tests/Performance/NativeProbe.swift']
subprocess.run(['xcrun','swiftc','-O','-swift-version','6','-target','arm64-apple-macos15.1',*[str(p) for p in files],'-o',str(out/'NativeProbe')],check=True)
(out/'source-manifest.json').write_text(json.dumps({'testSeam':'Only JobWorkspace.root overridden to mandatory STEM_PROBE_TEMP; shipping source untouched','sources':{str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files},'originalJobWorkspaceSHA256':hashlib.sha256(src.read_bytes()).hexdigest()},indent=2)+'\n')
