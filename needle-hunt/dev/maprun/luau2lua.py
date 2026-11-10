"""Turns the Luau the map code uses into plain Lua 5.4, so dev/maprun can run the real map builders
outside Roblox: `x += y` and friends, inline `if a then b else c` expressions (made lazy, so random
numbers are drawn in the same order), and `continue` is not used. Everything else is already Lua."""
import re

TOKEN = re.compile(r"""--\[\[.*?\]\]|--[^\n]*|\[\[.*?\]\]|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\d+\.?\d*(?:[eE][+-]?\d+)?|0x[0-9a-fA-F]+|[A-Za-z_]\w*|\.\.\.|\.\.=?|[=~<>]=|//|[+\-*/%^#]=?|\n|[ \t\r]+|.""", re.S)
EXPR_BEFORE = {"=", "(", ",", "{", "[", "return", "..", "and", "or", "not", "+", "-", "*", "/", "%", "^", "==", "~=", "<", ">", "<=", ">=", "//", "#"}
OPEN, CLOSE = {"(", "{", "["}, {")", "}", "]"}


def tokens(src):
    return TOKEN.findall(src)


def significant(t):
    return not (t.isspace() or t.startswith("--"))


def prev_sig(toks, i):
    j = i - 1
    while j >= 0 and not significant(toks[j]):
        j -= 1
    return toks[j] if j >= 0 else None


def span(toks, i, stops):
    """From i, the index of the first depth-0 token in stops (or a depth-0 newline if '\\n' in stops)."""
    depth = 0
    while i < len(toks):
        t = toks[i]
        if depth == 0 and (t in stops or ((t == "\n" or t.startswith("--")) and "\n" in stops)):
            return i
        if t in OPEN or t in ("function", "if") and False:
            depth += 1
        elif t in CLOSE:
            if depth == 0:
                return i
            depth -= 1
        elif t == "function":
            depth += 1
        elif t == "end" and depth > 0:
            depth -= 1
        i += 1
    return i


def conv(toks):
    out, i = [], 0
    while i < len(toks):
        t = toks[i]
        if t == "if" and prev_sig(toks, i) in EXPR_BEFORE:
            c_end = span(toks, i + 1, {"then"})
            a_end = span(toks, c_end + 1, {"else", "elseif"})
            if toks[a_end] == "elseif":  # elseif = else if ..., ending where the whole expression ends
                b_end = span(toks, a_end + 1, {",", "\n", "do", "end"} | CLOSE)
                b = conv(["(", "if"] + toks[a_end + 1:b_end] + [")"])
                tail = b_end
            else:
                b_end = span(toks, a_end + 1, {",", "\n", "then", "do", "end", "else", "elseif"} | CLOSE)
                b = conv(toks[a_end + 1:b_end])
                tail = b_end
            out.append("__if((" + conv(toks[i + 1:c_end]) + "),function() return " + conv(toks[c_end + 1:a_end]) + " end,function() return " + b + " end)")
            i = tail
            continue
        if t in ("+=", "-=", "*=", "/=", "..=", "//=", "%=", "^="):  # a compound assignment: x op= e
            j = len(out) - 1
            while j >= 0 and out[j].isspace():
                j -= 1
            k = j  # walk back over the target (names, dots, [index])
            depth = 0
            while k >= 0:
                o = out[k]
                if o in ("]", ")"):
                    depth += 1
                elif o in ("[", "("):
                    depth -= 1
                elif depth == 0 and not (re.match(r"[A-Za-z_]\w*$", o) or o in (".", ":")):
                    break
                k -= 1
            target = "".join(out[k + 1:j + 1])
            e_end = span(toks, i + 1, {"\n", ";"})
            out.append("= " + target + " " + t[:-1] + " (" + conv(toks[i + 1:e_end]) + ")")
            i = e_end
            continue
        out.append(t)
        i += 1
    return "".join(out)


def convert(src):
    src = re.sub(r"(?m)^(\s*)export type .*$", r"\1", src)
    return conv(tokens(src))
