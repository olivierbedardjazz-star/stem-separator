import importlib.util
from pathlib import Path
import tempfile
import unittest
spec=importlib.util.spec_from_file_location('audit',Path(__file__).resolve().parents[2]/'scripts/audit_stem_runtime.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class RuntimeAudit(unittest.TestCase):
    def test_normalized_os_floor(self):
        self.assertEqual(m.version('14'),m.version('14.0.0'))
        self.assertGreater(m.version('14.1'),m.version('14.0'))
    def test_empty_and_escaping_payload_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            (Path(root)/'outside').symlink_to('/etc/hosts')
            report=m.audit(root)
            self.assertTrue(any('symlink' in x for x in report['failures']))
            self.assertTrue(any('Missing native' in x for x in report['failures']))
