"""Use only a disposable owned disk image; never consume the host's free space."""
import json,pathlib,subprocess,tempfile
from run_suite import BASE, execute, quick

with tempfile.TemporaryDirectory(prefix='capacity-',dir=BASE) as d:
 root=pathlib.Path(d);image=root/'limited.dmg';mount=root/'volume';mount.mkdir()
 subprocess.run(['hdiutil','create','-size','64m','-fs','HFS+','-volname','StemProbeCapacity',str(image)],check=True)
 attached=False
 try:
  subprocess.run(['hdiutil','attach',str(image),'-mountpoint',str(mount),'-nobrowse','-noautoopen'],check=True);attached=True
  dest=mount/'dest';dest.mkdir()
  r1=execute('capacity-destination',14,custom_dest=dest)
  assert r1['errors'] and 'not enough free space' in r1['errors'][0]['message']
  temp=mount/'temp';temp.mkdir()
  r2=execute('capacity-temporary',600,custom_tmp=temp)
  assert r2['errors'] and 'not enough temporary space' in r2['errors'][0]['message']
  recovery_tmp=root/'recovery-temp';recovery_tmp.mkdir()
  crash=quick('crash-stage',recovery_tmp,dest,99)[0]
  subprocess.run(['hdiutil','detach',str(mount)],check=True);attached=False
  quick('recover',recovery_tmp)
  journal=recovery_tmp/'CleanupRecovery'/pathlib.Path(crash['job']).name
  assert journal.exists() and not pathlib.Path(crash['job']).exists()
  subprocess.run(['hdiutil','attach',str(image),'-mountpoint',str(mount),'-nobrowse','-noautoopen'],check=True);attached=True
  assert pathlib.Path(crash['stage']).exists()
  quick('recover',recovery_tmp)
  assert not pathlib.Path(crash['stage']).exists() and not journal.exists()
  (BASE/'capacity.json').write_text(json.dumps({'destinationPreflight':'pass','temporaryPreflight':'pass','unmountedDestinationRecovery':'pass: durable metadata retained, removed after remount','runs':[r1,r2]},indent=2)+'\n')
 finally:
  if attached:
   subprocess.run(['hdiutil','detach',str(mount)],check=True)
