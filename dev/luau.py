"""A small Luau checker for this project (standard library only).

Roblox's own tools (luau-lsp, selene) can't be downloaded in the build sandbox, so this
catches the mistakes that most often break a Roblox game before anyone presses Play:
unbalanced blocks (a missing `end`), names that are used but never declared (typos),
global assignments, and requires or remotes that point at something that doesn't exist.
It does not type-check Roblox APIs: test in Roblox Studio for that.
"""
from __future__ import annotations

import re

KEYWORDS = {
    "and", "break", "continue", "do", "else", "elseif", "end", "false", "for", "function", "if",
    "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while",
}
GLOBALS = {
    # Luau
    "assert", "error", "getmetatable", "ipairs", "next", "pairs", "pcall", "print", "rawequal",
    "rawget", "rawlen", "rawset", "require", "select", "setmetatable", "tonumber", "tostring",
    "type", "typeof", "unpack", "xpcall", "warn", "bit32", "buffer", "coroutine", "debug", "math",
    "os", "string", "table", "task", "utf8", "tick", "time", "elapsedTime", "gcinfo", "_G",
    # Roblox
    "game", "workspace", "script", "plugin", "shared", "Enum", "Instance", "Vector2", "Vector3",
    "CFrame", "Color3", "BrickColor", "UDim", "UDim2", "Rect", "Ray", "Region3", "TweenInfo",
    "NumberRange", "NumberSequence", "NumberSequenceKeypoint", "ColorSequence",
    "ColorSequenceKeypoint", "PhysicalProperties", "Random", "RaycastParams", "OverlapParams",
    "Font", "DateTime", "PathWaypoint", "Axes", "Faces", "SharedTable",
}
SYMBOLS = ["...", "..=", "//=", "..", "==", "~=", "<=", ">=", "//", "+=", "-=", "*=", "/=", "%=",
           "^=", "->", "::"]
EXPR_BEFORE = {"=", "(", ",", "return", "{", "[", "..", "+", "-", "*", "/", "//", "%", "^", "==",
               "~=", "<", ">", "<=", ">=", "and", "or", "not", "#", "+=", "-=", "*=", "/=", "..=",
               "in"}


class Token:
    __slots__ = ("kind", "text", "line")

    def __init__(self, kind: str, text: str, line: int):
        self.kind, self.text, self.line = kind, text, line

    def __repr__(self) -> str:
        return f"{self.kind}:{self.text}@{self.line}"


def _long_bracket(src: str, i: int) -> int | None:
    """At '[' starting a long bracket ([[ or [==[), return the index after its close."""
    m = re.match(r"\[(=*)\[", src[i:])
    if not m:
        return None
    close = "]" + m.group(1) + "]"
    end = src.find(close, i + len(m.group(0)))
    if end < 0:
        raise SyntaxError("unclosed long string or comment")
    return end + len(close)


def tokenize(src: str) -> list[Token]:
    tokens, i, line, n = [], 0, 1, len(src)
    while i < n:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
        elif c in " \t\r":
            i += 1
        elif src.startswith("--", i):
            j = _long_bracket(src, i + 2) if src.startswith("[", i + 2) else None
            j = j if j is not None else (src.find("\n", i) if "\n" in src[i:] else n)
            line += src.count("\n", i, j)
            i = j
        elif c in "\"'":
            j = i + 1
            while j < n and src[j] != c:
                if src[j] == "\\":
                    j += 1
                elif src[j] == "\n":
                    raise SyntaxError(f"line {line}: unfinished string")
                j += 1
            tokens.append(Token("string", src[i:j + 1], line))
            i = j + 1
        elif c == "`":
            j = src.find("`", i + 1)
            if j < 0:
                raise SyntaxError(f"line {line}: unfinished interpolated string")
            tokens.append(Token("string", src[i:j + 1], line))
            line += src.count("\n", i, j)
            i = j + 1
        elif c == "[" and _long_bracket(src, i) is not None:
            j = _long_bracket(src, i)
            tokens.append(Token("string", src[i:j], line))
            line += src.count("\n", i, j)
            i = j
        elif c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit()):
            m = re.match(r"0[xX][0-9a-fA-F_]+|0[bB][01_]+|(\d[\d_]*)?(\.[\d_]*)?([eE][+-]?\d+)?", src[i:])
            tokens.append(Token("number", m.group(0), line))
            i += max(1, len(m.group(0)))
        elif c.isalpha() or c == "_":
            m = re.match(r"[A-Za-z_][A-Za-z0-9_]*", src[i:])
            word = m.group(0)
            tokens.append(Token("keyword" if word in KEYWORDS else "name", word, line))
            i += len(word)
        else:
            sym = next((s for s in SYMBOLS if src.startswith(s, i)), c)
            if sym not in SYMBOLS and sym not in "+-*/%^#&~|<>=(){}[];:,.":
                raise SyntaxError(f"line {line}: unexpected character {sym!r}")
            tokens.append(Token("symbol", sym, line))
            i += len(sym)
    return tokens


def check_blocks(tokens: list[Token]) -> list[str]:
    """Every function/if/while/for/do needs an `end`, every repeat an `until`."""
    errors, stack, pending_do, prev = [], [], 0, None
    for t in tokens:
        w = t.text if t.kind == "keyword" else None
        if w == "if":
            if prev is None or prev.text not in EXPR_BEFORE:
                stack.append(("if", t.line))  # an if-expression (x = if a then b else c) has no end
        elif w in ("function", "repeat"):
            stack.append((w, t.line))
        elif w in ("while", "for"):
            stack.append((w, t.line))
            pending_do += 1
        elif w == "do":
            if pending_do:
                pending_do -= 1
            else:
                stack.append(("do", t.line))
        elif w == "end":
            if not stack or stack[-1][0] == "repeat":
                errors.append(f"line {t.line}: 'end' without an open block")
            else:
                stack.pop()
        elif w == "until":
            if not stack or stack[-1][0] != "repeat":
                errors.append(f"line {t.line}: 'until' without 'repeat'")
            else:
                stack.pop()
        prev = t
    errors += [f"line {line}: '{kind}' is never closed" for kind, line in stack]
    return errors


def check_names(tokens: list[Token]) -> list[str]:
    """Flag names that are used but never declared anywhere in the file (typos, globals)."""
    declared, errors = set(), []
    for i, t in enumerate(tokens):
        prev = tokens[i - 1] if i else None
        if t.kind == "keyword" and t.text in ("local", "for"):
            j = i + 1
            if j < len(tokens) and tokens[j].text == "function":
                j += 1
            while j < len(tokens) and tokens[j].kind == "name":
                declared.add(tokens[j].text)
                if j + 1 < len(tokens) and tokens[j + 1].text == ",":
                    j += 2
                else:
                    break
        elif t.text == "function" and t.kind == "keyword":
            j = i + 1
            if j < len(tokens) and tokens[j].kind == "name" and (prev is None or prev.text != "local"):
                if j + 1 < len(tokens) and tokens[j + 1].text == "(":
                    errors.append(f"line {t.line}: global function {tokens[j].text}; use 'local function'")
                    declared.add(tokens[j].text)
            while j < len(tokens) and tokens[j].text != "(":
                j += 1
            j += 1
            while j < len(tokens) and tokens[j].text != ")":
                if tokens[j].kind == "name" and tokens[j - 1].text != ":":
                    declared.add(tokens[j].text)
                j += 1
    brackets = []
    for i, t in enumerate(tokens):
        if t.text in "({[" and t.kind == "symbol":
            brackets.append(t.text)
        elif t.text in ")}]" and t.kind == "symbol" and brackets:
            brackets.pop()
        if t.kind != "name" or t.text in declared or t.text in GLOBALS:
            continue
        prev = tokens[i - 1] if i else None
        nxt = tokens[i + 1] if i + 1 < len(tokens) else None
        if prev is not None and prev.text in (".", ":"):
            continue  # a field or method
        if nxt is not None and nxt.text == "=" and brackets and brackets[-1] == "{":
            continue  # a key in a table constructor
        errors.append(f"line {t.line}: unknown name '{t.text}'")
    return errors


def check(src: str) -> list[str]:
    try:
        tokens = tokenize(src)
    except SyntaxError as e:
        return [str(e)]
    return check_blocks(tokens) + check_names(tokens)


REF = r"(?::WaitForChild\(\"(\w+)\"\)|\.(\w+))"


def references(src: str, root: str) -> set[str]:
    """Children named after `root` (script.Parent, Shared, Remotes, ...) in this source."""
    return {a or b for a, b in re.findall(re.escape(root) + REF, src)}
