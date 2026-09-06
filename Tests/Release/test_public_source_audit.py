import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('audit', Path(__file__).resolve().parents[2] / 'scripts/audit_public_source.py')
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)

class PublicSourceAuditTests(unittest.TestCase):
    def test_reports_category_without_credential_contents(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            dummy = 'ghp_' + 'x' * 32
            (root / 'config.txt').write_text(dummy)
            result = audit.audit(root, ['config.txt'])
            self.assertEqual(result[0]['category'], 'possible credential')
            self.assertNotIn(dummy, json.dumps(result))

    def test_public_key_is_not_a_private_credential(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'project.yml').write_text('TEMPLATE_APP_SPARKLE_PUBLIC_ED_KEY: ' + 'A' * 43 + '=')
            self.assertEqual(audit.audit(root, ['project.yml']), [])

    def test_blocks_artifacts_traversal_and_symlinks(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'source.swift').write_text('import Foundation')
            (root / 'linked.swift').symlink_to(root / 'source.swift')
            result = audit.audit(root, ['../other', '/etc/passwd', 'linked.swift', 'build/app', 'archive/old.swift', 'runtime/models/model.th'])
            self.assertEqual(len(result), 6)
            self.assertEqual(audit.audit(root, ['source.swift']), [])

if __name__ == '__main__': unittest.main()
