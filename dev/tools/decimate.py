"""Reads the hay FBX, triangulates, clusters vertices on a grid until the mesh is under the
target triangle count, and writes an OBJ with UVs (Roblox imports OBJ and FBX)."""
import sys, struct
import numpy as np

import fbx

def arr(p):
    _, code, raw, n = p
    return np.frombuffer(raw, dtype={'d': '<f8', 'i': '<i4', 'f': '<f4', 'q': '<i8'}[code])

path, out, target = sys.argv[1], sys.argv[2], int(sys.argv[3])
_, nodes = fbx.read(path)
g = next(fbx.find(nodes, 'Geometry'))
verts = arr(fbx.child(g, 'Vertices')['props'][0]).reshape(-1, 3)
pvi = arr(fbx.child(g, 'PolygonVertexIndex')['props'][0])
uvl = fbx.child(g, 'LayerElementUV')
mapping = fbx.child(uvl, 'MappingInformationType')['props'][0]
ref = fbx.child(uvl, 'ReferenceInformationType')['props'][0]
uv = arr(fbx.child(uvl, 'UV')['props'][0]).reshape(-1, 2)
uvi = arr(fbx.child(uvl, 'UVIndex')['props'][0]) if fbx.child(uvl, 'UVIndex') else None
print('verts', len(verts), 'corners', len(pvi), mapping, ref, 'uv', len(uv))
# polygons -> triangles (fan), keeping the corner index for UVs
tris, corners = [], []
start = 0
for i, v in enumerate(pvi):
    if v < 0:
        poly = list(range(start, i + 1))
        for k in range(1, len(poly) - 1):
            corners.append((poly[0], poly[k], poly[k + 1]))
        start = i + 1
corners = np.array(corners)
vidx = pvi.copy(); vidx[vidx < 0] = ~vidx[vidx < 0]
tri_v = vidx[corners]
if mapping == b'ByPolygonVertex':
    tri_uv = uv[uvi[corners]] if ref == b'IndexToDirect' else uv[corners]
else:
    tri_uv = uv[uvi[tri_v]] if ref == b'IndexToDirect' else uv[tri_v]
print('triangles', len(tri_v))
lo, hi = verts.min(0), verts.max(0)
size = (hi - lo).max()
cells = 200
while True:
    cell = size / cells
    key = np.floor((verts - lo) / cell).astype(np.int64)
    k = key[:, 0] * 1_000_003 ** 2 + key[:, 1] * 1_000_003 + key[:, 2]
    uniq, cluster = np.unique(k, return_inverse=True)
    t = cluster[tri_v]
    keep = (t[:, 0] != t[:, 1]) & (t[:, 1] != t[:, 2]) & (t[:, 0] != t[:, 2])
    tt = t[keep]
    srt = np.sort(tt, axis=1)
    _, first = np.unique(srt, axis=0, return_index=True)
    n = len(first)
    print('cells', cells, 'tris', n)
    if n <= target or cells < 10:
        break
    cells = int(cells * 0.85)
pos = np.zeros((len(uniq), 3)); cnt = np.zeros(len(uniq))
np.add.at(pos, cluster, verts); np.add.at(cnt, cluster, 1)
pos /= cnt[:, None]
pos -= (pos.min(0) + pos.max(0)) / 2
pos /= (pos.max(0) - pos.min(0)).max()  # fits a 1x1x1 box
tt = tt[np.sort(first)]
tuv = tri_uv[keep][np.sort(first)]
with open(out, 'w') as f:
    f.write('# garden hay, simplified for Roblox (%d triangles)\nmtllib garden-hay.mtl\nusemtl hay\n' % len(tt))
    for p in pos:
        f.write('v %.5f %.5f %.5f\n' % tuple(p))
    for u in tuv.reshape(-1, 2):
        f.write('vt %.5f %.5f\n' % tuple(u))
    for i, tri in enumerate(tt):
        a, b, c = tri + 1
        f.write('f %d/%d %d/%d %d/%d\n' % (a, 3 * i + 1, b, 3 * i + 2, c, 3 * i + 3))
print('wrote', out, len(tt), 'triangles', 'size', (hi - lo))
