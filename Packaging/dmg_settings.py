"""Brand-identical Finder layout. Paths arrive as environment data, not generated code."""
import os
from pathlib import Path
app = Path(os.environ['STEM_DMG_APP_PATH'])
background = os.environ['STEM_DMG_BACKGROUND']
format = 'UDZO'
files = [str(app)]
symlinks = {'Applications': '/Applications'}
show_toolbar = False
show_status_bar = False
show_sidebar = False
show_pathbar = False
show_tab_view = False
show_icon_preview = False
window_rect = ((400, 530), (540, 380))
default_view = 'icon-view'
arrange_by = None
grid_offset = (0, 0)
grid_spacing = 100
scroll_position = (0, 0)
label_pos = 'bottom'
text_size = 12
icon_size = 80
include_icon_view_settings = True
include_list_view_settings = False
icon_locations = {app.name: (130, 220), 'Applications': (410, 220)}
