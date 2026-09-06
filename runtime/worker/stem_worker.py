"""Private JSON-lines worker. No network, audio decoders, shell, or user Python."""
import hashlib
import json
import math
import os
from pathlib import Path
import sys
import threading
import uuid

VERSION = 1
MODEL_HASH = '8726e21a993978c7ba086d3872e7608d7d5bfca646ca4aca459ffda844faa8b4'
MODEL_FILE = '955717e8-8726e21a.th'
MAX_FRAMES = 44100 * 20 * 60
job_id = None
sequence = 0

def emit(kind, **values):
    global sequence
    event = dict(protocolVersion=VERSION, type=kind, **values)
    if job_id:
        sequence += 1
        event.update(jobID=job_id, sequence=sequence)
    print(json.dumps(event, allow_nan=False), flush=True)

def control():
    # EOF means the app disappeared. Exit even during a native inference call.
    while True:
        line = sys.stdin.buffer.readline(65537)
        if not line:
            os._exit(130)
        try:
            value = json.loads(line)
            if value.get('type') == 'cancel' and value.get('jobID') == job_id:
                os._exit(130)
        except Exception:
            os._exit(10)

class ProgressPool:
    def __init__(self, total):
        self.total, self.completed = total, 0
    def submit(self, fn, *args, **kwargs):
        owner = self
        class Deferred:
            def result(self):
                result = fn(*args, **kwargs)
                owner.completed += 1
                emit('progress', stage='separating', completedUnits=owner.completed, totalUnits=owner.total)
                return result
        return Deferred()

def main():
    global job_id
    emit('ready', workerVersion='0.1.0', supportedCommands=['separate'])
    line = sys.stdin.buffer.readline(65537)
    if not line or len(line) > 65536:
        return 10
    request = json.loads(line)
    job_id = str(uuid.UUID(request['jobID']))
    if request.get('protocolVersion') != VERSION or request.get('type') != 'separate':
        return 10
    inp = request['input']
    frames = inp['frames']
    if (type(frames) is not int or not 0 < frames <= MAX_FRAMES or inp['channels'] != 2
        or inp['sampleRate'] != 44100 or inp['sampleType'] != 'float32-le'
        or inp['layout'] != 'interleaved' or inp['byteCount'] != frames * 8
        or request.get('modelID') != 'htdemucs' or request.get('device') != 'cpu'):
        return 10
    src = Path(inp['path'])
    dest = Path(request['outputDirectory'])
    if not src.is_file() or src.is_symlink() or src.stat().st_size != frames * 8 or dest.exists():
        return 10
    threading.Thread(target=control, daemon=True).start()
    emit('stage', stage='loadingModel')
    root = Path(getattr(sys, '_MEIPASS', Path(__file__).resolve().parents[1]))
    model_path = root / 'models' / MODEL_FILE
    if not model_path.is_file() or hashlib.file_digest(model_path.open('rb'), 'sha256').hexdigest() != MODEL_HASH:
        emit('error', code='modelIntegrity')
        return 20
    # Imports happen after the ready handshake and under the parent-death watcher.
    import numpy as np
    import torch
    from demucs.states import load_model
    from demucs.apply import apply_model
    torch.set_num_threads(min(4, os.cpu_count() or 1))
    torch.set_num_interop_threads(1)
    torch.manual_seed(0)
    # Only this hash-verified bundled checkpoint is ever unpickled.
    model = load_model(torch.load(model_path, map_location='cpu', weights_only=False))
    model.eval()
    if set(model.sources) != {'vocals', 'drums', 'bass', 'other'}:
        return 20
    mix = torch.from_numpy(np.fromfile(src, dtype='<f4').reshape(frames, 2).T.copy())
    if not torch.isfinite(mix).all():
        return 10
    ref = mix.mean(0)
    mean, std = ref.mean(), ref.std(unbiased=False)
    mix = (mix - mean) / (std + 1e-8)
    segment = 7.8
    total = math.ceil(frames / int(0.75 * int(44100 * segment)))
    emit('progress', stage='separating', completedUnits=0, totalUnits=total)
    with torch.inference_mode():
        result = apply_model(model, mix[None], shifts=0, split=True, overlap=0.25,
                             segment=segment, device='cpu', num_workers=0,
                             pool=ProgressPool(total))[0]
        result = result * (std + 1e-8) + mean
    if not torch.isfinite(result).all() or result.shape != (4, 2, frames):
        return 30
    emit('stage', stage='writing')
    dest.mkdir(mode=0o700)
    stems = []
    for name, stem in zip(model.sources, result):
        filename = name + '.f32le'
        stem.T.contiguous().numpy().astype('<f4', copy=False).tofile(dest / filename)
        stems.append(dict(name=name, file=filename, byteCount=frames * 8))
    emit('result', frames=frames, channels=2, sampleRate=44100,
         sampleType='float32-le', layout='interleaved', stems=stems)
    return 0

if __name__ == '__main__':
    try:
        code = main()
    except Exception as error:
        # Never expose filenames, user data, or traceback in normal production output.
        emit('error', code='workerFailure')
        print(type(error).__name__, file=sys.stderr, flush=True)
        code = 30
    sys.stdout.flush()
    os._exit(code)
