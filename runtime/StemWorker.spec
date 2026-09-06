from PyInstaller.utils.hooks import collect_data_files
from pathlib import Path
root = Path(SPECPATH).parent
analysis = Analysis([str(root/'runtime/worker/stem_worker.py')],
    pathex=[], binaries=[], datas=[(str(root/'runtime/models'), 'models')] + collect_data_files('demucs'),
    hiddenimports=['demucs.htdemucs', 'demucs.hdemucs', 'demucs.transformer', 'demucs.demucs'],
    excludes=['matplotlib','scipy','pandas','IPython','pytest','tensorboard','tkinter','torchaudio.lib._torchaudio_sox'],
    noarchive=False)
# Audio decoding/encoding is native Swift. Optional torchaudio SoX extensions
# are unused and reference an unbundled libsox; exclude that optional backend.
analysis.binaries = [entry for entry in analysis.binaries
                     if Path(entry[0]).name not in ('libtorchaudio_sox.so', '_torchaudio_sox.so')]
pyz = PYZ(analysis.pure)
exe = EXE(pyz, analysis.scripts, [], exclude_binaries=True, name='StemWorker',
    debug=False, strip=False, upx=False, console=True, target_arch='arm64')
collection = COLLECT(exe, analysis.binaries, analysis.datas, strip=False, upx=False, name='StemWorker')
app = BUNDLE(collection, name='StemWorker.app', bundle_identifier='com.oliviergrenierbedard.stemseparator.worker',
    info_plist={'LSBackgroundOnly':True, 'LSMinimumSystemVersion':'14.0'})
