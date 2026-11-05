"""Minimal binary FBX reader: nodes, properties, arrays (zlib)."""
import struct, zlib, sys

def read(path):
    data = open(path, 'rb').read()
    version = struct.unpack('<I', data[23:27])[0]
    wide = version >= 7500
    pos = 27
    nodes = []
    while True:
        node, pos = _node(data, pos, wide)
        if node is None:
            break
        nodes.append(node)
    return version, nodes

def _prop(data, pos):
    t = chr(data[pos]); pos += 1
    simple = {'Y': ('<h', 2), 'C': ('<?', 1), 'I': ('<i', 4), 'F': ('<f', 4), 'D': ('<d', 8), 'L': ('<q', 8)}
    if t in simple:
        fmt, n = simple[t]
        return struct.unpack(fmt, data[pos:pos + n])[0], pos + n
    if t in 'fdlib':
        n, enc, clen = struct.unpack('<III', data[pos:pos + 12]); pos += 12
        raw = data[pos:pos + clen]; pos += clen
        if enc == 1:
            raw = zlib.decompress(raw)
        code = {'f': 'f', 'd': 'd', 'l': 'q', 'i': 'i', 'b': '?'}[t]
        return ('array', code, raw, n), pos
    if t in 'SR':
        n = struct.unpack('<I', data[pos:pos + 4])[0]; pos += 4
        return data[pos:pos + n], pos + n
    raise ValueError(t)

def _node(data, pos, wide):
    if wide:
        end, nprops, plen = struct.unpack('<QQQ', data[pos:pos + 24]); pos += 24
    else:
        end, nprops, plen = struct.unpack('<III', data[pos:pos + 12]); pos += 12
    nlen = data[pos]; pos += 1
    if end == 0:
        return None, pos
    name = data[pos:pos + nlen].decode('latin1'); pos += nlen
    props = []
    for _ in range(nprops):
        v, pos = _prop(data, pos)
        props.append(v)
    children = []
    sentinel = 25 if wide else 13
    while pos < end - sentinel or (pos < end and end - pos > sentinel):
        child, pos = _node(data, pos, wide)
        if child is None:
            break
        children.append(child)
    return {'name': name, 'props': props, 'children': children}, end

def find(nodes, name):
    for n in nodes:
        if n['name'] == name:
            yield n
        yield from find(n['children'], name)

def child(n, name):
    for c in n['children']:
        if c['name'] == name:
            return c
    return None
