"""Verify the tracked low-poly model really comes from valid compressed vertices.

No external dependencies; checks raw source-derived artwork without running LÖVE.
"""
from pathlib import Path
import base64
import math
import re
import struct
import zlib

root = Path(__file__).resolve().parents[2]
model = (root / "resources/models/wooden_table_mesh.lua").read_text()
credits = (root / "resources/models/WOODEN_TABLE_CREDITS.md").read_text()
match = re.search(r"local compressed=\[=\[([A-Za-z0-9+/=]+)\]=\]", model)
assert match, "embedded source-derived silhouette absent"
payload = zlib.decompress(base64.b64decode(match.group(1), validate=True))
vertices = 243
triangles = 497
assert len(payload) == 6 * (vertices + triangles)
positions = [tuple(struct.unpack_from("<HHH", payload, i * 6)) for i in range(vertices)]
indices = [
    struct.unpack_from("<HHH", payload, vertices * 6 + i * 6)
    for i in range(triangles)
]
assert all(0 <= index < vertices for face in indices for index in face)
assert all(len(set(face)) == 3 for face in indices), "no degenerate triangle indices"
bbox_min = (-123.8540895, 0.1132178, -63.0080835)
bbox_max = (123.8363987, 88.3412928, 63.0277228)
decoded = [
    tuple(bbox_min[j] + p[j] * (bbox_max[j] - bbox_min[j]) / 65535
          for j in range(3))
    for p in positions
]
assert all(all(math.isfinite(x) for x in v) for v in decoded)
width = max(v[0] for v in decoded) - min(v[0] for v in decoded)
depth = max(v[2] for v in decoded) - min(v[2] for v in decoded)
height = max(v[1] for v in decoded) - min(v[1] for v in decoded)
assert 240 < width < 250 and 120 < depth < 130 and 85 < height < 90
assert "Pixel Life" in credits and "CC BY 4.0" in credits
assert "wooden_table_game_ready_asset.glb" in credits
print(f"PASS wooden-table geometry: {vertices} vertices, {triangles} triangles; source credit")
