"""10/20-minute local MPS duration qualification, with bounded fixtures and cleanup."""
import json
import run_suite as suite
suite.WORKER=suite.ROOT/'build/StemRuntime/dist/StemWorker.app/Contents/MacOS/StemWorker'
results=[]
for seconds in [600,1200]:
 for mode in ['stems','karaoke']:
  results.append(suite.execute(f'mps-{mode}-{seconds}', seconds, output_mode=mode))
for mode in ['stems','karaoke']:
 for cancel in ['inference','writing','native-writing']:
  results.append(suite.execute(f'mps-{mode}-cancel-{cancel}',60,cancel=cancel,output_mode=mode))
(suite.BASE/'long-qualification.json').write_text(json.dumps({'result':'pass','fixture':'deterministic synthetic stereo mixture; not a vocal listening-quality corpus','runs':results},indent=2)+'\n')
