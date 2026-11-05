"""Build the Roblox place file from default.project.json (Rojo's format), after checking the code.

    python3 dev/build.py            # check, then write NeedleInTheHaystack.rbxlx
    python3 dev/build.py --check    # check only

Follows Rojo's conventions for the parts this project uses: a folder becomes a Folder,
X.server.luau a Script, X.client.luau a LocalScript, X.luau a ModuleScript and X.json a
ModuleScript returning the data. With Rojo installed, `rojo build` gives the same tree.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from xml.sax.saxutils import escape

sys.path.insert(0, str(Path(__file__).parent))
import luau  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "default.project.json"
OUT = ROOT / "NeedleInTheHaystack.rbxlx"
SCRIPT_KINDS = {".server.luau": "Script", ".client.luau": "LocalScript", ".luau": "ModuleScript"}
# Names Rojo turns into their own class rather than a Folder when no $className is given
SPECIAL = {"StarterPlayerScripts", "StarterCharacterScripts"}


class Node:
    def __init__(self, name: str, cls: str, source: str | None = None, path: Path | None = None):
        self.name, self.cls, self.source, self.path = name, cls, source, path
        self.props: dict = {}
        self.children: list[Node] = []

    def walk(self):
        yield self
        for c in self.children:
            yield from c.walk()

    def child(self, name: str) -> "Node | None":
        return next((c for c in self.children if c.name == name), None)


def luau_literal(value, indent: str = "") -> str:
    """JSON data as a Luau table literal (what Rojo does for .json modules)."""
    inner = indent + "\t"
    if isinstance(value, dict):
        items = []
        for k, v in value.items():
            key = k if k.isidentifier() and k not in luau.KEYWORDS else "[" + json.dumps(k) + "]"
            items.append(f"{inner}{key} = {luau_literal(v, inner)},")
        return "{\n" + "\n".join(items) + "\n" + indent + "}"
    if isinstance(value, list):
        return "{\n" + "\n".join(f"{inner}{luau_literal(v, inner)}," for v in value) + "\n" + indent + "}"
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "nil"
    if isinstance(value, (int, float)):
        return repr(value)
    return json.dumps(value, ensure_ascii=False)


def from_path(name: str, path: Path) -> Node:
    if path.is_dir():
        node = Node(name, "Folder", path=path)
        for p in sorted(path.iterdir()):
            if p.name.startswith("."):
                continue
            child = file_node(p)
            if child:
                node.children.append(child)
        return node
    node = file_node(path)
    if node is None:
        raise SystemExit(f"{path}: not a script, module or folder")
    node.name = name
    return node


def file_node(p: Path) -> Node | None:
    if p.is_dir():
        return from_path(p.name, p)
    for suffix, cls in SCRIPT_KINDS.items():
        if p.name.endswith(suffix):
            return Node(p.name[: -len(suffix)], cls, p.read_text(), p)
    if p.suffix == ".json":
        data = json.loads(p.read_text())
        return Node(p.stem, "ModuleScript", "-- Generated from " + p.name + "\nreturn " + luau_literal(data) + "\n", p)
    return None


def from_project(name: str, spec: dict, parent_is_root: bool) -> Node:
    if "$path" in spec:
        node = from_path(name, ROOT / spec["$path"])
    else:
        node = Node(name, spec.get("$className", name if parent_is_root or name in SPECIAL else "Folder"))
    node.props.update(spec.get("$properties", {}))
    for key, child in spec.items():
        if not key.startswith("$"):
            node.children.append(from_project(key, child, False))
    return node


EXPECTED = {  # where Roblox runs things: these must be real containers, not Folders
    ("StarterPlayer", "StarterPlayerScripts"): "StarterPlayerScripts",
}


def check(tree: Node) -> list[str]:
    errors = []
    for (parent, child), cls in EXPECTED.items():
        node = tree.child(parent) and tree.child(parent).child(child)
        if node is None or node.cls != cls:
            errors.append(f"{parent}.{child} must be a {cls}, not {node.cls if node else 'missing'}")
    for node in tree.walk():
        if node.cls == "LocalScript" and not any(p.cls in ("StarterPlayerScripts", "StarterCharacterScripts", "StarterGui", "ReplicatedFirst") for p in ancestors(tree, node)):
            errors.append(f"LocalScript {node.name} is somewhere it will never run")
        if node.cls == "Script" and not any(p.cls in ("ServerScriptService", "Workspace") for p in ancestors(tree, node)):
            errors.append(f"Script {node.name} is somewhere it will never run")
    shared = tree.child("ReplicatedStorage").child("Shared")
    remotes = tree.child("ReplicatedStorage").child("Remotes")
    for node in tree.walk():
        if node.source is None or node.path is None or node.path.suffix == ".json":
            continue
        rel = node.path.relative_to(ROOT)
        lines = node.source.count("\n") + 1
        if lines >= 300:
            errors.append(f"{rel}: {lines} lines (keep files under 300)")
        errors += [f"{rel}: {e}" for e in luau.check(node.source)]
        parent = next(p for p in tree.walk() if node in p.children)
        for ref in luau.references(node.source, "script.Parent"):
            if parent.child(ref) is None:
                errors.append(f"{rel}: script.Parent has no '{ref}'")
        for ref in luau.references(node.source, "Shared"):
            if ref != "Parent" and shared.child(ref) is None:
                errors.append(f"{rel}: Shared has no '{ref}'")
        for ref in luau.references(node.source, "Remotes"):
            if ref != "Parent" and remotes.child(ref) is None:
                errors.append(f"{rel}: Remotes has no '{ref}'")
    return errors


def ancestors(tree: Node, node: Node) -> list[Node]:
    chain, current = [], node
    while current is not tree:
        current = next(p for p in tree.walk() if current in p.children)
        chain.append(current)
    return chain


def xml(node: Node, ids: dict, depth: int = 1) -> str:
    pad = "\t" * depth
    ids[node] = f"RBX{len(ids):05X}"
    props = [f'{pad}\t\t<string name="Name">{escape(node.name)}</string>']
    for key, value in node.props.items():
        if isinstance(value, bool):
            props.append(f'{pad}\t\t<bool name="{key}">{"true" if value else "false"}</bool>')
        elif isinstance(value, str):
            props.append(f'{pad}\t\t<string name="{key}">{escape(value)}</string>')
        else:
            raise SystemExit(f"{node.name}.{key}: only true/false and text properties are supported")
    if node.source is not None:
        source = node.source.replace("]]>", "]]]]><![CDATA[>")
        props.append(f'{pad}\t\t<ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>')
    body = "\n".join(xml(c, ids, depth + 1) for c in node.children)
    return (f'{pad}<Item class="{node.cls}" referent="{ids[node]}">\n{pad}\t<Properties>\n'
            + "\n".join(props) + f"\n{pad}\t</Properties>\n" + (body + "\n" if body else "") + f"{pad}</Item>")


def main() -> int:
    spec = json.loads(PROJECT.read_text())
    tree = Node("game", "DataModel")
    for key, child in spec["tree"].items():
        if not key.startswith("$"):
            tree.children.append(from_project(key, child, True))
    errors = check(tree)
    for e in errors:
        print("x", e)
    scripts = [n for n in tree.walk() if n.source is not None]
    print(f"checked {len(scripts)} scripts and modules: {len(errors)} problem(s)")
    if errors:
        return 1
    if "--check" in sys.argv:
        return 0
    ids: dict = {}
    body = "\n".join(xml(c, ids) for c in tree.children)
    OUT.write_text('<roblox version="4">\n' + body + "\n</roblox>\n", encoding="utf-8")
    print(f"wrote {OUT.name}: {len(ids)} instances, {OUT.stat().st_size // 1024} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
