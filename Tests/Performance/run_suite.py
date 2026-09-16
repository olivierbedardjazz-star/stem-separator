"""Development-only baseline against unchanged native sources and signed worker."""
import argparse, array, hashlib, json, math, os, pathlib, queue, re, shutil, subprocess, tempfile, threading, time, wave
ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = ROOT / 'build/Performance'
PROBE = BASE / 'NativeProbe'
WORKER = ROOT / 'release-evidence/0.1.1-101/Stem Separator.app/Contents/Helpers/StemWorker.app/Contents/MacOS/StemWorker'

def fixture(path, seconds):
    # Fixed, non-silent synthetic stereo mixture; bounded generation memory.
    samples = array.array('h')
    for i in range(44100):
        t = i / 44100
        samples.extend((int(7000*math.sin(2*math.pi*220*t)+2000*math.sin(2*math.pi*997*t)), int(6500*math.sin(2*math.pi*330*t)+1500*math.sin(2*math.pi*1103*t))))
    with wave.open(str(path), 'wb') as f:
        f.setparams((2, 2, 44100, 0, 'NONE', 'not compressed'))
        for _ in range(seconds): f.writeframesraw(samples.tobytes())

def size(root):
    return sum(p.stat().st_size for p in root.rglob('*') if p.is_file() and not p.is_symlink()) if root.exists() else 0

def tree(pid):
    rows = subprocess.check_output(['ps','-axo','pid=,ppid=,rss='], text=True)
    data = {int(a):(int(b),int(c)*1024) for a,b,c in (r.split() for r in rows.splitlines())}
    found={pid}
    while True:
        new={p for p,(pp,rss) in data.items() if pp in found}
        if new <= found: break
        found |= new
    return {p:data[p][1] for p in found if p in data}

def swap_mib():
    value=subprocess.check_output(['sysctl','-n','vm.swapusage'],text=True)
    match=re.search(r'used\s*=\s*([0-9.]+)([MG])',value)
    return float(match[1])*(1024 if match[2]=='G' else 1)

def env_for(tmp):
    return dict(os.environ, TMPDIR=str(tmp)+'/', STEM_PROBE_TEMP=str(tmp), PYTHONNOUSERSITE='1')

def execute(label, seconds, cancel='none', profile=False, custom_tmp=None, custom_dest=None, expected_error=None, output_mode="stems"):
    with tempfile.TemporaryDirectory(prefix='session-', dir=BASE) as d:
        root=pathlib.Path(d); tmp=custom_tmp or root/'tmp'; dest=custom_dest or root/'output'
        tmp.mkdir(exist_ok=True);dest.mkdir(exist_ok=True)
        src=root/'synthetic.wav';fixture(src,seconds)
        original=hashlib.sha256(src.read_bytes()).hexdigest()
        args=[str(PROBE),'session',str(src),str(dest),str(WORKER),cancel,output_mode]
        initial_swap=swap_mib(); last_system_check=0
        start=time.monotonic(); events=[]; samples=[]; q=queue.Queue(); stderr_path=BASE/(label+'.stderr.log')
        with stderr_path.open('w') as err:
            p=subprocess.Popen(args,stdout=subprocess.PIPE,stderr=err,text=True,env=env_for(tmp),start_new_session=True)
            def read():
                for line in p.stdout: q.put(json.loads(line))
            reader=threading.Thread(target=read, daemon=True);reader.start();sample_process=None;host_sample=None;abort=None
            try:
                while p.poll() is None or reader.is_alive() or not q.empty():
                    while not q.empty():
                        event=q.get(); events.append(event)
                        if event.get('stage')=='writing' and profile and host_sample is None:
                            host_sample=subprocess.Popen(['/usr/bin/sample',str(p.pid),'3','10','-file',str(BASE/(label+'.host.sample.txt'))],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
                        if event.get('stage')=='separating' and event.get('fraction',0)>0 and profile and sample_process is None:
                            members=tree(p.pid)
                            if len(members)>1:
                                worker_pid=max((pid for pid in members if pid!=p.pid),key=lambda pid:members[pid])
                                sample_process=subprocess.Popen(['/usr/bin/sample',str(worker_pid),'5','10','-file',str(BASE/(label+'.sample.txt'))],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
                    members=tree(p.pid) if p.poll() is None else {}
                    rss=sum(members.values()); elapsed=time.monotonic()-start
                    samples.append({'seconds':elapsed,'rssTreeBytes':rss,'rssHostBytes':members.get(p.pid,0),'rssLargestChildBytes':max([r for pid,r in members.items() if pid!=p.pid] or [0]),'tempBytes':size(tmp),'outputBytes':size(dest)})
                    if rss>12*1024**3: abort='12 GiB RSS safety threshold'
                    if elapsed>1800: abort='30 minute timeout'
                    if shutil.disk_usage(BASE).free<8*1024**3: abort='8 GiB free disk safety threshold'
                    if elapsed-last_system_check>5:
                        last_system_check=elapsed
                        if swap_mib()-initial_swap>1024:abort='1 GiB system swap growth; shared-machine interference or memory pressure'
                    if abort:
                        (BASE/(label+'.interrupted.json')).write_text(json.dumps({'reason':abort,'events':events,'samples':samples},indent=2)+'\n')
                        raise RuntimeError(abort)
                    time.sleep(.25)
                reader.join(timeout=2)
                if sample_process: sample_process.wait(timeout=15)
                if host_sample: host_sample.wait(timeout=15)
            finally:
                if p.poll() is None:
                    import signal
                    os.killpg(p.pid,signal.SIGTERM)
                    try:p.wait(timeout=5)
                    except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
        assert hashlib.sha256(src.read_bytes()).hexdigest()==original,'Input changed'
        outputs=[]
        for wav in dest.rglob('*.wav'):
            with wave.open(str(wav),'rb') as f:
                assert (f.getnchannels(),f.getsampwidth(),f.getframerate(),f.getnframes())==(2,3,44100,seconds*44100)
                outputs.append(wav.name)
        errors=[e for e in events if e['type']=='error']
        if expected_error:
            assert errors and expected_error in errors[0]['message'] and not outputs,(label,errors,outputs)
        if cancel=='none' and custom_tmp is None and custom_dest is None and not expected_error:
            assert not errors and len(outputs)==(1 if output_mode=="karaoke" else 4),(label,errors,outputs)
        assert not ((tmp/'CleanupRecovery').exists() and list((tmp/'CleanupRecovery').iterdir())), 'Durable journal left after normal job'
        jobs=tmp/'StemSeparatorJobs'; remaining=list(jobs.iterdir()) if jobs.exists() else []
        assert not remaining,('Unexpected leftover jobs',remaining)
        assert not list(dest.glob('.stem-separator-*')),'Unexpected staging left'
        if cancel!='none':assert errors and not outputs,(label,errors,outputs)
        first={}
        for e in events:
            key=e.get('stage',e['type'])
            if key not in first:first[key]=e['time']
        def diff(a,b):return round(first[b]-first[a],3) if a in first and b in first else None
        result={'label':label,'durationSeconds':seconds,'profiled':profile,'cancel':cancel,'exitCode':p.returncode,'separationSeconds':diff('start','end'),'preparationSeconds':diff('preparing','loadingModel'),'modelLoadingSeconds':diff('loadingModel','separating'),'inferenceSeconds':diff('separating','writing'),'writingAndCommitSeconds':diff('writing','result'),'maxSampledTreeRSSBytes':max(s['rssTreeBytes'] for s in samples),'maxSampledHostRSSBytes':max(s['rssHostBytes'] for s in samples),'maxSampledChildRSSBytes':max(s['rssLargestChildBytes'] for s in samples),'maxObservedTempBytes':max(s['tempBytes'] for s in samples),'maxObservedOutputBytes':max(s['outputBytes'] for s in samples),'remainingJobs':len(remaining),'outputs':outputs,'errors':errors,'fixtureSHA256':original}
        (BASE/(label+'.json')).write_text(json.dumps({'summary':result,'events':events,'samples':samples},indent=2)+'\n')
        print(json.dumps(result),flush=True)
        return result

def quick(mode, tmp, dest=None, code=0):
    p=subprocess.run([str(PROBE),mode]+([str(dest)] if dest else []),env=env_for(tmp),capture_output=True,text=True,timeout=30)
    assert p.returncode==code,(mode,p.returncode,p.stderr)
    return [json.loads(line) for line in p.stdout.splitlines()]

def storage():
    # Current assertions live beside the historical measurements; do not expect old defects.
    import runpy
    runpy.run_path(str(ROOT/'Tests/Performance/qualify_cleanup.py'), run_name='__main__')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('mode',choices=['baseline','storage','profile']);args=parser.parse_args()
    BASE.mkdir(exist_ok=True)
    if args.mode=='storage':storage()
    elif args.mode=='profile':execute('profile',60,profile=True)
    else:
        for label,seconds in [('warmup',14),('three-minute-1',180),('three-minute-2',180),('three-minute-3',180),('ten-minute',600),('twenty-minute',1200)]:execute(label,seconds)
        for mode in ['inference','writing']:execute('cancel-'+mode,14,cancel=mode)
