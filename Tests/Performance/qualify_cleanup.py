"""Fault-injection proof using isolated, disposable roots and the native cleanup code."""
import json, pathlib, shutil, tempfile
from run_suite import BASE, quick
results=[]
with tempfile.TemporaryDirectory(prefix='cleanup-proof-',dir=BASE) as d:
 root=pathlib.Path(d);tmp=root/'tmp';tmp.mkdir();dest=root/'dest';dest.mkdir()
 lease=quick('lease-tests',tmp)[0]
 assert lease['remainingAfter100']==0 and lease['liveProtected'] and lease['unmarkedProtected']
 results.append('100 jobs, live lock and unmarked directory protection')
 crash=quick('crash-stage',tmp,dest,99)[0]
 journal=tmp/'CleanupRecovery'/pathlib.Path(crash['job']).name
 shutil.rmtree(crash['job'])  # Simulate macOS purging all temporary audio and metadata.
 quick('recover',tmp)
 assert not pathlib.Path(crash['stage']).exists() and not journal.exists()
 results.append('durable recovery after total temporary workspace purge')
 crash=quick('crash-stage',tmp,dest,99)[0];journal=tmp/'CleanupRecovery'/pathlib.Path(crash['job']).name
 dest.chmod(0o500)
 try:quick('recover',tmp)
 finally:dest.chmod(0o700)
 assert journal.exists() and pathlib.Path(crash['stage']).exists()
 assert not pathlib.Path(crash['job']).exists()
 quick('recover',tmp)
 assert not journal.exists() and not pathlib.Path(crash['stage']).exists()
 results.append('denied destination deletion retains durable retry and removes local workspace; retry succeeds')
 for attack in ['owner','symlink','bookmark']:
  crash=quick('crash-stage',tmp,dest,99)[0];stage=pathlib.Path(crash['stage']);job=pathlib.Path(crash['job']);journal=tmp/'CleanupRecovery'/job.name
  if attack=='owner':(stage/'.stem-separator-owner').write_text('unrelated-owner')
  if attack=='symlink':
   saved=dest/'unrelated';stage.rename(saved);stage.symlink_to(saved,target_is_directory=True)
  if attack=='bookmark':
   record=journal/'staging.json';data=json.loads(record.read_text());data['bookmark']='AA==';record.write_text(json.dumps(data))
  quick('recover',tmp)
  assert stage.exists() and (stage/'partial.wav').stat().st_size==1024*1024 and journal.exists()
  assert not job.exists()
  if attack=='symlink':stage.unlink();shutil.rmtree(saved)
  else:shutil.rmtree(stage)
  shutil.rmtree(journal)
  results.append(attack+' protected, metadata retained, local workspace removed')
 crash=quick('crash-stage',tmp,dest,99)[0];job=pathlib.Path(crash['job']);journal=tmp/'CleanupRecovery'/job.name
 (job/'working.pcm').write_bytes(b'x'*1024);job.chmod(0o500)
 try:quick('recover',tmp)
 finally:job.chmod(0o700)
 assert journal.exists() and (job/'.owner').exists()
 quick('recover',tmp)
 assert not job.exists() and not journal.exists()
 results.append('workspace permissions failure preserves ownership, retry succeeds')
(BASE/'cleanup-qualification.json').write_text(json.dumps({'result':'pass','cases':results},indent=2)+'\n')
print(json.dumps(results))
