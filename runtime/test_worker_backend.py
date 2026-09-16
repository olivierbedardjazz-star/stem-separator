"""Deterministic CPU-request rejection and unavailable-MPS tests; no GPU work."""
import json, pathlib, subprocess, sys, tempfile, uuid
root=pathlib.Path(__file__).resolve().parents[1]
for case in ['cpu-request','no-gpu','old-os']:
 with tempfile.TemporaryDirectory(prefix='backend-',dir=root/'build/StemRuntime') as d:
  folder=pathlib.Path(d);src=folder/'input.f32le';src.write_bytes(b'\0'*8)
  code="import runpy,sys;sys._MEIPASS=sys.argv[1];"
  if case=='no-gpu':code+="import torch;torch.backends.mps.is_available=lambda:False;"
  if case=='old-os':code+="import platform;platform.mac_ver=lambda:('14.7',('','',''),'arm64');"
  code+="runpy.run_path(sys.argv[2],run_name='__main__')"
  p=subprocess.Popen([sys.executable,'-c',code,str(root/'runtime'),str(root/'runtime/worker/stem_worker.py')],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
  try:
   assert json.loads(p.stdout.readline())['device']=='mps'
   request=dict(protocolVersion=1,type='separate',jobID=str(uuid.uuid4()),input=dict(path=str(src),frames=1,channels=2,sampleRate=44100,sampleType='float32-le',layout='interleaved',byteCount=8),outputDirectory=str(folder/'out'),modelID='htdemucs',device='cpu' if case=='cpu-request' else 'mps')
   p.stdin.write(json.dumps(request)+'\n');p.stdin.flush()
   events=[json.loads(line) for line in p.stdout]
   status=p.wait(timeout=10)
   assert status==(10 if case=='cpu-request' else 21),(case,status,p.stderr.read())
   if case!='cpu-request':assert events[-1]['code']=='mpsUnavailable'
   assert not (folder/'out').exists()
   print('PASS',case,flush=True)
  finally:
   if p.poll() is None:p.kill();p.wait()
