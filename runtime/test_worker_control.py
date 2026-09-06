"""Worker control-plane proof, including parent disappearance during model loading."""
import json, pathlib, subprocess, sys, tempfile, time, uuid
worker=pathlib.Path(sys.argv[1]).resolve()
for mode in ('cancel','parentEOF','invalid'):
    with tempfile.TemporaryDirectory(prefix='control-',dir='build/StemRuntime') as d:
        root=pathlib.Path(d).resolve();src=root/'input.f32le';src.write_bytes(b'\0'*(44100*8))
        p=subprocess.Popen([str(worker)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,
            env={'PATH':'/usr/bin:/bin','HOME':str(root),'TMPDIR':str(root)})
        assert json.loads(p.stdout.readline())['type']=='ready'
        job=str(uuid.uuid4())
        request=dict(protocolVersion=1,type='separate',jobID=job,
                     input=dict(path=str(src),frames=0 if mode=='invalid' else 44100,channels=2,sampleRate=44100,layout='interleaved',sampleType='float32-le',byteCount=44100*8),
                     outputDirectory=str(root/'out'),modelID='htdemucs',device='cpu')
        p.stdin.write(json.dumps(request)+'\n');p.stdin.flush()
        if mode!='invalid':
            assert json.loads(p.stdout.readline())['stage']=='loadingModel'
            if mode=='cancel':
                p.stdin.write(json.dumps(dict(protocolVersion=1,type='cancel',jobID=job))+'\n');p.stdin.flush()
            else:p.stdin.close()
        started=time.monotonic();code=p.wait(timeout=5)
        assert code==(10 if mode=='invalid' else 130),(mode,code,p.stderr.read())
        assert not (root/'out').exists()
        print('PASS',mode,'exit',code,'latency',round(time.monotonic()-started,3),flush=True)
