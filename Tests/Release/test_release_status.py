import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'scripts'))
from release_record import write_record
from release_status import inspect, RECORDS

class ReleaseStatus(unittest.TestCase):
    def test_absent_evidence_is_incomplete(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertIn('Missing two-version-update',inspect(Path(d),complete=True))
    def test_modified_public_artifact_is_incomplete(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);asset=root/'payload';asset.write_bytes(b'original')
            write_record(root/'published.json',asset)
            asset.write_bytes(b'changed')
            self.assertIn('Changed artifact published',inspect(root))
    def test_ci_source_mismatch_is_incomplete(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            (root/'ci-proof.json').write_text(json.dumps({'conclusion':'success','sourceSHA':'wrong'}))
            (root/'archived.json').write_text(json.dumps({'evidence':{'sourceSHA':'expected'}}))
            self.assertIn('CI source mismatch',inspect(root))
