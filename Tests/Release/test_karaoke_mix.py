import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('worker', Path(__file__).resolve().parents[2] / 'runtime/worker/stem_worker.py')
worker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worker)

class KaraokeMixTests(unittest.TestCase):
    def test_excludes_vocals_and_respects_source_order(self):
        self.assertEqual(worker.output_tracks(['vocals', 'other', 'bass', 'drums'], [999, 3, 2, 1], 'karaoke'), [('karaoke', 6)])
    def test_stems_remain_unchanged(self):
        self.assertEqual(list(worker.output_tracks(['vocals', 'other', 'bass', 'drums'], [999, 3, 2, 1], 'stems')), [('vocals', 999), ('other', 3), ('bass', 2), ('drums', 1)])

if __name__ == '__main__':
    unittest.main()
