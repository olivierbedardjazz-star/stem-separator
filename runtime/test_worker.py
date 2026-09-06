import json, math, os, struct, subprocess, sys, tempfile, uuid, pathlib, time
worker = pathlib.Path(sys.argv[1]).resolve()
with tempfile.TemporaryDirectory(prefix='proof-', dir='build/StemRuntime') as d:
    root = pathlib.Path(d).resolve()
    src = root/'input.f32le'
    frames = 44100 * 14
    with src.open('wb') as f:
        for i in range(frames):
            v = 0.1 * math.sin(i * 440 * 2 * math.pi / 44100)
            f.write(struct.pack('<ff', v, v))
    job = str(uuid.uuid4())
    env = {'PATH':'/usr/bin:/bin','HOME':str(root),'TMPDIR':str(root),'PYTHONNOUSERSITE':'1','OMP_NUM_THREADS':'4'}
    command = ['/usr/bin/sandbox-exec', '-p', '(version 1) (allow default) (deny network*)', str(worker)]
    p = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=env, cwd=root)
    line = p.stdout.readline()
    if not line: raise RuntimeError(p.stderr.read())
    ready = json.loads(line); assert ready['type'] == 'ready', ready
    request = dict(protocolVersion=1,type='separate',jobID=job,
                   input=dict(path=str(src),frames=frames,channels=2,sampleRate=44100,layout='interleaved',sampleType='float32-le',byteCount=frames*8),
                   outputDirectory=str(root/'worker-output'),modelID='htdemucs',device='cpu')
    p.stdin.write(json.dumps(request)+'\n');p.stdin.flush()
    events=[]
    for line in p.stdout:
        print(line.strip(), flush=True);events.append(json.loads(line))
    status=p.wait(timeout=30)
    print('exit', status, 'stderr', p.stderr.read()[-2000:], flush=True)
    assert status == 0
    progress=[e for e in events if e['type']=='progress']
    assert progress[-1]['completedUnits'] == progress[-1]['totalUnits'] == 3
    result=events[-1]; assert result['type']=='result' and len(result['stems'])==4
    for s in result['stems']:
        data=(root/'worker-output'/s['file']).read_bytes()
        assert len(data)==frames*8
        assert all(math.isfinite(x[0]) for x in struct.iter_unpack('<f',data))
    print('PASS: frozen worker, empty HOME, minimal PATH, network denied, four finite stereo stems.', flush=True)
