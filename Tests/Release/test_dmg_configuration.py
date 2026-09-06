import os
from pathlib import Path
import runpy
import unittest
from unittest.mock import patch

class DmgConfigurationTests(unittest.TestCase):
    def test_unicode_and_quoted_path_preserves_layout(self):
        app = "/workspace/Olivier's café/Stem Separator.app"
        settings = Path(__file__).resolve().parents[2] / 'Packaging/dmg_settings.py'
        with patch.dict(os.environ, {'STEM_DMG_APP_PATH': app, 'STEM_DMG_BACKGROUND': '/background.tiff'}):
            values = runpy.run_path(str(settings))
        self.assertEqual(values['files'], [app])
        self.assertEqual(values['window_rect'], ((400, 530), (540, 380)))
        self.assertEqual(values['icon_locations']['Stem Separator.app'], (130, 220))
        self.assertEqual(values['icon_locations']['Applications'], (410, 220))
        self.assertEqual(values['icon_size'], 80)

if __name__ == '__main__': unittest.main()
