import importlib.util
from pathlib import Path
import tempfile
import unittest
spec=importlib.util.spec_from_file_location('record',Path(__file__).resolve().parents[2]/'scripts/release_record.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class ArtifactRecords(unittest.TestCase):
    def test_modified_artifact_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            root=Path(root);app=root/'App';app.mkdir();data=app/'payload';data.write_bytes(b'original')
            record=root/'record.json';m.write_record(record,app);m.verify_record(record,app)
            data.write_bytes(b'modified')
            with self.assertRaises(ValueError):m.verify_record(record,app)
    def test_symlink_escape_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            root=Path(root);app=root/'App';app.mkdir();(app/'escape').symlink_to('/etc/hosts')
            with self.assertRaises(ValueError):m.fingerprint(app)
    def test_modes_and_link_targets_bound(self):
        with tempfile.TemporaryDirectory() as root:
            root=Path(root);(root/'a').write_bytes(b'a');(root/'b').symlink_to('a')
            first=m.fingerprint(root);(root/'a').chmod(0o700)
            self.assertNotEqual(first,m.fingerprint(root))
